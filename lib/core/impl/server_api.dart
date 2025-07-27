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
import 'package:sync_client/core/core.dart';
import 'package:sync_client/storage/storage.dart';

import 'request_utils.dart';

Future<List<NetFolder>?> apiGetFolders(String userName, String deviceId) async {
  var request = Request('POST', getUrl("folders"));
  request.headers.addAll(
      <String, String>{'Content-Type': 'application/json; charset=UTF-8'});

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
  request.headers.addAll(
      <String, String>{'Content-Type': 'application/json; charset=UTF-8'});

  request.body = jsonEncode(<String, dynamic>{
    'UserData': <String, dynamic>{
      'User': userName,
      'DeviceId': deviceId,
    },
    "Folder": folder
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

Future<bool> apiDeleteAllFiles(String userName, String deviceId) async {
  var request = Request('POST', getUrl("delete-all"));
  request.headers.addAll(
      <String, String>{'Content-Type': 'application/json; charset=UTF-8'});

  request.body = jsonEncode(<String, dynamic>{
    'User': userName,
    'DeviceId': deviceId,
  });
  try {
    var response = await request.send();
    if (response.statusCode == 200) {
      return true;
    }
  } catch (err) {
    throw GetFoldersError();
  }
  return false;
}

Future<Uint8List?> apiGetImageBytes(
  String userName,
  String deviceId,
  String file, {
  bool fullQuality = false,
}) async {
  var request = Request('POST', getUrl("img"));
  request.headers.addAll(
      <String, String>{'Content-Type': 'application/json; charset=UTF-8'});

  request.body = jsonEncode(<String, dynamic>{
    'UserData': <String, dynamic>{
      'User': userName,
      'DeviceId': deviceId,
    },
    "File": file,
    "Quality": fullQuality ? "full" : ""
  });

  try {
    var streamResponse = await request.send();
    final response = await Response.fromStream(streamResponse);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
  } catch (err) {
    throw GetFoldersError();
  }
  return null;
}
