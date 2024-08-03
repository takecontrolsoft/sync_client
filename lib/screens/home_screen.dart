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
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: HomeScreenView(),
    );
  }
}

class HomeScreenView extends StatelessWidget {
  HomeScreenView();
  StreamController<ProcessedFile> processedFileController =
      StreamController<ProcessedFile>();

  @override
  Widget build(BuildContext context) {
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();
    deviceService.state.lastErrorMessage = null;

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
                subtitle: Reactive<DeviceServicesCubit, DeviceSettings>(
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
                subtitle: Reactive<DeviceServicesCubit, DeviceSettings>(
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
                leading: const Icon(Icons.calendar_today),
                title: const Text("Last synced file date"),
                subtitle: Reactive<DeviceServicesCubit, DeviceSettings>(
                    child: (context, state) {
                  final DateFormat formatter = DateFormat('yyyy-MM-dd hh:ss');
                  return Text(
                      'Date time: ${state.lastSyncDateTime == null ? "" : formatter.format(state.lastSyncDateTime!)}');
                }),
                onTap: () {
                  context.push("/dates");
                },
              ))
            ],
          ),
          SizedBox(
              width: double.maxFinite,
              child: syncButton(context,
                  child: const Text("Send to server"),
                  onPressed: () => _run(deviceService))),
          Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Reactive<DeviceServicesCubit, DeviceSettings>(
                buildWhen: (previous, current) =>
                    current.lastErrorMessage == null ||
                    previous.lastErrorMessage != current.lastErrorMessage,
                child: (context, state) => SyncFilesStatusWidget(
                  context,
                  deviceService,
                  processedFileController,
                ),
              ))
        ]),
      ),
    );
  }

  void _run(DeviceServicesCubit deviceService) async {
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
    if (deviceService.state.serverUrl == null) {
      errorText = "Please select server address.";
    }

    if (errorText.isNotEmpty) {
      await deviceService.edit((state) {
        state.lastErrorMessage = errorText;
      });
      return;
    }

    if (processedFileController.isClosed) {
      processedFileController = StreamController<ProcessedFile>();
    }
    await deviceService.edit((state) {
      state.lastErrorMessage = null;
    });
    await BackgroundAction().execute(
        processedFileController, deviceService.state.currentUser!.email);

    await deviceService.edit((state) {
      state.lastSyncDateTime = currentDeviceSettings.lastSyncDateTime;
    });
    processedFileController.close();
  }
}
