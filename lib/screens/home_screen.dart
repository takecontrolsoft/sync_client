// ignore_for_file: must_be_immutable

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
import 'dart:typed_data';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/config/theme/app_theme.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/screens/components/gallery_app_bar.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';
import 'package:sync_client/models/photo_item.dart';

// Photo model and cache service are now in separate files

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // State management
  List<String> _folders = [];
  Map<String, List<PhotoItem>> _photosCache = {};
  Map<String, List<PhotoItem>> _photosByMonth = {};
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _hasError = false;
  String? _errorMessage;
  Timer? _timeoutTimer;

  // UI State
  bool _isGridView = true;
  int _crossAxisCount = 3;
  final ScrollController _scrollController = ScrollController();
  bool _selectionMode = false;
  final Set<String> _selectedPaths = {};
  final Set<String> _collapsedMonths = {};
  bool _wasRouteCurrent = false;
  bool _leftHome = false;

  // Loading configuration
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _initialDelay = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _initializeLoading();
    _setupScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (_wasRouteCurrent && !isCurrent) {
      _leftHome = true;
    }
    if (isCurrent && _leftHome) {
      _leftHome = false;
      if (_folders.isNotEmpty) {
        _refreshInBackground();
      }
    }
    _wasRouteCurrent = isCurrent;
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      // Hide/show FAB based on scroll position
      if (_scrollController.position.pixels > 200) {
        // Could trigger state change here if needed
      }
    });
  }

  Future<void> _initializeLoading() async {
    // Always load folder/file list from server (fast); thumbnails are cached on device
    Future.delayed(_initialDelay, () {
      if (mounted) {
        _loadFolders();
      }
    });
  }

  void _groupPhotosByMonth() {
    _photosByMonth.clear();

    for (final photos in _photosCache.values) {
      for (final photo in photos) {
        final month = photo.month ?? 'Recent';
        _photosByMonth[month] ??= [];
        _photosByMonth[month]!.add(photo);
      }
    }

    // Sort photos within each month by date
    for (final photos in _photosByMonth.values) {
      photos.sort((a, b) =>
          (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));
    }
  }

  Future<void> _loadFolders({bool isRetry = false}) async {
    if (_isLoading) return;

    final deviceService = context.read<DeviceServicesCubit>();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    // Set timeout
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_timeout, () {
      if (mounted && _isLoading) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Loading is taking longer than expected. Please check your connection.';
          _isLoading = false;
        });
      }
    });

    try {
      // Load folders with timeout
      final folders = await getAllFolders(deviceService).timeout(
        _timeout,
        onTimeout: () => throw TimeoutException('Loading folders timed out'),
      );

      if (mounted) {
        setState(() {
          _folders = folders;
          _isLoading = false;
        });

        // Load files for each folder from server
        _loadFilesProgressively(folders, deviceService);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e is CustomError
              ? e.message
              : 'Failed to load folders: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      _timeoutTimer?.cancel();
    }
  }

  Future<void> _loadFilesProgressively(
      List<String> folders, DeviceServicesCubit deviceService) async {
    for (final folder in folders) {
      if (!mounted) break;

      try {
        final files = await getAllFiles(deviceService, folder);
        if (mounted) {
          // Filter out .converted.jpg files and create PhotoItems
          final photos = files
              .where((f) => !f.toLowerCase().contains('.converted.jpg'))
              .map((f) => PhotoItem.fromPath(f, folder))
              .toList();

          setState(() {
            _photosCache[folder] = photos;
          });
          _groupPhotosByMonth();
        }
      } catch (e) {
        debugPrint('Error loading files for $folder: $e');
      }
    }
  }

  Future<void> _refreshInBackground() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    final deviceService = context.read<DeviceServicesCubit>();

    try {
      final folders = await getAllFolders(deviceService);

      if (mounted && !_listEquals(_folders, folders)) {
        setState(() {
          _folders = folders;
        });

        _loadFilesProgressively(folders, deviceService);
      }
    } catch (e) {
      debugPrint('Background refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _folders.clear();
      _photosCache.clear();
      _photosByMonth.clear();
    });
    await _loadFolders(isRetry: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GalleryRefreshCubit, GalleryRefreshState>(
      listener: (context, state) {
        if (state.homeNeedsRefresh && mounted) {
          context.read<GalleryRefreshCubit>().clearHomeRefresh();
          _refreshInBackground();
        }
      },
      child: Scaffold(
        appBar: _selectionMode ? _buildSelectionAppBar() : GalleryAppBar.appBar(
          context,
          crossAxisCount: _crossAxisCount,
          isGridView: _isGridView,
          onGridSizeChanged: (value) {
            setState(() {
              _crossAxisCount = value;
            });
          },
          onViewModeToggle: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
          onMoveDocumentsToTrashPressed: _moveDocumentsToTrash,
          onSelectPressed: () {
            setState(() {
              _selectionMode = true;
              _selectedPaths.clear();
            });
          },
        ),
        body: _buildBody(context),
        floatingActionButton: _selectionMode ? null : _buildFloatingActionButtons(),
      ),
    );
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
            icon: const Icon(Icons.delete_outline),
            label: const Text('Move to Trash'),
            onPressed: _moveSelectedToTrash,
          ),
      ],
    );
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

  /// Asks the server to run document detection on existing files (server uses its own logic, e.g. Python); thumbnails and metadata cleaned, then documents moved to Trash.
  Future<void> _moveDocumentsToTrash() async {
    final deviceService = context.read<DeviceServicesCubit>();
    // Prefer userId when auth is used so the server scans the correct folder (UploadDirectory/userId/deviceId).
    final user = deviceService.state.currentUser?.userId ?? deviceService.state.currentUser?.email;
    final deviceId = deviceService.state.id;
    if (user == null || user.isEmpty || deviceId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not signed in')),
        );
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move documents to Trash'),
        content: const Text(
          'The server will scan folders and detect documents (using its detection logic), clean their thumbnails and metadata, and move them to Trash. You can restore them later from Trash.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Run on server'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detecting documents on server…')),
      );
    }
    try {
      final moved = await apiRunDocumentDetection(user, deviceId);
      if (!mounted) return;
      if (moved < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server did not accept or endpoint not implemented')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                moved == 0
                    ? 'No documents found on the server.'
                    : '$moved document(s) moved to Trash on server.')),
      );
      context.read<GalleryRefreshCubit>().requestHomeRefresh();
      context.read<GalleryRefreshCubit>().requestTrashRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _moveSelectedToTrash() async {
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
      final ok = await apiMoveToTrash(user, deviceId, paths);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${paths.length} item(s) moved to Trash')),
        );
        setState(() {
          _selectionMode = false;
          _selectedPaths.clear();
          _removePhotosFromCache(paths);
        });
        context.read<GalleryRefreshCubit>().requestTrashRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to move to Trash')),
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

  void _removePhotosFromCache(List<String> paths) {
    final pathSet = paths.toSet();
    for (final month in _photosByMonth.keys.toList()) {
      final photos = _photosByMonth[month]!;
      photos.removeWhere((p) => pathSet.contains(p.path));
      if (photos.isEmpty) {
        _photosByMonth.remove(month);
      }
    }
    for (final folder in _photosCache.keys.toList()) {
      final photos = _photosCache[folder]!;
      photos.removeWhere((p) => pathSet.contains(p.path));
      if (photos.isEmpty) {
        _photosCache.remove(folder);
      } else {
        _photosCache[folder] = photos;
      }
    }
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_scrollController.hasClients && _scrollController.offset > 200)
          FloatingActionButton.small(
            heroTag: 'scrollTop',
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            },
            child: const Icon(Icons.arrow_upward),
          ),
        const SizedBox(height: 10),
        FloatingActionButton.small(
          heroTag: 'refresh',
          onPressed: _handleRefresh,
          tooltip: 'Refresh',
          child: _isLoading
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
    );
  }

  Widget _buildBody(BuildContext context) {
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();

    if (!deviceService.isAuthenticated()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.push("/login");
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    if ((deviceService.state.serverUrl ?? "").isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Server is not configured. Please configure the server URL.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Show error state
    if (_hasError) {
      return _buildErrorState();
    }

    // Show loading state only if no cached data
    if (_isLoading && _photosByMonth.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading your photos..."),
          ],
        ),
      );
    }

    // Show empty state
    if (_photosByMonth.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    // Show gallery
    return _buildGallery();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadFolders(isRetry: true),
              child: const Text("Retry"),
            ),
            if (_photosByMonth.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                  });
                },
                child: const Text("Show cached photos"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: GalleryStyles.emptyStateIconSize,
            color: GalleryStyles.emptyStateIconColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            "No photos found",
            style: GalleryStyles.emptyStateTitleStyle(context),
          ),
          const SizedBox(height: 8),
          Text(
            "Sync your photos to see them here",
            style: GalleryStyles.emptyStateSubtitleStyle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    final sortedMonths = _photosByMonth.keys.toList();
    sortedMonths.sort((a, b) {
      // Put "Recent" (unknown date) last; otherwise newest month first (descending by date taken)
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

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: sortedMonths.length * 2 +
            1, // month headers + grids + loading indicator
        itemBuilder: (context, index) {
          // Loading indicator at top
          if (index == 0 && (_isLoading || _isRefreshing)) {
            return const LinearProgressIndicator();
          }

          // Adjust index for loading indicator
          final adjustedIndex =
              (_isLoading || _isRefreshing) ? index - 1 : index;

          // Calculate which month and whether it's header or grid
          final monthIndex = adjustedIndex ~/ 2;
          final isHeader = adjustedIndex % 2 == 0;

          if (monthIndex >= sortedMonths.length) {
            return const SizedBox(height: 80); // Bottom padding
          }

          final month = sortedMonths[monthIndex];
          final photos = _photosByMonth[month] ?? [];

          if (isHeader) {
            // Month header (tappable to collapse/expand)
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Text(
                        '${photos.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            // Photos grid (hidden when month is collapsed)
            if (_collapsedMonths.contains(month)) {
              return const SizedBox.shrink();
            }
            if (_isGridView) {
              return Padding(
                padding: GalleryStyles.galleryPadding,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    mainAxisSpacing: GalleryStyles.photoSpacing,
                    crossAxisSpacing: GalleryStyles.photoSpacing,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return GalleryPhotoTile(
                      photo: photo,
                      onTap: _selectionMode
                          ? () => _toggleSelection(photo)
                          : () => _openPhotoViewer(context, photos, index),
                      isSelectionMode: _selectionMode,
                      isSelected: _selectedPaths.contains(photo.path),
                    );
                  },
                ),
              );
            } else {
              // List view
              return Column(
                children: photos.map((photo) {
                  final index = photos.indexOf(photo);
                  return ListTile(
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: GalleryPhotoTile(
                        photo: photo,
                        onTap: _selectionMode
                            ? () => _toggleSelection(photo)
                            : () => _openPhotoViewer(context, photos, index),
                        isSelectionMode: _selectionMode,
                        isSelected: _selectedPaths.contains(photo.path),
                      ),
                    ),
                    title: Text(photo.path.split('/').last),
                    subtitle: Text(photo.folder),
                    onTap: _selectionMode
                        ? () => _toggleSelection(photo)
                        : () => _openPhotoViewer(context, photos, index),
                  );
                }).toList(),
              );
            }
          }
        },
      ),
    );
  }

  void _openPhotoViewer(
      BuildContext context, List<PhotoItem> photos, int initialIndex) {
    final photo = photos[initialIndex];

    if (photo.isVideo) {
      _openVideoPlayer(context, photo, photos, initialIndex);
    } else {
      _pushViewerAndRefreshIfTrashed(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoViewerScreen(
            photos: photos,
            initialIndex: initialIndex,
          ),
        ),
      );
    }
  }

  void _openVideoPlayer(
    BuildContext context,
    PhotoItem video,
    List<PhotoItem> photos,
    int initialIndex,
  ) {
    _pushViewerAndRefreshIfTrashed(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          video: video,
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _pushViewerAndRefreshIfTrashed(
      BuildContext context, MaterialPageRoute route) async {
    final result = await Navigator.push<Object?>(context, route);
    if (!mounted) return;
    if (result is String) {
      setState(() => _removePhotosFromCache([result]));
    } else if (result is List<String>) {
      setState(() => _removePhotosFromCache(result));
    }
  }

  List<String> getChildrenFolders(List<NetFolder>? folders) {
    final List<String> allSubFolders = [];
    if (folders != null) {
      for (var f in folders) {
        allSubFolders.add(f.name);
        if (f.subFolders != null) {
          allSubFolders.addAll(getChildrenFolders(f.subFolders));
        }
      }
    }
    return allSubFolders;
  }

  Future<List<String>> getAllFolders(DeviceServicesCubit deviceService) async {
    if ((deviceService.state.serverUrl ?? "").isEmpty) {
      return [];
    }
    List<NetFolder>? folders = await apiGetFolders(
        deviceService.state.currentUser!.email, deviceService.state.id);

    final List<String> allFolders = getChildrenFolders(folders);
    return allFolders
        .where((f) => f != 'Trash' && !f.startsWith('Trash/'))
        .toList();
  }

  Future<List<String>> getAllFiles(
      DeviceServicesCubit deviceService, String folder) async {
    if ((deviceService.state.serverUrl ?? "").isEmpty) {
      return [];
    }
    List<String>? files = await apiGetFiles(
        deviceService.state.currentUser!.email, deviceService.state.id, folder);

    return files ?? [];
  }

  List<PhotoItem> _getAllPhotosInOrder() {
    final sortedMonths = _photosByMonth.keys.toList();
    sortedMonths.sort((a, b) {
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

    final allPhotos = <PhotoItem>[];
    for (final month in sortedMonths) {
      allPhotos.addAll(_photosByMonth[month] ?? []);
    }
    return allPhotos;
  }

  Widget itemsView(BuildContext context) {
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();
    deviceService.state.lastErrorMessage = null;
    if (!deviceService.isAuthenticated()) {
      context.push("/login");
      return Container();
    }

    return Container(
        margin: const EdgeInsets.only(
            left: 10.0, right: 10.0, top: 30.0, bottom: 30.0),
        child: ((deviceService.state.serverUrl ?? "") == "")
            ? const Text(
                "There is no files synced to the server or the server is not configured.")
            : FutureBuilder<List<String>>(
                future: getAllFolders(deviceService),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text((snapshot.error as CustomError).message);
                  } else {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return const CircularProgressIndicator();
                      case ConnectionState.active:
                      case ConnectionState.done:
                        if (snapshot.hasData) {
                          final folders = snapshot.data!;
                          return folders.isEmpty
                              ? const Text(
                                  "There is no files synced to the server or the server is not configured.")
                              : ListView(
                                  physics: const PageScrollPhysics(),
                                  children:
                                      photoGridWidgets(folders, deviceService));
                        } else {
                          return const Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                Text(
                                  "There is no synced photos/videos from this device and nickname.",
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  "Please go the menu and select 'Sync' to setup configurations.",
                                  textAlign: TextAlign.center,
                                ),
                                Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      "Go to MOBISYNC.EU for help.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ))
                              ]));
                        }
                    }
                  }
                },
              ));
  }

  List<Widget> photoGridWidgets(
      List<String> folders, DeviceServicesCubit deviceService) {
    List<Widget> result = [];
    for (var folder in folders) {
      result.add(Card(
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(folder,
                  style: const TextStyle(fontWeight: FontWeight.bold)))));
      result.add(FutureBuilder<List<String>>(
        future: getAllFiles(deviceService, folder),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else if (snapshot.hasData) {
            final files = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(1.0),
              gridDelegate: CustomGridDelegate(dimension: 100.0),
              shrinkWrap: true,
              itemCount: files.length,
              physics: const PageScrollPhysics(),
              itemBuilder: (context, index) {
                return GridTile(
                    child: Container(
                  margin: const EdgeInsets.all(2.0),
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    gradient: const RadialGradient(
                      colors: <Color>[
                        Color.fromARGB(15, 249, 250, 251),
                        Color.fromARGB(44, 120, 121, 122)
                      ],
                    ),
                  ),
                  child: photoWidget(files[index], deviceService),
                ));
              },
            );
          } else {
            return const Text(
              "No photos loaded",
              style: TextStyle(fontSize: 10),
            );
          }
        },
      ));
    }
    return result;
  }

  Widget photoWidget(String file, DeviceServicesCubit deviceService) {
    return FutureBuilder<Uint8List?>(
        future: apiGetImageBytes(deviceService.state.currentUser!.email,
            deviceService.state.id, file),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else if (snapshot.hasData) {
            final fileData = snapshot.data!;
            return Image.memory(fileData);
          } else {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      file.split("/").last,
                      style: const TextStyle(fontSize: 9),
                    )));
          }
        });
  }
}
