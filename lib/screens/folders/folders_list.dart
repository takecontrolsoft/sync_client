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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/service_locator.dart';

import 'folders_cubit.dart';

class FoldersListScreen extends StatelessWidget {
  const FoldersListScreen({super.key});

  void _selectFolders(BuildContext context) {
    context.read<FoldersCubit>().selectSourceDir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: _FoldersListScreenView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectFolders(context),
        tooltip: 'Select folder',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FoldersListScreenView extends StatelessWidget {
  _FoldersListScreenView();

  final _config = getIt<Configuration>();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Selected directories to sync:',
          ),
          BlocConsumer<FoldersCubit, String>(
            listener: (context, state) => _config.dirs.add(state),
            builder: (context, state) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: _config.dirs.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text('Directory: ${_config.dirs.elementAt(index)}'),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
