// ignore_for_file: must_be_immutable

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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: const SyncScreenView(),
    );
  }
}

class SyncScreenView extends StatelessWidget {
  const SyncScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();
    final SyncServicesCubit syncService = context.read<SyncServicesCubit>();

    deviceService.state.lastErrorMessage = null;
    deviceService.state.isSyncing = false;

    if (!deviceService.isAuthenticated()) {
      context.push("/login");
      return Container();
    }

    return Container(
      margin: const EdgeInsets.only(
          left: 10.0, right: 10.0, top: 30.0, bottom: 30.0),
      child: SingleChildScrollView(
        child: Column(children: [
          ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Text(
                  "Nickname: ${deviceService.state.currentUser?.email ?? ""}",
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              Card(
                  child: ListTile(
                title: const Text("Server address"),
                leading: const Icon(Icons.cloud),
                subtitle: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
                    child: (context, state) =>
                        Text("Server set to: ${state.serverUrl ?? ""}"),
                    buildWhen: (previous, current) =>
                        previous.serverUrl != current.serverUrl),
                onTap: () {
                  context.push("/servers");
                },
              )),
              Card(
                  child: ListTile(
                leading: const Icon(Icons.folder),
                title: const Text("Folders to sync"),
                subtitle: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
                    child: (context, state) => Text(
                        "Selected folders count: ${state.mediaDirectories.length}"),
                    buildWhen: (previous, current) =>
                        previous.mediaDirectories.length !=
                        current.mediaDirectories.length),
                onTap: () {
                  context.push("/folders");
                },
              )),
              Card(
                  child: ListTile(
                leading: const Icon(Icons.clear),
                title: const Text("Delete synced files from this device?"),
                subtitle: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
                    child: (context, state) {
                  return Text(
                      'Deleting: ${state.deleteLocalFilesEnabled ?? false ? "ON" : "OFF"}');
                }),
                onTap: () {
                  context.push("/deleteOption");
                },
              ))
            ],
          ),
          SizedBox(
              width: double.maxFinite,
              child: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
                  buildWhen: (previous, current) =>
                      previous.isSyncing != current.isSyncing,
                  child: (context, state) => syncButton(context,
                      child: Text((deviceService.state.isSyncing ?? false)
                          ? "Syncing ..."
                          : "Send to server"),
                      onPressed: () async => (deviceService.state.isSyncing ??
                              false)
                          ? null
                          : await _sync(context, deviceService, syncService)))),
          Center(
              child: Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
                      buildWhen: (previous, current) =>
                          previous.syncedFiles.length !=
                              current.syncedFiles.length ||
                          current.lastErrorMessage == null ||
                          previous.lastErrorMessage != current.lastErrorMessage,
                      child: (context, state) => Text(
                          deviceService.state.lastErrorMessage ?? "",
                          style: errorTextStyle(context),
                          textAlign: TextAlign.center)))),
          Center(
              child: Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
                      buildWhen: (previous, current) =>
                          previous.isSyncing != current.isSyncing ||
                          previous.lastErrorMessage != current.lastErrorMessage,
                      child: (context, state) => syncService.state == null
                          ? Container()
                          : syncFilesStatusWidget(
                              context, deviceService, syncService))))
        ]),
      ),
    );
  }

  Future<void> _sync(BuildContext context, DeviceServicesCubit deviceService,
      SyncServicesCubit syncService) async {
    if (!(deviceService.state.deleteLocalFilesEnabled ?? false)) {
      await _run(context, deviceService, syncService);
    } else {
      final errorMessage = _validate(deviceService);
      if (errorMessage.isNotEmpty) {
        await deviceService.edit((state) {
          state.lastErrorMessage = errorMessage;
        });
      } else {
        showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: const Text('Synced files will be deleted'),
                  content: const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 20,
                      children: <Widget>[
                        Text(
                          'WARNING: Option Deleting=ON.',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'All the synced files will be deleted from this device.',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Would you like to continue?',
                          textAlign: TextAlign.center,
                        ),
                      ]),
                  actions: [
                    okButton(context, "Confirm", onPressed: () {
                      Navigator.pop(context);
                      _run(context, deviceService, syncService);
                    }),
                    cancelButton(context)
                  ],
                ));
      }
    }
  }

  Future<void> _run(BuildContext context, DeviceServicesCubit deviceService,
      SyncServicesCubit syncService) async {
    if (deviceService.state.isSyncing ?? false) return;
    final errorMessage = _validate(deviceService);
    if (errorMessage.isNotEmpty) {
      await deviceService.edit((state) {
        state.lastErrorMessage = errorMessage;
      });
      return;
    }
    syncService.reset();

    await deviceService.edit((state) {
      state.lastErrorMessage = null;
      state.isSyncing = true;
    });

    try {
      syncService.state!.add(SyncedFile("Syncing ..."));
      Future<void>.delayed(const Duration(microseconds: 10));
      await BackgroundAction()
          .execute(syncService.state!, deviceService.state.currentUser!.email);
      await deviceService.edit((state) {
        state.lastSyncDateTime = DateTime.now();
      });
    } on Exception catch (e) {
      await deviceService.edit((state) {
        state.lastErrorMessage = e.toString();
      });
    }
    await deviceService.edit((state) {
      state.isSyncing = false;
    });
    syncService.state!.close();
  }

  String _validate(DeviceServicesCubit deviceService) {
    String errorText = "";
    if (!deviceService.isAuthenticated()) {
      errorText = "No logged in user.";
    }
    if (deviceService.state.currentUser!.email.isEmpty) {
      errorText = "Missing user name.";
    }
    if (deviceService.state.mediaDirectories.isEmpty) {
      errorText = "Please select folders to sync.";
    }
    if ((deviceService.state.serverUrl ?? "") == "") {
      errorText = "Please select server address.";
    }

    return errorText;
  }
}
