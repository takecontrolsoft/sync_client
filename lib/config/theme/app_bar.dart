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
import 'package:popup_menu/popup_menu.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/services/device_services.dart';

enum AppMenuOption { home, trash, sync, theme, account, logout }

const Color _headerOrange = Color(0xFFE85D04);

class MainAppBar {
  /// [actionsBeforeMenu] are shown in the AppBar before the menu (e.g. refresh on Trash).
  static AppBar appBar(BuildContext context,
      {List<Widget>? actionsBeforeMenu}) {
    final ThemeCubit theme = context.watch<ThemeCubit>();
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    GlobalKey btnKey = GlobalKey();

    void onClickMenu(MenuItemProvider item) async {
      print('Click menu -> ${item.menuTitle}');
      final option = item.menuUserInfo as AppMenuOption;
      switch (option) {
        case AppMenuOption.home:
          context.go("/");
        case AppMenuOption.trash:
          context.go("/trash");
        case AppMenuOption.sync:
          context.go("/sync");
        case AppMenuOption.theme:
          theme.toggleTheme();
        case AppMenuOption.account:
          context.go("/account");
        case AppMenuOption.logout:
          await logOut(context, deviceService);
      }
    }

    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Image.asset(
          'images/mobi-sync.png',
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.cloud_sync_rounded,
            color: colorScheme.onSurface,
            size: 28,
          ),
        ),
      ),
      leadingWidth: 48,
      title: const SizedBox.shrink(),
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 8,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      actions: actionsBeforeMenu != null ? [...actionsBeforeMenu] : null,
    );
  }

  /// AppBar for sub-screens (e.g. Servers, Folders) with Back and optional "Done" to return to Sync.
  static AppBar appBarWithBack(
    BuildContext context, {
    required String title,
    bool showDoneButton = true,
  }) {
    final actions = <Widget>[];
    if (showDoneButton) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () => context.go("/sync"),
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text("Done"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go("/sync");
          }
        },
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      backgroundColor: _headerOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.95)),
      actionsIconTheme:
          IconThemeData(color: Colors.white.withValues(alpha: 0.95)),
      actions: actions,
    );
  }

  /// Shows the app menu (theme, account, log out). Call from bottom bar or elsewhere.
  /// [menuButtonKey] should be the GlobalKey of the button that opens the menu (for positioning).
  static void showAppMenu(BuildContext context, GlobalKey menuButtonKey) {
    final ThemeCubit theme = context.read<ThemeCubit>();
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();

    void onClickMenu(MenuItemProvider item) async {
      final option = item.menuUserInfo as AppMenuOption;
      switch (option) {
        case AppMenuOption.home:
          context.go("/");
        case AppMenuOption.trash:
          context.go("/trash");
        case AppMenuOption.sync:
          context.go("/sync");
        case AppMenuOption.theme:
          theme.toggleTheme();
        case AppMenuOption.account:
          context.go("/account");
        case AppMenuOption.logout:
          await logOut(context, deviceService);
      }
    }

    final PopupMenu menu = PopupMenu(
      context: context,
      config: MenuConfig(
        maxColumn: 2,
        backgroundColor: theme.state.isDarkMode ? Colors.white : Colors.black,
        lineColor: Theme.of(context).listTileTheme.iconColor!,
      ),
      items: [
        mainMenuItem(
            context,
            AppMenuOption.theme,
            theme.state.isDarkMode ? "Light" : "Dark",
            theme.state.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
        mainMenuItem(context, AppMenuOption.account, "Account", Icons.person),
        mainMenuItem(context, AppMenuOption.logout, "Log out", Icons.logout),
      ],
      onClickMenu: onClickMenu,
    );
    menu.show(widgetKey: menuButtonKey);
  }

  static Future<void> logOut(
      BuildContext context, DeviceServicesCubit deviceService) async {
    await deviceService.logOut();
    // ignore: use_build_context_synchronously
    if (context.canPop()) {
      // ignore: use_build_context_synchronously
      context.pop();
    }
    // ignore: use_build_context_synchronously
    context.push('/login');
  }
}
