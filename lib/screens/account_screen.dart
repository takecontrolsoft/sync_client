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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: const AccountScreenView(),
    );
  }
}

class AccountScreenView extends StatelessWidget {
  const AccountScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();
    deviceService.state.lastErrorMessage = null;
    deviceService.state.successMessage = "";

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
            ],
          ),
          SizedBox(
              width: double.maxFinite,
              child: okButton(context, "Delete my server files",
                  onPressed: () => deleteServerFiles(deviceService))),
          SizedBox(
              width: double.maxFinite,
              child: okButton(context, "Delete my local settings",
                  onPressed: () =>
                      deleteDeviceSettings(context, deviceService))),
          Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
                  buildWhen: (previous, current) =>
                      current.lastErrorMessage == null ||
                      previous.lastErrorMessage != current.lastErrorMessage,
                  child: (context, state) => Text(
                      deviceService.state.lastErrorMessage ??
                          deviceService.state.successMessage ??
                          "",
                      style: deviceService.state.lastErrorMessage == null
                          ? successTextStyle(context)
                          : errorTextStyle(context),
                      textAlign: TextAlign.center))),
        ]),
      ),
    );
  }

  void deleteServerFiles(DeviceServicesCubit deviceService) async {
    String errorText = "";
    if (!deviceService.isAuthenticated()) {
      errorText = "No logged in user.";
    }

    if (deviceService.state.currentUser!.email.isEmpty) {
      errorText = "Missing user name.";
    }
    if (deviceService.state.serverUrl == null) {
      errorText = "Please select server address.";
    }
    if (errorText.isEmpty) {
      bool deleted = await apiDeleteAllFiles(
          deviceService.state.currentUser!.email, deviceService.state.id);
      if (!deleted) {
        errorText =
            "An error ocurred while deleting your files from the server.";
      }
    }
    if (errorText.isNotEmpty) {
      await deviceService.edit((state) {
        state.lastErrorMessage = errorText;
      });
      return;
    }

    await deviceService.edit((state) {
      state.lastErrorMessage = null;
      state.lastSyncDateTime = null;
      state.syncedFiles.clear();
      state.successMessage = "Files deleted successfully from the server.";
    });
  }

  Future<void> deleteDeviceSettings(
      BuildContext context, DeviceServicesCubit deviceService) async {
    try {
      await deviceService.logOut();
      await deviceService.clearDeviceSettings();
      // ignore: use_build_context_synchronously
      if (context.canPop()) {
        // ignore: use_build_context_synchronously
        context.pop();
      }
      // ignore: use_build_context_synchronously
      context.push('/login');
    } catch (err) {
      await deviceService.edit((state) {
        state.lastErrorMessage =
            "An error ocurred while deleting local file with your settings.";
        state.successMessage = null;
      });
    }
  }
}
