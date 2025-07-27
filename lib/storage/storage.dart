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
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sync_client/storage/schema.dart';

export 'schema.dart';

const dataFilename = "deviceSettings.json";
late DeviceSettings currentDeviceSettings;

Future<DeviceSettings> updateCurrentDevice(
    DeviceSettings deviceSettings) async {
  deviceSettings.id = const Uuid().v4();
  return deviceSettings;
}

Future<void> loadDeviceSettings() async {
  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File jsonFile = File("${appDocDir.path}/$dataFilename");

    if (!await jsonFile.exists() || jsonFile.readAsStringSync().isEmpty) {
      // Try to load from bundled asset
      try {
        ByteData realmBytes = await rootBundle.load("data/$dataFilename");
        await jsonFile.writeAsBytes(
          realmBytes.buffer
              .asUint8List(realmBytes.offsetInBytes, realmBytes.lengthInBytes),
          mode: FileMode.write,
        );
      } catch (e) {
        // If asset doesn't exist, create default settings
        print(
            'No bundled deviceSettings.json found, creating default settings');
        currentDeviceSettings = await updateCurrentDevice(DeviceSettings(""));
        await saveDeviceSettings(currentDeviceSettings);
        return;
      }

      final jsonAsString = await jsonFile.readAsString();

      DeviceSettings deviceSettings;
      if (jsonAsString.isNotEmpty) {
        try {
          final jsonData = jsonDecode(jsonAsString);
          // Ensure mediaDirectories exists and is a list
          jsonData['mediaDirectories'] ??= [];
          deviceSettings = DeviceSettings.fromJson(jsonData);
        } catch (e) {
          print('Error parsing bundled deviceSettings.json: $e');
          deviceSettings = DeviceSettings("");
        }
      } else {
        deviceSettings = DeviceSettings("");
      }

      currentDeviceSettings = await updateCurrentDevice(deviceSettings);
      jsonFile.writeAsStringSync(jsonEncode(currentDeviceSettings.toJson()));
    }

    // Read and parse the JSON file
    final jsonAsString = jsonFile.readAsStringSync();

    if (jsonAsString.isEmpty) {
      // Empty file, create default settings
      currentDeviceSettings = await updateCurrentDevice(DeviceSettings(""));
      await saveDeviceSettings(currentDeviceSettings);
      return;
    }

    try {
      final jsonData = jsonDecode(jsonAsString);

      // Ensure mediaDirectories is not null
      if (jsonData is Map<String, dynamic>) {
        jsonData['mediaDirectories'] ??= [];

        // Ensure it's a list
        if (jsonData['mediaDirectories'] is! List) {
          jsonData['mediaDirectories'] = [];
        }
      }

      currentDeviceSettings = DeviceSettings.fromJson(jsonData);
    } catch (e) {
      print('Error parsing deviceSettings.json: $e');
      // If parsing fails, create default settings
      currentDeviceSettings = await updateCurrentDevice(DeviceSettings(""));
      await saveDeviceSettings(currentDeviceSettings);
    }
  } catch (e) {
    print('Error loading device settings: $e');
    // Final fallback - create default settings
    currentDeviceSettings = DeviceSettings("");
    currentDeviceSettings.id = const Uuid().v4();
  }
}

Future<void> saveDeviceSettings(DeviceSettings deviceSettings) async {
  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File jsonFile = File("${appDocDir.path}/$dataFilename");

    // Ensure the data is valid before saving
    final jsonData = deviceSettings.toJson();
    jsonData['mediaDirectories'] ??= [];

    jsonFile.writeAsStringSync(jsonEncode(jsonData));
  } catch (e) {
    print('Error saving device settings: $e');
  }
}

Future<void> deleteDeviceSettings() async {
  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File jsonFile = File("${appDocDir.path}/$dataFilename");

    if (await jsonFile.exists()) {
      await jsonFile.delete();
    }

    // Create fresh default settings
    currentDeviceSettings = DeviceSettings("");
    currentDeviceSettings.id = const Uuid().v4();
    await saveDeviceSettings(currentDeviceSettings);
  } catch (e) {
    print('Error deleting device settings: $e');
    // Fallback to default settings
    currentDeviceSettings = DeviceSettings("");
    currentDeviceSettings.id = const Uuid().v4();
  }
}

// Optional: Add a migration function
Future<void> migrateDeviceSettings() async {
  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File jsonFile = File("${appDocDir.path}/$dataFilename");

    if (await jsonFile.exists()) {
      final jsonAsString = jsonFile.readAsStringSync();
      if (jsonAsString.isNotEmpty) {
        final jsonData = jsonDecode(jsonAsString);

        bool needsUpdate = false;

        // Fix missing or null mediaDirectories
        if (jsonData['mediaDirectories'] == null ||
            jsonData['mediaDirectories'] is! List) {
          jsonData['mediaDirectories'] = [];
          needsUpdate = true;
        }

        // Add other migrations as needed

        if (needsUpdate) {
          await jsonFile.writeAsString(jsonEncode(jsonData));
        }
      }
    }
  } catch (e) {
    print('Error migrating device settings: $e');
  }
}
