/*
	Copyright 2023 Take Control - Software & Infrastructure

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sync_client/config/theme/app_bar.dart';

/// Shell that shows bottom navigation (Home, Trash, Sync, Account) and menu (theme, log out) on the right.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey _menuButtonKey = GlobalKey();

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.delete_outline_rounded, label: 'Trash'),
    _NavItem(icon: Icons.sync_rounded, label: 'Sync'),
    _NavItem(icon: Icons.person_rounded, label: 'Account'),
  ];

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navTheme = theme.navigationBarTheme;

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: navTheme.height ?? 64,
              decoration: BoxDecoration(
                color: navTheme.backgroundColor ?? colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_items.length, (index) {
                        final item = _items[index];
                        final selected = index == widget.navigationShell.currentIndex;
                        return Expanded(
                          child: InkWell(
                            onTap: () => _onTap(index),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 24,
                                  color: selected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                    fontWeight:
                                        selected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  IconButton(
                    key: _menuButtonKey,
                    icon: const Icon(Icons.more_vert_rounded),
                    tooltip: 'Menu',
                    onPressed: () => MainAppBar.showAppMenu(context, _menuButtonKey),
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
            _BottomBrandStrip(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Thin strip at the very bottom: app icon, name, and link to mobisync.eu.
class _BottomBrandStrip extends StatelessWidget {
  const _BottomBrandStrip({required this.colorScheme});

  final ColorScheme colorScheme;

  static const _mobisyncUrl = 'https://mobisync.eu';

  Future<void> _openMobisync() async {
    final uri = Uri.parse(_mobisyncUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surface,
      child: SizedBox(
        height: 32,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/mobi-sync.png',
                height: 20,
                width: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.cloud_sync_rounded,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'SpaceIt Mobi Sync',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: _openMobisync,
                child: Text(
                  'mobisync.eu',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
