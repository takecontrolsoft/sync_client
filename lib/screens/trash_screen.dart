/*
	Copyright 2024 Take Control - Software & Infrastructure

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

import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/config/theme/app_theme.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/models/photo_item.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<PhotoItem> _trashPhotos = [];
  Map<String, List<PhotoItem>> _trashPhotosByMonth = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _wasRouteCurrent = false;
  bool _selectionMode = false;
  bool _isRestoring = false;
  final Set<String> _selectedPaths = {}; // Stores photo.path (e.g. "Trash/2024/01/photo.jpg")
  final Set<String> _collapsedMonths = {};

  static const String _trashFolder = 'Trash';

  void _groupTrashByMonth() {
    _trashPhotosByMonth.clear();
    for (final photo in _trashPhotos) {
      final month = photo.month ?? 'Recent';
      _trashPhotosByMonth[month] ??= [];
      _trashPhotosByMonth[month]!.add(photo);
    }
    for (final photos in _trashPhotosByMonth.values) {
      photos.sort((a, b) =>
          (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));
    }
  }

  List<PhotoItem> _getTrashPhotosInOrder() {
    final sortedMonths = _trashPhotosByMonth.keys.toList();
    sortedMonths.sort((a, b) {
      // Newest month first; "Recent" (unknown date) last
      if (a == 'Recent') return 1;
      if (b == 'Recent') return -1;
      try {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA);
      } catch (e) {
        return b.compareTo(a);
      }
    });
    final list = <PhotoItem>[];
    for (final month in sortedMonths) {
      list.addAll(_trashPhotosByMonth[month] ?? []);
    }
    return list;
  }

  Future<void> _loadTrashFiles() async {
    final deviceService = context.read<DeviceServicesCubit>();
    if (!deviceService.isAuthenticated()) {
      if (mounted) context.push("/login");
      return;
    }
    final user = deviceService.state.currentUser?.email;
    final showAll = deviceService.state.showAllDevices;
    // In all-devices mode, use empty deviceId to get files from all devices
    final deviceId = showAll ? '' : deviceService.state.id;
    if (user == null || user.isEmpty) return;
    if (!showAll && deviceId.isEmpty) return;
    if ((deviceService.state.serverUrl ?? "").isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await apiGetFiles(user, deviceId, _trashFolder);
      if (!mounted) return;
      final photos = files
          .where((f) => !f.toLowerCase().contains('.converted.jpg'))
          .map((f) {
        if (showAll) {
          // "device1/Trash/2024/01/photo.jpg" -> deviceId="device1", path="Trash/2024/01/photo.jpg"
          final parsed = PhotoItem.parseDeviceIdPath(f);
          final devId = parsed[0];
          final path = parsed[1]!;
          return PhotoItem.fromPath(path, _trashFolder, deviceIdOverride: devId);
        }
        return PhotoItem.fromPath(f, _trashFolder);
      }).toList();
      setState(() {
        _trashPhotos = photos;
        _groupTrashByMonth();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is CustomError ? e.message : e.toString();
        });
      }
    }
  }

  void _openPhotoViewer(
      BuildContext context, List<PhotoItem> photos, int initialIndex) {
    final photo = photos[initialIndex];
    if (photo.isVideo) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => VideoPlayerScreen(
            video: photo,
            photos: photos,
            initialIndex: initialIndex,
            isFromTrash: true,
          ),
        ),
      );
    } else {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => PhotoViewerScreen(
            photos: photos,
            initialIndex: initialIndex,
            isFromTrash: true,
          ),
        ),
      );
    }
  }

  void _toggleSelection(PhotoItem photo) {
    setState(() {
      if (_selectedPaths.contains(photo.path)) {
        _selectedPaths.remove(photo.path);
      } else {
        _selectedPaths.add(photo.path);
      }
    });
  }

  Future<void> _restoreSelected() async {
    if (_selectedPaths.isEmpty) return;
    final deviceService = context.read<DeviceServicesCubit>();
    final user = deviceService.state.currentUser?.email;
    final showAll = deviceService.state.showAllDevices;
    final defaultDeviceId = deviceService.state.id;

    if (user == null || user.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not signed in')),
        );
      }
      return;
    }
    if (!showAll && defaultDeviceId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No device selected')),
        );
      }
      return;
    }

    setState(() => _isRestoring = true);

    try {
      bool allOk = true;
      int totalRestored = 0;

      if (showAll) {
        // In all-devices mode, group photos by deviceIdOverride and restore per device
        final Map<String, List<String>> photosByDevice = {};
        for (final path in _selectedPaths) {
          // Find the PhotoItem to get its deviceIdOverride
          final photo = _trashPhotos.firstWhere(
            (p) => p.path == path,
            orElse: () => PhotoItem(path: path, folder: _trashFolder, isVideo: false),
          );
          final devId = photo.deviceIdOverride ?? '';
          if (devId.isEmpty) continue; // Skip if no device ID
          photosByDevice.putIfAbsent(devId, () => []).add(path);
        }

        for (final entry in photosByDevice.entries) {
          final devId = entry.key;
          final paths = entry.value;
          final ok = await apiRestoreFromTrash(user, devId, paths)
              .timeout(const Duration(seconds: 60));
          if (ok) {
            totalRestored += paths.length;
          } else {
            allOk = false;
          }
        }
      } else {
        // Single device mode - restore all selected paths to current device
        final paths = _selectedPaths.toList();
        final ok = await apiRestoreFromTrash(user, defaultDeviceId, paths)
            .timeout(const Duration(seconds: 60));
        if (ok) {
          totalRestored = paths.length;
        } else {
          allOk = false;
        }
      }

      if (!mounted) return;

      if (totalRestored > 0) {
        context.read<GalleryRefreshCubit>().requestHomeRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$totalRestored item(s) restored to Home')),
        );
        setState(() {
          _selectionMode = false;
          _selectedPaths.clear();
          _isRestoring = false;
        });
        _loadTrashFiles();
        unawaited(CacheService.clearCache());
      } else if (!allOk) {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore from Trash')),
        );
      } else {
        setState(() => _isRestoring = false);
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Restore timed out. Check the server and try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildTrashList() {
    final sortedMonths = _trashPhotosByMonth.keys.toList();
    sortedMonths.sort((a, b) {
      // Newest month first; "Recent" last
      if (a == 'Recent') return 1;
      if (b == 'Recent') return -1;
      try {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA);
      } catch (e) {
        return b.compareTo(a);
      }
    });
    final photosInOrder = _getTrashPhotosInOrder();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedMonths.length * 2 + 1,
      itemBuilder: (context, index) {
        if (index == 0 && _isLoading) {
          return const LinearProgressIndicator();
        }
        final adjustedIndex = _isLoading ? index - 1 : index;
        final monthIndex = adjustedIndex ~/ 2;
        final isHeader = adjustedIndex % 2 == 0;

        if (monthIndex >= sortedMonths.length) {
          return const SizedBox.shrink();
        }

        final month = sortedMonths[monthIndex];
        final photos = _trashPhotosByMonth[month] ?? [];

        if (isHeader) {
          final isCollapsed = _collapsedMonths.contains(month);
          return Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isCollapsed) {
                    _collapsedMonths.remove(month);
                  } else {
                    _collapsedMonths.add(month);
                  }
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isCollapsed ? Icons.chevron_right : Icons.expand_more,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        month,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Text(
                      '${photos.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_collapsedMonths.contains(month)) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: GalleryStyles.galleryPadding,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: GalleryStyles.photoSpacing,
              crossAxisSpacing: GalleryStyles.photoSpacing,
              childAspectRatio: 1.0,
            ),
            itemCount: photos.length,
            itemBuilder: (context, gridIndex) {
              final photo = photos[gridIndex];
              final globalIndex = photosInOrder.indexOf(photo);
              return GalleryPhotoTile(
                photo: photo,
                onTap: _selectionMode
                    ? () => _toggleSelection(photo)
                    : () =>
                        _openPhotoViewer(context, photosInOrder, globalIndex),
                isSelectionMode: _selectionMode,
                isSelected: _selectedPaths.contains(photo.path),
              );
            },
          ),
        );
      },
    );
  }

  AppBar _buildSelectionAppBar() {
    final n = _selectedPaths.length;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _isRestoring
            ? null
            : () {
                setState(() {
                  _selectionMode = false;
                  _selectedPaths.clear();
                });
              },
        tooltip: 'Cancel',
      ),
      title: Text(n == 0 ? 'Select items' : '$n selected'),
      actions: [
        if (n > 0)
          TextButton.icon(
            icon: _isRestoring
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restore_from_trash),
            label: Text(_isRestoring ? 'Restoring…' : 'Restore from Trash'),
            onPressed: _isRestoring ? null : _restoreSelected,
          ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrent && !_wasRouteCurrent) {
      _loadTrashFiles();
    }
    _wasRouteCurrent = isCurrent;
  }

  @override
  Widget build(BuildContext context) {
    final deviceService = context.read<DeviceServicesCubit>();
    if (!deviceService.isAuthenticated()) {
      return Scaffold(
        appBar: MainAppBar.appBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocListener<GalleryRefreshCubit, GalleryRefreshState>(
      listener: (context, state) {
        if (state.trashNeedsRefresh && mounted) {
          context.read<GalleryRefreshCubit>().clearTrashRefresh();
          _loadTrashFiles();
        }
      },
      child: Scaffold(
        appBar: _selectionMode
            ? _buildSelectionAppBar()
            : MainAppBar.appBar(
                context,
                actionsBeforeMenu: _trashPhotos.isEmpty
                    ? null
                    : [
                        IconButton(
                          icon: const Icon(Icons.checklist_rtl),
                          onPressed: () {
                            setState(() {
                              _selectionMode = true;
                              _selectedPaths.clear();
                            });
                          },
                          tooltip: 'Select',
                        ),
                      ],
              ),
        floatingActionButton: _selectionMode
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'trash_refresh',
                    onPressed: _isLoading ? null : _loadTrashFiles,
                    tooltip: 'Refresh',
                    child: _isLoading && _trashPhotos.isNotEmpty
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
        body: RefreshIndicator(
          onRefresh: _loadTrashFiles,
          child: _isLoading && _trashPhotos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTrashFiles,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _trashPhotos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(height: 16),
                              Text(
                                'Trash',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Items moved to Trash will appear here.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _buildTrashList(),
        ),
      ),
    );
  }
}
