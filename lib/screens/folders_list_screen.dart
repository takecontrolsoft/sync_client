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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

class FoldersListScreen extends StatelessWidget {
  const FoldersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceService = context.read<DeviceServicesCubit>();
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: const _FoldersListScreenView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => selectSourceDir(context, deviceService),
        tooltip: 'Select folder',
        child: const Icon(Icons.add),
      ),
    );
  }

  void selectSourceDir(
      BuildContext context, DeviceServicesCubit deviceService) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      return;
    }
    await deviceService.edit((state) {
      state.mediaDirectories.add(selectedDirectory);
      state.lastSyncDateTime = null;
    });
  }
}

class _FoldersListScreenView extends StatelessWidget {
  const _FoldersListScreenView();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
          left: 10.0, right: 10.0, top: 30.0, bottom: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Selected directories to sync:',
          ),
          Reactive<DeviceServicesCubit, DeviceSettings>(
              buildWhen: (previous, current) =>
                  previous.mediaDirectories.length !=
                  current.mediaDirectories.length,
              child: (context, state) => ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.mediaDirectories.length,
                    itemBuilder: (context, index) => state.mediaDirectories
                            .elementAt(index)
                            .isNotEmpty
                        ? FolderItem(state.mediaDirectories.elementAt(index))
                        : Container(),
                  ))
        ],
      ),
    );
  }
}
