import 'package:flutter/material.dart';
import 'package:sync_client/config/theme/app_bar.dart';

class GalleryAppBar {
  static AppBar appBar(
    BuildContext context, {
    required int crossAxisCount,
    required bool isGridView,
    required void Function(int) onGridSizeChanged,
    required VoidCallback onViewModeToggle,
    VoidCallback? onSelectPressed,
    VoidCallback? onMoveDocumentsToTrashPressed,
  }) {
    final baseAppBar = MainAppBar.appBar(context);

    final List<Widget> galleryActions = [
      if (onMoveDocumentsToTrashPressed != null)
        IconButton(
          icon: const Icon(Icons.description),
          onPressed: onMoveDocumentsToTrashPressed,
          tooltip: 'Move documents to Trash',
        ),
      if (onSelectPressed != null)
        IconButton(
          icon: const Icon(Icons.checklist_rtl),
          onPressed: onSelectPressed,
          tooltip: 'Select',
        ),
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
      IconButton(
        icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
        onPressed: onViewModeToggle,
        tooltip: isGridView ? 'List view' : 'Grid view',
      ),
      if (baseAppBar.actions != null) ...baseAppBar.actions!,
    ];

    return AppBar(
      title: baseAppBar.title,
      leading: baseAppBar.leading,
      leadingWidth: baseAppBar.leadingWidth,
      actions: galleryActions,
      backgroundColor: baseAppBar.backgroundColor,
      foregroundColor: baseAppBar.foregroundColor,
      elevation: baseAppBar.elevation,
      scrolledUnderElevation: baseAppBar.scrolledUnderElevation,
      surfaceTintColor: baseAppBar.surfaceTintColor,
      iconTheme: baseAppBar.iconTheme,
      actionsIconTheme: baseAppBar.actionsIconTheme,
      centerTitle: baseAppBar.centerTitle,
      flexibleSpace: baseAppBar.flexibleSpace,
    );
  }
}
