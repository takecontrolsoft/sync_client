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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/config/theme/app_theme.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/models/photo_item.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/screens/components/gallery_app_bar.dart';
import 'package:sync_client/services/services.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<PhotoItem> _trashPhotos = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _wasRouteCurrent = false;
  bool _selectionMode = false;
  final Set<String> _selectedPaths = {};

  static const String _trashFolder = 'Trash';

  Future<void> _loadTrashFiles() async {
    final deviceService = context.read<DeviceServicesCubit>();
    if (!deviceService.isAuthenticated()) {
      if (mounted) context.push("/login");
      return;
    }
    final user = deviceService.state.currentUser?.email;
    final deviceId = deviceService.state.id;
    if (user == null || user.isEmpty || deviceId.isEmpty) return;
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
          .map((f) => PhotoItem.fromPath(f, _trashFolder))
          .toList();
      setState(() {
        _trashPhotos = photos;
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            video: photo,
            photos: photos,
            initialIndex: initialIndex,
            isFromTrash: true,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
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
    final deviceId = deviceService.state.id;
    if (user == null || user.isEmpty || deviceId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not signed in')),
        );
      }
      return;
    }
    final paths = _selectedPaths.toList();
    try {
      final ok = await apiRestoreFromTrash(user, deviceId, paths);
      if (!mounted) return;
      if (ok) {
        await CacheService.clearCache();
        if (!mounted) return;
        context.read<GalleryRefreshCubit>().requestHomeRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${paths.length} item(s) restored to Home')),
        );
        setState(() {
          _selectionMode = false;
          _selectedPaths.clear();
        });
        _loadTrashFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore from Trash')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  AppBar _buildSelectionAppBar() {
    final n = _selectedPaths.length;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
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
            icon: const Icon(Icons.restore_from_trash),
            label: const Text('Restore from Trash'),
            onPressed: _restoreSelected,
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
                FloatingActionButton(
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
                              style: Theme.of(context).textTheme.headlineSmall,
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
                    : ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          if (_isLoading)
                            const LinearProgressIndicator(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              '${_trashPhotos.length} item(s)',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing:
                                  GalleryStyles.photoSpacing,
                              crossAxisSpacing:
                                  GalleryStyles.photoSpacing,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: _trashPhotos.length,
                            itemBuilder: (context, index) {
                              final photo = _trashPhotos[index];
                              return GalleryPhotoTile(
                                photo: photo,
                                onTap: _selectionMode
                                    ? () => _toggleSelection(photo)
                                    : () => _openPhotoViewer(
                                        context, _trashPhotos, index),
                                isSelectionMode: _selectionMode,
                                isSelected: _selectedPaths.contains(photo.path),
                              );
                            },
                          ),
                        ],
                      ),
        ),
      ),
    );
  }
}
