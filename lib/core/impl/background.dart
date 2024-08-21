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
  Future<Stream<SyncedFile>> execute(
      StreamController<SyncedFile> syncFileController, String userName);
}

class BackgroundAction implements IAction {
  final Transfers _transfers;

  BackgroundAction() : _transfers = Transfers();

  @override
  Future<Stream<SyncedFile>> execute(
      StreamController<SyncedFile> syncFileController, String userName) async {
    final dirs = await _getSourceDirectories();
    if (dirs == null) {
      return syncFileController.stream;
    }
    for (var dir in dirs) {
      final files = await getFilesFromExternalStorage(dir);
      if (syncFileController.isClosed) {
        return syncFileController.stream;
      }
      await _uploadFiles(syncFileController, files, userName);
    }
    return syncFileController.stream;
  }

  Future<Iterable<Directory>?> _getSourceDirectories() async {
    if (currentDeviceSettings.id.isEmpty) {
      return Future.value();
    }
    return currentDeviceSettings.mediaDirectories.map((e) => Directory(e));
  }

  Future<void> _uploadFiles(StreamController<SyncedFile> syncFileController,
      List<FileSystemEntity> files, String userName) async {
    for (var file in files) {
      if (syncFileController.isClosed) {
        return;
      }
      if (!FileSystemEntity.isDirectorySync(file.path)) {
        DateTime lastFileDate = await File(file.path).lastModified();
        String dateClassifier = "${lastFileDate.year}-${lastFileDate.month}";

        final fileHadBeenSynced = currentDeviceSettings.syncedFiles.any((f) =>
            f.filename.toLowerCase() == file.path.toLowerCase() &&
            (f.errorMessage ?? "").trim() == "");
        if (!fileHadBeenSynced) {
          var syncedFile = await _transfers.sendFile(
              syncFileController, file.path, userName, dateClassifier);

          if (syncedFile != null) {
            if ((currentDeviceSettings.deleteLocalFilesEnabled ?? false) &&
                syncedFile.errorMessage == null) {
              await File(syncedFile.filename).delete();
              currentDeviceSettings.syncedFiles.remove(syncedFile);
            } else {
              SyncedFile? fileFromList = currentDeviceSettings.syncedFiles
                  .firstWhere(
                      (f) =>
                          f.filename.toLowerCase() == file.path.toLowerCase(),
                      orElse: () {
                currentDeviceSettings.syncedFiles.add(syncedFile);
                return syncedFile;
              });
              fileFromList.errorMessage = syncedFile.errorMessage;
            }
          }
        }
      }
    }
    currentDeviceSettings.lastErrorMessage = null;
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
