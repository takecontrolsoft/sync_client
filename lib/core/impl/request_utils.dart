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
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:sync_client/storage/storage.dart';

MediaType? getMediaType(String filename) {
  final detectedFileType = lookupMimeType(filename);
  if (detectedFileType == null) return null;
  return MediaType.parse(detectedFileType);
}

Uri getUrl(String relPath) {
  if (currentDeviceSettings.serverUrl == null) {
    return Uri();
  }
  return Uri.parse("${currentDeviceSettings.serverUrl!}/$relPath");
}
