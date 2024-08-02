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
import 'package:sync_client/core/core.dart';
import 'package:sync_client/storage/storage.dart';

abstract class IAction {
  Future<Stream<ProcessedFile>> execute(
      StreamController<ProcessedFile> processedFileController, String userName);
}

class BackgroundAction implements IAction {
  final Transfers _transfers;

  BackgroundAction() : _transfers = Transfers();

  @override
  Future<Stream<ProcessedFile>> execute(
      StreamController<ProcessedFile> processedFileController,
      String userName) async {
    final dirs = await _getSourceDirectories();
    if (dirs == null) {
      return processedFileController.stream;
    }
    DateTime lastMaxSyncedFileDate =
        currentDeviceSettings.lastSyncDateTime ?? DateTime(1800);
    DateTime maxSyncedFileDate = lastMaxSyncedFileDate;
    for (var dir in dirs) {
      final files = await getFilesFromExternalStorage(dir);
      if (processedFileController.isClosed) {
        return processedFileController.stream;
      }
      DateTime lastFileDate = await _uploadFiles(
          processedFileController, files, userName, lastMaxSyncedFileDate);
      if (lastFileDate.isAfter(maxSyncedFileDate)) {
        maxSyncedFileDate = lastFileDate;
      }
    }
    currentDeviceSettings.lastSyncDateTime =
        maxSyncedFileDate == DateTime(1800) ? null : maxSyncedFileDate;
    return processedFileController.stream;
  }

  Future<Iterable<Directory>?> _getSourceDirectories() async {
    if (currentDeviceSettings.name.isEmpty) {
      return Future.value();
    }
    return currentDeviceSettings.mediaDirectories.map((e) => Directory(e));
  }

  Future<DateTime> _uploadFiles(
      StreamController<ProcessedFile> processedFileController,
      List<FileSystemEntity> files,
      String userName,
      DateTime lastMaxSyncedFileDate) async {
    DateTime maxSyncedFileDate = lastMaxSyncedFileDate;
    for (var file in files) {
      if (!FileSystemEntity.isDirectorySync(file.path)) {
        DateTime lastFileDate = await File(file.path).lastModified();
        String dateClassifier = "${lastFileDate.year}-${lastFileDate.month}";

        if (lastFileDate.isAfter(lastMaxSyncedFileDate)) {
          if (processedFileController.isClosed) {
            return maxSyncedFileDate;
          }
          if (await _transfers.sendFile(
              processedFileController, file.path, userName, dateClassifier)) {
            if (lastFileDate.isAfter(maxSyncedFileDate)) {
              maxSyncedFileDate = lastFileDate;
            }
          }
        }
      }
    }
    return maxSyncedFileDate;
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
