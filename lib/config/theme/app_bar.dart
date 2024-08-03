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
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:popup_menu/popup_menu.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/config/theme/theme_cubit.dart';
import 'package:sync_client/services/device_services.dart';

enum AppMenuOption { home, sync, theme, account, logout }

class MainAppBar {
  static AppBar appBar(BuildContext context) {
    final ThemeCubit theme = context.watch<ThemeCubit>();
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();
    PopupMenu menu;
    GlobalKey btnKey = GlobalKey();

    void onClickMenu(MenuItemProvider item) async {
      print('Click menu -> ${item.menuTitle}');
      final option = item.menuUserInfo as AppMenuOption;
      switch (option) {
        case AppMenuOption.home:
          if (context.canPop()) {
            context.pop();
          }
        case AppMenuOption.sync:
          if (context.canPop()) {
            context.pop();
          }
          context.push("/sync");
        case AppMenuOption.theme:
          theme.toggleTheme();
        case AppMenuOption.account:
          if (context.canPop()) {
            context.pop();
          }
          context.push("/account");
        case AppMenuOption.logout:
          await logOut(context, deviceService);
      }
    }

    void onDismiss() {
      print('Menu is dismiss');
    }

    void onShow() {
      print('Menu is show');
    }

    void stateChanged(bool isShow) {
      print('menu is ${isShow ? 'showing' : 'closed'}');
    }

    void getMenu(BuildContext context) {
      PopupMenu menu = PopupMenu(
          context: context,
          config: MenuConfig(
              maxColumn: 4,
              backgroundColor:
                  theme.state.isDarkMode ? Colors.white : Colors.black,
              lineColor: Theme.of(context).listTileTheme.iconColor!),
          items: [
            mainMenuItem(context, AppMenuOption.home, "Home", Icons.home),
            mainMenuItem(context, AppMenuOption.sync, "Sync", Icons.sync),
            mainMenuItem(
                context,
                AppMenuOption.theme,
                theme.state.isDarkMode ? "Light" : "Dark",
                theme.state.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined),
            mainMenuItem(
                context, AppMenuOption.account, "Account", Icons.person),
            mainMenuItem(context, AppMenuOption.logout, "LogOut", Icons.logout),
          ],
          onClickMenu: onClickMenu,
          onDismiss: onDismiss);
      menu.show(widgetKey: btnKey);
    }

    return AppBar(
      title: const Text("Mobi Sync Client"),
      actions: [
        IconButton(
            key: btnKey,
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Show menu',
            onPressed: () => getMenu(context)),
        IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('System notifications list is empty.')));
            }),
      ],
    );
  }

  static Future<void> logOut(
      BuildContext context, DeviceServicesCubit deviceService) async {
    await deviceService.logOut();
    // ignore: use_build_context_synchronously
    if (context.canPop()) {
      context.pop();
    }
    context.push('/login');
  }
}
