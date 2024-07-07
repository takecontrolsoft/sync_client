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
import 'package:sync_client/config/config.dart';
import 'package:sync_client/storage/storage.dart';

import 'transfers.dart';

abstract class IAction {
  Future<void> execute();
}

class BackgroundAction implements IAction {
  final Transfers _transfers;

  BackgroundAction() : _transfers = Transfers();

  @override
  Future<void> execute() async {
    final dirs =
        await DeviceSettings.getSourceDirectories(currentDevice.settings);
    if (dirs == null) {
      return;
    }
    for (var dir in dirs) {
      final files = await getFilesFromExternalStorage(dir);
      await _uploadFiles(files);
    }
  }

  Future<void> _uploadFiles(List<FileSystemEntity> files) async {
    for (var file in files) {
      if (!FileSystemEntity.isDirectorySync(file.path)) {
        await _transfers.sendFile(file.path);
      }
    }
  }

  Future<List<FileSystemEntity>> getFilesFromExternalStorage(
      Directory dir) async {
    List<FileSystemEntity> entities = await dir.list().toList();
    List<FileSystemEntity> finalEntities = [];
    entities.removeWhere((entity) {
      return entity.path == '/storage/emulated/0/Android';
    });
    for (var entity in entities) {
      if (entity is Directory) {
        try {
          var sub = await entity.list(recursive: true).toList();
          finalEntities.addAll(sub);
        } catch (e) {
          continue;
        }
      } else {
        finalEntities.add(entity);
      }
    }
    return finalEntities;
  }
}
