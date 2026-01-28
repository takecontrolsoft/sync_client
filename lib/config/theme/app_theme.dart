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
import 'package:popup_menu/popup_menu.dart';

import '../config.dart';

// Primary: orange. Secondary / surfaces: dark brown.
const Color _orange = Color(0xFFE85D04);
const Color _orangeLight = Color(0xFFFF8534);
const Color _darkBrown = Color(0xFF3D2914);
const Color _darkBrownLight = Color(0xFF5C3D1E);

const seedColor = _orange;

class AppTheme {
  static ThemeData getTheme(BuildContext context) {
    final theme = context.watch<ThemeCubit>();
    return themeData(context, theme);
  }

  static ThemeData themeData(BuildContext context, ThemeCubit theme) {
    final isDark = theme.state.isDarkMode;
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: _orangeLight,
            onPrimary: Colors.white,
            secondary: _darkBrownLight,
            onSecondary: Colors.white,
            surface: const Color(0xFF1A1209),
            onSurface: Colors.white,
            surfaceContainerHighest: _darkBrown,
          )
        : ColorScheme.light(
            primary: _orange,
            onPrimary: Colors.white,
            secondary: _darkBrown,
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: _darkBrown,
            surfaceContainerHighest: const Color(0xFFF5E6D3),
          );

    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        return colorScheme.primary;
      }),
      foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevation: WidgetStateProperty.resolveWith((_) => 0),
    );

    final outlinedStyle = ButtonStyle(
      foregroundColor: WidgetStateProperty.all(colorScheme.primary),
      side: WidgetStateProperty.all(
        BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: isDark ? Brightness.dark : Brightness.light,
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.28),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          );
        }),
        height: 64,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedStyle),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.all(colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

// Folder List Screen Styles
class FolderListStyles {
  // Container margins
  static const EdgeInsets containerMargin = EdgeInsets.all(20);

  // Empty state styles
  static const double emptyStateIconSize = 80;
  static const double emptyStateSpacing = 20;

  // Card styles
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 4);
  static const BorderRadius cardBorderRadius =
      BorderRadius.all(Radius.circular(8));

  // Loading dialog styles
  static const EdgeInsets loadingDialogPadding = EdgeInsets.all(20);

  // Info box styles
  static BoxDecoration infoContainerDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.primaryColor.withOpacity(0.3),
      ),
    );
  }

  // Folder icon container
  static BoxDecoration folderIconDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.primaryColor.withOpacity(0.1),
      shape: BoxShape.circle,
    );
  }

  // Text styles for folder list
  static TextStyle titleTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!;
  }

  static TextStyle subtitleTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Colors.grey[600],
        );
  }

  static TextStyle emptyStateTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          color: Colors.grey[600],
        );
  }

  static TextStyle emptyStateSubtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Colors.grey[500],
        );
  }

  static TextStyle helperTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      color: Colors.grey[500],
      fontStyle: FontStyle.italic,
    );
  }

  static TextStyle folderPathStyle() {
    return const TextStyle(fontSize: 12);
  }

  static TextStyle folderNameStyle() {
    return const TextStyle(fontWeight: FontWeight.w500);
  }

  // Colors
  static Color emptyStateIconColor = Colors.grey[300]!;

  // Platform-specific help text
  static String getPlatformHelpText() {
    if (Platform.isAndroid) {
      return 'You\'ll select a folder and grant access.\nNo special permissions required!';
    } else if (Platform.isIOS) {
      return 'Select folders from Files app.\nPhotos sync is handled separately.';
    } else if (Platform.isMacOS) {
      return 'Select any folder on your Mac.\nThe app only accesses folders you choose.';
    } else if (Platform.isWindows) {
      return 'Select any folder on your PC.\nWorks with all Windows folders.';
    } else {
      return 'Select any folder on your system.\nThe app only accesses folders you choose.';
    }
  }
}

// Dialog styles
class DialogStyles {
  static const EdgeInsets contentPadding = EdgeInsets.all(16);
  static const double contentSpacing = 16;
  static const double optionVerticalPadding = 8.0;
  static const double optionIconSize = 32;
  static const double optionSpacing = 16;

  static TextStyle optionTitleStyle() {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle optionSubtitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      color: Colors.grey[600],
    );
  }

  static TextStyle errorDialogContentStyle() {
    return const TextStyle(fontSize: 12, fontStyle: FontStyle.italic);
  }
}

// Snackbar styles
class SnackbarStyles {
  static SnackBar successSnackbar({
    required String message,
    VoidCallback? onAction,
    String actionLabel = 'Undo',
  }) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      action: onAction != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
            )
          : null,
    );
  }

  static SnackBar warningSnackbar({required String message}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.orange,
    );
  }

  static SnackBar errorSnackbar({required String message}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
  }

  static SnackBar infoSnackbar({
    required String message,
    VoidCallback? onAction,
    String actionLabel = 'Retry',
  }) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.orange,
      action: onAction != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
            )
          : null,
    );
  }
}

class GalleryStyles {
  // Container styles
  static const EdgeInsets galleryPadding = EdgeInsets.all(4);
  static const double photoSpacing = 4;
  static const double borderRadius = 4;

  // Photo tile styles
  static BoxDecoration photoTileDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? Colors.grey[800] : Colors.grey[300],
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  static BoxDecoration loadingPhotoDecoration(BuildContext context) {
    return photoTileDecoration(context);
  }

  // Month header styles
  static BoxDecoration monthHeaderDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.scaffoldBackgroundColor.withOpacity(0.95),
      border: Border(
        bottom: BorderSide(
          color: theme.dividerColor.withOpacity(0.2),
          width: 0.5,
        ),
      ),
    );
  }

  static TextStyle monthHeaderTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        );
  }

  static const EdgeInsets monthHeaderPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  // Empty state styles
  static const double emptyStateIconSize = 80;
  static Color emptyStateIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[600]!
        : Colors.grey[400]!;
  }

  static TextStyle emptyStateTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
        );
  }

  static TextStyle emptyStateSubtitleStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        );
  }

  // Loading state styles
  static const double loadingIndicatorSize = 20;
  static const double loadingIndicatorStrokeWidth = 2;

  static Color loadingIndicatorColor(BuildContext context) {
    return Theme.of(context).primaryColor;
  }

  // Error widget styles
  static const double errorIconSize = 30;

  static Color errorIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[600]! : Colors.grey[500]!;
  }

  // List view styles
  static const double listTileThumbnailSize = 60;
  static const EdgeInsets listTilePadding =
      EdgeInsets.symmetric(horizontal: 16);

  static TextStyle listTileSubtitleStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? Colors.grey[400] : Colors.grey[600],
      fontSize: 14,
    );
  }

  // Floating action button styles
  static const double fabSpacing = 10;

  // Photo viewer overlay gradient
  static const List<Color> overlayGradientColors = [
    Colors.black54,
    Colors.transparent,
    Colors.transparent,
    Colors.black54,
  ];

  static const List<double> overlayGradientStops = [0, 0.2, 0.8, 1];

  static BoxDecoration videoPlayButtonDecoration() {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.7),
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(0.8),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static const double videoPlayButtonSize = 48;
  static const double videoPlayIconSize = 32;

  static BoxDecoration videoBadgeDecoration() {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.7),
      borderRadius: BorderRadius.circular(4),
    );
  }

  static const EdgeInsets videoBadgePadding =
      EdgeInsets.symmetric(horizontal: 6, vertical: 2);

  static const TextStyle videoBadgeTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}

// Photo Viewer Styles
class PhotoViewerStyles {
  // Photo viewer overlay gradient
  static const List<Color> overlayGradientColors = [
    Colors.black54,
    Colors.transparent,
    Colors.transparent,
    Colors.black54,
  ];

  static const List<double> overlayGradientStops = [0, 0.2, 0.8, 1];

  // Navigation arrow styles
  static BoxDecoration navigationArrowDecoration() {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.5),
      shape: BoxShape.circle,
    );
  }

  static const double navigationArrowSize = 32;
  static const EdgeInsets navigationArrowPadding = EdgeInsets.all(16);

  // Top bar styles
  static const EdgeInsets topBarPadding = EdgeInsets.all(8);

  static TextStyle pageIndicatorStyle() {
    return const TextStyle(
      color: Colors.white,
      fontSize: 16,
    );
  }

  // Quality indicator styles
  static BoxDecoration qualityIndicatorDecoration() {
    return BoxDecoration(
      color: Colors.green.withOpacity(0.8),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static const EdgeInsets qualityIndicatorPadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  static const TextStyle qualityIndicatorTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  // Bottom info styles
  static const EdgeInsets bottomInfoPadding = EdgeInsets.all(16);

  static const TextStyle photoTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static TextStyle photoSubtitleStyle() {
    return TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 14,
    );
  }

  // Loading state
  static const TextStyle loadingTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
  );

  // Page dots indicator
  static const double pageDotSize = 8;
  static const EdgeInsets pageDotSpacing = EdgeInsets.symmetric(horizontal: 2);

  static Color activeDotColor = Colors.white;
  static Color inactiveDotColor = Colors.white.withValues(alpha: 0.4);

  // Info sheet styles
  static BoxDecoration infoSheetDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? Colors.grey[900] : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    );
  }

  static const EdgeInsets infoSheetPadding = EdgeInsets.all(16);

  static const TextStyle infoSheetTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const double infoRowLabelWidth = 80;

  static TextStyle infoRowLabelStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.grey[400] : Colors.grey[600],
      fontSize: 14,
    );
  }
}

// Common animation durations
class GalleryAnimations {
  static const Duration overlayFade = Duration(milliseconds: 200);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration scrollToTop = Duration(milliseconds: 500);
  static const Curve defaultCurve = Curves.easeInOut;
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

TextStyle successTextStyle(BuildContext context, {bool bold = false}) {
  return TextStyle(
      color: Colors.green,
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
  0xFFE85D04,
  const <int, Color>{
    50: Color(0x1AE85D04),
    100: Color(0x33E85D04),
    200: Color(0x4DE85D04),
    300: Color(0x66E85D04),
    400: Color(0x80E85D04),
    500: Color(0x99E85D04),
    600: Color(0xB3E85D04),
    700: Color(0xCCE85D04),
    800: Color(0xE6E85D04),
    900: Color(0xFFE85D04),
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
