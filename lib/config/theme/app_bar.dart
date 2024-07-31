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
import 'package:sync_client/config/theme/theme_cubit.dart';
import 'package:sync_client/services/device_services.dart';

class MainAppBar {
  static AppBar appBar(BuildContext context) {
    final ThemeCubit theme = context.watch<ThemeCubit>();
    final DeviceServicesCubit deviceService =
        context.watch<DeviceServicesCubit>();
    return AppBar(
      title: const Text("Mobi Sync Client"),
      actions: [
        IconButton(
          icon: theme.state.isDarkMode
              ? const Icon(Icons.dark_mode_outlined)
              : const Icon(Icons.light_mode_outlined),
          tooltip: 'Change theme',
          onPressed: () {
            theme.toggleTheme();
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: () async => await logOut(context, deviceService),
        ),
      ],
    );
  }

  static Future<void> logOut(
      BuildContext context, DeviceServicesCubit deviceService) async {
    await deviceService.logOut();
    // ignore: use_build_context_synchronously
    context.push('/login');
  }
}
