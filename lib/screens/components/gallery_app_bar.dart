// lib/screens/components/gallery_app_bar.dart

import 'package:flutter/material.dart';
import 'package:sync_client/config/theme/app_bar.dart';

class GalleryAppBar {
  static AppBar appBar(
    BuildContext context, {
    required int crossAxisCount,
    required bool isGridView,
    required Function(int) onGridSizeChanged,
    required VoidCallback onViewModeToggle,
  }) {
    // Get the base app bar
    final baseAppBar = MainAppBar.appBar(context);

    // Add gallery-specific actions to the existing actions
    final List<Widget> galleryActions = [
      // Grid size selector
      PopupMenuButton<int>(
        icon: const Icon(Icons.grid_view),
        onSelected: onGridSizeChanged,
        itemBuilder: (context) => [
          const PopupMenuItem(value: 2, child: Text('2 columns')),
          const PopupMenuItem(value: 3, child: Text('3 columns')),
          const PopupMenuItem(value: 4, child: Text('4 columns')),
          const PopupMenuItem(value: 5, child: Text('5 columns')),
        ],
      ),
      // View mode toggle
      IconButton(
        icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
        onPressed: onViewModeToggle,
        tooltip: isGridView ? 'List view' : 'Grid view',
      ),
      // Keep existing actions if any
      if (baseAppBar.actions != null) ...baseAppBar.actions!,
    ];

    return AppBar(
      title: baseAppBar.title,
      leading: baseAppBar.leading,
      actions: galleryActions,
      backgroundColor: baseAppBar.backgroundColor,
      foregroundColor: baseAppBar.foregroundColor,
      elevation: baseAppBar.elevation,
      centerTitle: baseAppBar.centerTitle,
    );
  }
}
