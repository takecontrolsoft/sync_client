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
import 'package:sync_client/services/device_services.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

Future<void> _confirmDeleteCachedImages(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Delete cached images'),
      content: const Text(
        'This will clear all cached thumbnails and images from this device. '
        'Images will be re-downloaded when you browse again.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  try {
    await ThumbnailCacheService.clear();
    await CacheService.clearCache();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cached images deleted')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

Future<void> _confirmDeleteSyncMetadata(
    BuildContext context, DeviceServicesCubit deviceService) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Delete Sync Metadata'),
      content: const Text(
        'This will clear sync metadata (synced file list, last sync time) from '
        'device settings (deviceSettings.json). Your account and selected folders '
        'to sync are kept.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  try {
    await deviceService.clearSyncMetadata();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync metadata deleted')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      deviceService.edit((state) {
        state.lastErrorMessage = 'Failed to delete sync metadata: $e';
        state.successMessage = null;
      });
    }
  }
}

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
          const Padding(
            padding: EdgeInsets.only(left: 25, top: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Data & cache",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: okButton(context, "Delete cached images",
                onPressed: () => _confirmDeleteCachedImages(context)),
          ),
          SizedBox(
            width: double.maxFinite,
            child: okButton(context, "Delete Sync Metadata",
                onPressed: () => _confirmDeleteSyncMetadata(context, deviceService)),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 25, top: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Account",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
              width: double.maxFinite,
              child: okButton(context, "Delete my local settings",
                  onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                            title: const Text('Delete my local settings'),
                            content: const Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                children: <Widget>[
                                  Text(
                                    'WARNING: This operation will delete you settings for this application.',
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'After this operation your account will be removed, but your photos/videos will still exist on the server.',
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Make sure next time you enter the application with the same Nickname if you want to access your synced files from the server.',
                                    textAlign: TextAlign.center,
                                  ),
                                ]),
                            actions: [
                              okButton(context, "Confirm", onPressed: () async {
                                deleteDeviceSettings(context, deviceService);
                                Navigator.pop(context);
                              }),
                              cancelButton(context)
                            ],
                          )))),
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
