/*
	Copyright 2023 Take Control - Software & Infrastructure

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
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as path;
import 'package:sync_client/core/core.dart';
import 'package:sync_client/storage/storage.dart';

class Transfers {
  Transfers();

  MediaType? _getMediaType(String filename) {
    final detectedFileType = lookupMimeType(filename);
    if (detectedFileType == null) return null;
    return MediaType.parse(detectedFileType);
  }

  Uri _getUrl(String relPath) {
    if (currentDeviceSettings.serverUrl == null) {
      return Uri();
    }
    return Uri.parse("${currentDeviceSettings.serverUrl!}/$relPath");
  }

  Future<bool> sendFile(StreamController<ProcessedFile> processedFileController,
      String filename, String userName, String dateClassifier) async {
    var request = MultipartRequest('POST', _getUrl("upload"));
    final hdr = <String, String>{"user": userName, "date": dateClassifier};
    request.headers.addEntries(hdr.entries);
    final file = File(filename);
    final len = file.lengthSync();
    final name = path.basename(filename);
    try {
      request.files.add(MultipartFile(
          currentDeviceSettings.name, file.openRead(), len,
          filename: name, contentType: _getMediaType(filename)));
      var streamedResponse = await request.send();
      var response = await Response.fromStream(streamedResponse);
      if (processedFileController.isClosed) {
        return false;
      } else {
        processedFileController.add(ProcessedFile(filename));
        print("SENT: $filename");
        return response.statusCode == 200;
      }
    } catch (err) {
      currentDeviceSettings.lastErrorMessage =
          "ERROR: $filename [${err.toString()}]";
      if (processedFileController.isClosed) {
        return false;
      }
      processedFileController
          .addError(SyncError(currentDeviceSettings.lastErrorMessage!));

      print(currentDeviceSettings.lastErrorMessage);
      return false;
    }
  }
}
