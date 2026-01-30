/*
	Copyright 2024 Take Control - Software & Infrastructure

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:sync_client/core/auth_storage.dart';
import 'package:sync_client/core/errors/custom_errors.dart';
import 'package:sync_client/core/impl/request_utils.dart';
import 'package:sync_client/storage/storage.dart';

import 'request_utils.dart';

/// Server expects forward slashes; on Windows paths may use backslash.
String _normalizePath(String path) => path.replaceAll(r'\', '/');

/// Returns headers for JSON API requests, including Authorization when a token exists.
Future<Map<String, String>> _authHeaders() async {
  final token = await getAuthToken();
  return <String, String>{
    'Content-Type': 'application/json; charset=UTF-8',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

/// POST /auth/login. Returns token and userId on success; throws InvalidCredentialError on 401.
Future<AuthResult> apiLogin(String email, String password) async {
  var request = Request('POST', getUrl('auth/login'));
  request.headers.addAll(await _authHeaders());
  request.body =
      jsonEncode(<String, String>{'User': email, 'Password': password});
  try {
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return AuthResult(
        token: data['Token'] as String? ?? '',
        userId: data['UserId'] as String? ?? '',
      );
    }
    if (response.statusCode == 401) throw InvalidCredentialError();
    throw GetFoldersError();
  } catch (e) {
    if (e is InvalidCredentialError) rethrow;
    throw GetFoldersError();
  }
}

/// POST /auth/register. Returns token and userId on success.
Future<AuthResult> apiRegister(String email, String password) async {
  var request = Request('POST', getUrl('auth/register'));
  request.headers.addAll(await _authHeaders());
  request.body =
      jsonEncode(<String, String>{'User': email, 'Password': password});
  try {
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return AuthResult(
        token: data['Token'] as String? ?? '',
        userId: data['UserId'] as String? ?? '',
      );
    }
    if (response.statusCode == 401) throw InvalidCredentialError();
    throw GetFoldersError();
  } catch (e) {
    if (e is InvalidCredentialError) rethrow;
    throw GetFoldersError();
  }
}

/// Result of successful login or register.
class AuthResult {
  AuthResult({required this.token, required this.userId});
  final String token;
  final String userId;
}

Future<List<NetFolder>?> apiGetFolders(String userName, String deviceId) async {
  var request = Request('POST', getUrl("folders"));
  request.headers.addAll(await _authHeaders());

  request.body = jsonEncode(<String, dynamic>{
    'User': userName,
    'DeviceId': deviceId,
  });
  try {
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final List<dynamic> result = json.decode(response.body);
      final List<NetFolder> folders = result.reversed
          .map((item) => NetFolder(item["Year"],
              subFolders: (List<String>.from(item["Months"])
                  .reversed
                  .map((m) => NetFolder(m))
                  .toList())))
          .toList();
      return folders;
    }
  } catch (err) {
    throw GetFoldersError();
  }
  return null;
}

Future<List<String>> apiGetFiles(
    String userName, String deviceId, String folder) async {
  var request = Request('POST', getUrl("files"));
  request.headers.addAll(await _authHeaders());

  request.body = jsonEncode(<String, dynamic>{
    'UserData': <String, dynamic>{
      'User': userName,
      'DeviceId': deviceId,
    },
    "Folder": _normalizePath(folder)
  });
  try {
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final List<dynamic> result = json.decode(response.body);
      final List<String> files =
          result.reversed.map((item) => item.toString()).toList();
      return files;
    }
  } catch (err) {
    throw GetFoldersError();
  }
  return [];
}

/// Returns all file paths currently on the server (Home + Trash). Used to prune orphan thumbnail cache.
Future<List<String>> apiGetAllFilePaths(
    String userName, String deviceId) async {
  final folders = await apiGetFolders(userName, deviceId);
  final paths = <String>[];

  Future<void> visit(NetFolder? f, String prefix) async {
    if (f == null) return;
    final folderPath = prefix.isEmpty ? f.name : '$prefix/${f.name}';
    final normalized = _normalizePath(folderPath);
    final files = await apiGetFiles(userName, deviceId, normalized);
    for (final name in files) {
      paths.add('$normalized/$name');
    }
    for (final sub in f.subFolders ?? []) {
      await visit(sub, normalized);
    }
  }

  for (final f in folders ?? []) {
    await visit(f, '');
  }
  return paths;
}

Future<bool> apiMoveToTrash(
  String userName,
  String deviceId,
  List<String> files,
) async {
  if (files.isEmpty) return true;
  var request = Request('POST', getUrl("move-to-trash"));
  request.headers.addAll(await _authHeaders());
  request.body = jsonEncode(<String, dynamic>{
    'UserData': <String, dynamic>{'User': userName, 'DeviceId': deviceId},
    'Files': files.map(_normalizePath).toList(),
  });
  try {
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);
    return response.statusCode == 200;
  } catch (err) {
    throw GetFoldersError();
  }
}

/// Restore files from Trash back to Home. [files] must be paths like "Trash/2024/01/photo.jpg".
Future<bool> apiRestoreFromTrash(
  String userName,
  String deviceId,
  List<String> files,
) async {
  if (files.isEmpty) return true;
  var request = Request('POST', getUrl("restore"));
  request.headers.addAll(await _authHeaders());
  request.body = jsonEncode(<String, dynamic>{
    'UserData': <String, dynamic>{'User': userName, 'DeviceId': deviceId},
    'Files': files.map(_normalizePath).toList(),
  });
  try {
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);
    return response.statusCode == 200;
  } catch (err) {
    throw GetFoldersError();
  }
}

/// Asks the server to regenerate thumbnails for all (or missing) media files. Server must implement POST "regenerate-thumbnails".
Future<bool> apiRegenerateThumbnails(String userName, String deviceId) async {
  var request = Request('POST', getUrl("regenerate-thumbnails"));
  request.headers.addAll(await _authHeaders());
  request.body = jsonEncode(<String, dynamic>{
    'UserData': <String, dynamic>{'User': userName, 'DeviceId': deviceId},
  });
  try {
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);
    return response.statusCode == 200;
  } catch (err) {
    throw GetFoldersError();
  }
}

/// Asks the server to delete thumbnail files that have no corresponding source file (orphans). Server must implement POST "clean-orphan-thumbnails".
Future<bool> apiCleanOrphanThumbnails(String userName, String deviceId) async {
  var request = Request('POST', getUrl("clean-orphan-thumbnails"));
  request.headers.addAll(await _authHeaders());
  request.body = jsonEncode(<String, dynamic>{
    'UserData': <String, dynamic>{'User': userName, 'DeviceId': deviceId},
  });
  try {
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);
    return response.statusCode == 200;
  } catch (err) {
    throw GetFoldersError();
  }
}

/// Asks the server to run document detection on existing files (server uses its own logic, e.g. Python function): find documents, clean their thumbnails and metadata, and move them to Trash. Server must implement POST "run-document-detection".
/// Returns the number of documents moved, or -1 on failure.
Future<int> apiRunDocumentDetection(String userName, String deviceId) async {
  var request = Request('POST', getUrl("run-document-detection"));
  request.headers.addAll(await _authHeaders());
  request.body = jsonEncode(<String, dynamic>{
    'UserData': <String, dynamic>{'User': userName, 'DeviceId': deviceId},
  });
  try {
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);
    if (response.statusCode != 200) return -1;
    final body = response.body.trim();
    if (body.isEmpty) return 0;
    try {
      final data = json.decode(body) as Map<String, dynamic>;
      final moved =
          data['Moved'] ?? data['Count'] ?? data['moved'] ?? data['count'];
      if (moved is int) return moved;
      if (moved is num) return moved.toInt();
    } catch (_) {}
    return 0;
  } catch (err) {
    throw GetFoldersError();
  }
}

/// Quality for image requests: "" or "thumb" = thumbnail, "high" = compressed preview (max 1920px, JPEG 85%), "full" = full res (JPEG 92%).
Future<Uint8List?> apiGetImageBytes(
  String userName,
  String deviceId,
  String file, {
  bool fullQuality = false,
  String? quality,
}) async {
  var request = Request('POST', getUrl("img"));
  request.headers.addAll(await _authHeaders());

  String qualityParam = quality ?? (fullQuality ? "full" : "");
  request.body = jsonEncode(<String, dynamic>{
    'UserData': <String, dynamic>{
      'User': userName,
      'DeviceId': deviceId,
    },
    "File": _normalizePath(file),
    "Quality": qualityParam,
  });

  try {
    var streamResponse = await request.send();
    final response = await Response.fromStream(streamResponse);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    // Log so we can see 404 etc. (e.g. wrong path on server)
    print(
        'apiGetImageBytes: server returned ${response.statusCode} for file: $file');
  } catch (err) {
    print('apiGetImageBytes error: $err');
    throw GetFoldersError();
  }
  return null;
}
