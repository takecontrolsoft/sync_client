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
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

enum DeletingEnabledMenuOption { enableDeleting }

class DeletingEnabledScreen extends StatelessWidget {
  const DeletingEnabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MainAppBar.appBar(context),
        body: const _DeletingEnabledScreenView());
  }
}

class _DeletingEnabledScreenView extends StatelessWidget {
  const _DeletingEnabledScreenView();

  @override
  Widget build(BuildContext context) {
    final deviceService = context.read<DeviceServicesCubit>();
    return Container(
      margin: const EdgeInsets.only(
          left: 10.0, right: 10.0, top: 30.0, bottom: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Delete synced files from this device?',
          ),
          ListTile(
              leading: const Icon(Icons.clear),
              title: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
                  buildWhen: (previous, current) =>
                      previous.deleteLocalFilesEnabled !=
                      current.deleteLocalFilesEnabled,
                  child: (context, state) {
                    return Text(
                        'Deleting: ${state.deleteLocalFilesEnabled ?? false ? "ON" : "OFF"}');
                  }),
              trailing: SizedBox(
                width: 25,
                child: PopupMenuButton<DeletingEnabledMenuOption>(
                  onSelected: (menuItem) =>
                      handleMenuClick(context, deviceService, menuItem),
                  itemBuilder: (context) => [
                    PopupMenuItem<DeletingEnabledMenuOption>(
                      value: DeletingEnabledMenuOption.enableDeleting,
                      child: ListTile(
                          leading: const Icon(Icons.reset_tv),
                          title: Text(
                              'Switched: ${deviceService.state.deleteLocalFilesEnabled ?? false ? "OFF" : "ON"}')),
                    ),
                  ],
                ),
              ),
              shape: const Border(bottom: BorderSide()))
        ],
      ),
    );
  }

  void handleMenuClick(BuildContext context, DeviceServicesCubit deviceService,
      DeletingEnabledMenuOption menuItem) async {
    if (menuItem == DeletingEnabledMenuOption.enableDeleting) {
      if ((deviceService.state.deleteLocalFilesEnabled ?? false)) {
        await deviceService.edit((state) {
          state.deleteLocalFilesEnabled =
              !(state.deleteLocalFilesEnabled ?? false);
          state.lastErrorMessage = null;
        });
      } else {
        showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: const Text('Local files deleting: ON'),
                  content: const Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: <Widget>[
                        Text(
                          'WARNING: Switching this option to ON will cause DELETING synced files from this device.',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'The files are deleted only if they are successfully send to the server.',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'If you confirm the files will be deleted from the device after the next sync operation.',
                          textAlign: TextAlign.center,
                        ),
                      ]),
                  actions: [
                    okButton(context, "Confirm", onPressed: () async {
                      await deviceService.edit((state) {
                        state.deleteLocalFilesEnabled =
                            !(state.deleteLocalFilesEnabled ?? false);
                        state.lastErrorMessage = null;
                      });
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    }),
                    cancelButton(context)
                  ],
                ));
      }
    }
  }
}
