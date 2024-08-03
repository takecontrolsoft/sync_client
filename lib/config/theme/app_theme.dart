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
import 'package:popup_menu/popup_menu.dart';

import '../config.dart';

const seedColor = Color.fromARGB(255, 246, 113, 31);

class AppTheme {
  static ThemeData getTheme(BuildContext context) {
    final theme = context.watch<ThemeCubit>();
    return themeData(context, theme);
  }

  static ThemeData themeData(BuildContext context, ThemeCubit theme) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      brightness: theme.state.isDarkMode ? Brightness.dark : Brightness.light,
      listTileTheme: const ListTileThemeData(
        iconColor: seedColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.all(objectColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          textStyle: WidgetStateProperty.all<TextStyle>(
              const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

BoxDecoration headerFooterBoxDecoration(BuildContext context, bool isHeader) {
  final theme = Theme.of(context);
  return BoxDecoration(
    color: theme.colorScheme.surface,
    border: Border(
        top: isHeader
            ? BorderSide.none
            : BorderSide(width: 2, color: theme.primaryColor),
        bottom: isHeader
            ? BorderSide(width: 2, color: theme.primaryColor)
            : BorderSide.none),
  );
}

BoxDecoration errorBoxDecoration(BuildContext context) {
  final theme = Theme.of(context);
  return BoxDecoration(
      border: Border.all(color: Colors.black),
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(8)));
}

BoxDecoration infoBoxDecoration(BuildContext context) {
  final theme = Theme.of(context);
  return BoxDecoration(
      border: Border.all(color: Colors.black),
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(8)));
}

TextStyle errorTextStyle(BuildContext context, {bool bold = false}) {
  final theme = Theme.of(context);
  return TextStyle(
      color: theme.colorScheme.error,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal);
}

TextStyle infoTextStyle(BuildContext context, {bool bold = false}) {
  return TextStyle(
      color: Colors.black,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal);
}

TextStyle boldTextStyle() {
  return const TextStyle(color: Colors.black, fontWeight: FontWeight.bold);
}

TextStyle importantTextStyle(BuildContext context) {
  return TextStyle(
      color: objectColor, fontWeight: FontWeight.bold, fontSize: 12);
}

MenuItem mainMenuItem(BuildContext context, AppMenuOption menuOption,
    String title, IconData icon) {
  final themeCubit = context.read<ThemeCubit>();
  final theme = Theme.of(context);

  return MenuItem(
      title: title,
      userInfo: menuOption,
      image: Icon(icon, color: theme.listTileTheme.iconColor),
      textStyle: TextStyle(
        color: themeCubit.state.isDarkMode ? Colors.black : Colors.white,
      ));
}

MaterialColor objectColor = MaterialColor(
  const Color.fromRGBO(246, 113, 31, 1).value,
  const <int, Color>{
    50: Color.fromRGBO(246, 113, 31, 0.1),
    100: Color.fromRGBO(246, 113, 31, 0.2),
    200: Color.fromRGBO(246, 113, 31, 0.3),
    300: Color.fromRGBO(246, 113, 31, 0.4),
    400: Color.fromRGBO(246, 113, 31, 0.5),
    500: Color.fromRGBO(246, 113, 31, 0.6),
    600: Color.fromRGBO(246, 113, 31, 0.7),
    700: Color.fromRGBO(246, 113, 31, 0.8),
    800: Color.fromRGBO(246, 113, 31, 0.9),
    900: Color.fromRGBO(246, 113, 31, 1),
  },
);

MaterialColor mistColor = MaterialColor(
  const Color.fromRGBO(227, 252, 247, 1).value,
  const <int, Color>{
    50: Color.fromRGBO(227, 252, 247, 0.1),
    100: Color.fromRGBO(227, 252, 247, 0.2),
    200: Color.fromRGBO(227, 252, 247, 0.3),
    300: Color.fromRGBO(227, 252, 247, 0.4),
    400: Color.fromRGBO(227, 252, 247, 0.5),
    500: Color.fromRGBO(227, 252, 247, 0.6),
    600: Color.fromRGBO(227, 252, 247, 0.7),
    700: Color.fromRGBO(227, 252, 247, 0.8),
    800: Color.fromRGBO(227, 252, 247, 0.9),
    900: Color.fromRGBO(227, 252, 247, 1),
  },
);

Color get darkRedColor => const Color.fromARGB(255, 208, 18, 5);
Color get lightRedColor => const Color.fromARGB(255, 244, 223, 221);
