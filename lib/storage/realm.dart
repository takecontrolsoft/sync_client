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

import 'package:realm/realm.dart';
import 'package:sync_client/config/config.dart';
import 'package:path/path.dart' as path;
import 'schema.dart';

final Realm localRealm = Realm(Configuration.local(
  [Settings.schema, DeviceInfo.schema, DeviceError.schema],
  path: path.join(Configuration.defaultStoragePath, 'settings.realm'),
));
late DeviceInfo currentDevice;

Future<DeviceInfo> initCurrentDevice() async {
  print(localRealm.config.path);
  currentDevice = await DeviceSettings.currentDeviceInfo();
  DeviceInfo? device = localRealm
      .query<DeviceInfo>(r'name == $0', [currentDevice.name]).singleOrNull;
  if (device == null) {
    currentDevice.settings = Settings(
        serverUrl: Platform.environment["SYNC_SERVER_URL"],
        device: currentDevice);
    localRealm.write(() {
      device = localRealm.add(currentDevice);
    });
  }
  currentDevice = device!;
  return currentDevice;
}
