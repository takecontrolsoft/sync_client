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
import 'package:realm/realm.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/storage/realm.dart';
import 'package:sync_client/storage/storage.dart';

import '../components/widgets.dart';

class FoldersListScreen extends StatelessWidget {
  const FoldersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: const _FoldersListScreenView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => selectSourceDir(context),
        tooltip: 'Select folder',
        child: const Icon(Icons.add),
      ),
    );
  }

  void selectSourceDir(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      return;
    }
    localRealm.write(() {
      currentDevice.settings?.mediaDirectories.add(selectedDirectory);
    });
  }
}

class _FoldersListScreenView extends StatelessWidget {
  const _FoldersListScreenView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Selected directories to sync:',
          ),
          StreamBuilder<RealmSetChanges<String>>(
            stream: currentDevice.settings?.mediaDirectories.changes,
            builder: (context, snapshot) {
              final data = snapshot.data;

              if (data == null) return waitingIndicator();

              final results = data.set.asResults();
              return ListView.builder(
                shrinkWrap: true,
                itemCount: results.realm.isClosed ? 0 : results.length,
                itemBuilder: (context, index) => results[index].isNotEmpty
                    ? ListTile(title: Text('Directory: ${results[index]}'))
                    : Container(),
              );
            },
          ),
        ],
      ),
    );
  }
}
