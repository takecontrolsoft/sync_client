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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadDeviceSettings();
  if (Platform.isAndroid) {
    final mediaStorePlugin = MediaStore();
    await mediaStorePlugin.getPlatformSDKInt();
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = "MediaStorePlugin";
    await requestPermissions();
  }

  runApp(const BlocProviders());
}

Future<void> requestPermissions() async {
  List<Permission> permissions = [
    Permission.storage,
  ];
  permissions.add(Permission.storage);
  permissions.add(Permission.photos);
  permissions.add(Permission.audio);
  permissions.add(Permission.videos);

  final mapPermissions = await permissions.request();
  for (var i = 0; i < permissions.length; i++) {
    if (mapPermissions[permissions[i]]!.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
}

class BlocProviders extends StatelessWidget {
  const BlocProviders({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DeviceServicesCubit()),
        BlocProvider(create: (context) => SyncServicesCubit()),
        BlocProvider(create: (context) => ThemeCubit()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        title: 'Mobi Sync Client',
        debugShowCheckedModeBanner: false,
        routerConfig: getAppRouter(),
        theme: AppTheme.getTheme(context));
  }
}
