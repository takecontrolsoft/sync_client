// lib/screens/components/video_player_screen.dart
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/config/theme/app_theme.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/models/photo_item.dart';
import 'package:sync_client/screens/components/photo_viewer_screen.dart';
import 'package:sync_client/services/services.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.video,
    this.photos,
    this.initialIndex,
    this.isFromTrash = false,
  });

  final PhotoItem video;

  /// When set, app bar shows prev/next and move-to-trash (unless isFromTrash).
  final List<PhotoItem>? photos;
  final int? initialIndex;

  /// When true (e.g. opened from Trash), hide move-to-trash button.
  final bool isFromTrash;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  Player? _player;
  VideoController? _videoController;
  String? _errorMessage;
  bool _ready = false;
  Uint8List? _posterBytes;

  @override
  void initState() {
    super.initState();
    _loadPoster();
    _initPlayer();
  }

  Future<void> _loadPoster() async {
    final fullPath = widget.video.fullPath;
    final cached = await EnhancedCacheService.getCachedThumbnail(fullPath);
    if (cached != null && mounted) {
      setState(() => _posterBytes = cached);
      return;
    }
    final deviceService = context.read<DeviceServicesCubit>();
    final user = deviceService.state.currentUser?.email;
    final deviceId =
        widget.video.deviceIdOverride ?? deviceService.state.id;
    if (user == null || deviceId.isEmpty) return;
    try {
      final data =
          await apiGetImageBytes(user, deviceId, fullPath, fullQuality: false);
      if (data != null && mounted) {
        setState(() => _posterBytes = data);
        EnhancedCacheService.cacheThumbnail(fullPath, data);
      }
    } catch (_) {}
  }

  Future<void> _initPlayer() async {
    final deviceService = context.read<DeviceServicesCubit>();
    final serverUrl = deviceService.state.serverUrl;
    final user = deviceService.state.currentUser?.email;
    final deviceId =
        widget.video.deviceIdOverride ?? deviceService.state.id;

    if (serverUrl == null ||
        serverUrl.isEmpty ||
        user == null ||
        user.isEmpty ||
        deviceId.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Server or account not configured.';
        });
      }
      return;
    }

    final streamUrl = getStreamUrl(
      serverUrl,
      user,
      deviceId,
      widget.video.fullPath,
    );

    try {
      _player = Player();
      _videoController = VideoController(_player!);
      await _player!.open(Media(streamUrl.toString()));
      await _player!.play();
      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  bool get _hasGallery =>
      widget.photos != null &&
      widget.photos!.isNotEmpty &&
      widget.initialIndex != null &&
      widget.initialIndex! >= 0 &&
      widget.initialIndex! < widget.photos!.length;

  bool get _canGoPrevious => _hasGallery && widget.initialIndex! > 0;

  bool get _canGoNext =>
      _hasGallery && widget.initialIndex! < widget.photos!.length - 1;

  void _goToPrevious() {
    if (!_canGoPrevious) return;
    final idx = widget.initialIndex! - 1;
    final item = widget.photos![idx];
    Navigator.of(context).pop();
    if (item.isVideo) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => VideoPlayerScreen(
            video: item,
            photos: widget.photos,
            initialIndex: idx,
            isFromTrash: widget.isFromTrash,
          ),
        ),
      );
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => PhotoViewerScreen(
            photos: widget.photos!,
            initialIndex: idx,
            isFromTrash: widget.isFromTrash,
          ),
        ),
      );
    }
  }

  void _goToNext() {
    if (!_canGoNext) return;
    final idx = widget.initialIndex! + 1;
    final item = widget.photos![idx];
    Navigator.of(context).pop();
    if (item.isVideo) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => VideoPlayerScreen(
            video: item,
            photos: widget.photos,
            initialIndex: idx,
            isFromTrash: widget.isFromTrash,
          ),
        ),
      );
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => PhotoViewerScreen(
            photos: widget.photos!,
            initialIndex: idx,
            isFromTrash: widget.isFromTrash,
          ),
        ),
      );
    }
  }

  Future<void> _moveToTrash() async {
    final deviceService = context.read<DeviceServicesCubit>();
    final user = deviceService.state.currentUser?.email;
    final deviceId =
        widget.video.deviceIdOverride ?? deviceService.state.id;
    if (user == null || user.isEmpty || deviceId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not signed in')),
        );
      }
      return;
    }
    try {
      final ok = await apiMoveToTrash(user, deviceId, [widget.video.path]);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moved to Trash')),
        );
        context.read<GalleryRefreshCubit>().requestTrashRefresh();
        Navigator.of(context).pop(widget.video.path);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          widget.video.path.split('/').last,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!widget.isFromTrash)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _moveToTrash,
              tooltip: 'Move to Trash',
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          // Prev/next arrows on both sides of video (not in app bar)
          if (_canGoPrevious)
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _goToPrevious,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_canGoNext)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _goToNext,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: GalleryStyles.errorIconColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GalleryStyles.errorIconColor(context),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    if (_videoController == null || !_ready) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (_posterBytes != null)
            Positioned.fill(
              child: Image.memory(
                _posterBytes!,
                fit: BoxFit.contain,
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Loading video...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Center(
      child: Video(controller: _videoController!),
    );
  }
}
