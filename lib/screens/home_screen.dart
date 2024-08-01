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
      body: const _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();

  @override
  Widget build(BuildContext context) {
    final DeviceServicesCubit deviceService =
        context.watch<DeviceServicesCubit>();
    if (deviceService.currentUser == null) {
      context.push("/login");
    }
    deviceService.state.lastErrorMessage = "";
    return Container(
        margin: const EdgeInsets.only(
            left: 10.0, right: 10.0, top: 30.0, bottom: 30.0),
        child: Column(children: [
          SingleChildScrollView(
            child: ListView(
              shrinkWrap: true,
              children: [
                Card(
                    child: ListTile(
                  title: const Text("Server address"),
                  leading: const Icon(Icons.cloud),
                  subtitle: BlocConsumer<DeviceServicesCubit, DeviceSettings>(
                      listener: (context, state) => state.serverUrl,
                      builder: (context, state) {
                        return Text("Server set to: ${state.serverUrl ?? ""}");
                      }),
                  onTap: () {
                    context.push("/servers");
                  },
                )),
                Card(
                    child: ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text("Folders to sync"),
                  subtitle: BlocConsumer<DeviceServicesCubit, DeviceSettings>(
                      listener: (context, state) => state.mediaDirectories,
                      builder: (context, state) {
                        return Text(
                          "Selected folders count: ${state.mediaDirectories.length}",
                        );
                      }),
                  onTap: () {
                    context.push("/folders");
                  },
                )),
                Card(
                    child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text("Last synced file date"),
                  subtitle: BlocConsumer<DeviceServicesCubit, DeviceSettings>(
                      listener: (context, state) => state.lastSyncDateTime,
                      builder: (context, state) {
                        final DateFormat formatter =
                            DateFormat('yyyy-MM-dd hh:ss');
                        return Text(
                          "Selected folders count: ${formatter.format(state.lastSyncDateTime!)}",
                        );
                      }),
                  onTap: () {
                    context.push("/dates");
                  },
                ))
              ],
            ),
          ),
          SizedBox(
              width: double.maxFinite,
              child: okButton(context, "Send to server",
                  onPressed: () => _run(deviceService))),
          Padding(
            padding: const EdgeInsets.all(25),
            child: BlocConsumer<DeviceServicesCubit, DeviceSettings>(
                listener: (context, state) => state.lastErrorMessage,
                builder: (context, state) {
                  return Text(state.lastErrorMessage ?? "",
                      style: errorTextStyle(context),
                      textAlign: TextAlign.center);
                }),
          ),
        ]));
  }

  void _run(DeviceServicesCubit deviceService) async {
    String errorText = "";
    if (deviceService.currentUser == null) {
      errorText = "No logged in user.";
    }
    if (deviceService.currentUser!.email.isEmpty) {
      errorText = "Missing user name.";
    }
    if (deviceService.state.mediaDirectories.isEmpty) {
      errorText = "Please select folders to sync.";
    }
    if (deviceService.state.serverUrl == null) {
      errorText = "Please select server address.";
    }
    deviceService.state.lastErrorMessage = errorText;
    if (errorText.isNotEmpty) {
      return;
    }
    BackgroundAction().execute(deviceService.currentUser!.email);
    saveDeviceSettings(deviceService.state);
  }
}
