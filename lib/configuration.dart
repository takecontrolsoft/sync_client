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

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';

class Configuration {
  final Set<String> dirs = {};
  final serverUrl = Platform.environment["SYNC_SERVER_URL"];
  static final Configuration _configuration = Configuration._internal();
  String? _deviceName;

  factory Configuration() {
    return _configuration;
  }

  Configuration._internal();

  void selectSourceDir() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      return;
    }
    dirs.add(selectedDirectory);
  }

  Iterable<Directory> getSourceDirs() {
    return dirs.map((e) => Directory(e));
  }

  Future<String> getDeviceInfo() async {
    if (_deviceName == null) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.deviceInfo;
      _deviceName = deviceInfo.data["deviceId"];
      _deviceName ??= deviceInfo.data["id"];
      _deviceName ??= deviceInfo.data["model"];
      _deviceName ??= "unknown";
    }
    return _deviceName!;
  }
}
