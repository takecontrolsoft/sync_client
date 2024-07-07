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

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:sync_client/storage/schema.dart';

class DeviceSettings {
  static Future<DeviceInfo> currentDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = await deviceInfoPlugin.deviceInfo;
    String? deviceName = deviceInfo.data["deviceId"];
    deviceName ??= deviceInfo.data["id"];
    deviceName ??= deviceInfo.data["model"];
    deviceName ??= "unknown";
    DeviceInfo di = DeviceInfo(deviceName,
        id: deviceInfo.data["id"], model: deviceInfo.data["model"]);
    return di;
  }

  static Future<Iterable<Directory>?> getSourceDirectories(
      Settings? settings) async {
    if (settings == null) {
      return Future.value();
    }
    return settings.mediaDirectories.map((e) => Directory(e));
  }
}
