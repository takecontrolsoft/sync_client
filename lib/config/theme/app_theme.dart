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
import 'package:sync_client/config/theme/theme_cubit.dart';

const seedColor = Color.fromARGB(255, 7, 80, 59);

class AppTheme {
  static ThemeData getTheme(BuildContext context) {
    final theme = context.watch<ThemeCubit>();
    return ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: theme.state.isDarkMode ? Brightness.dark : Brightness.light,
        listTileTheme: const ListTileThemeData(
          iconColor: seedColor,
        ));
  }
}
