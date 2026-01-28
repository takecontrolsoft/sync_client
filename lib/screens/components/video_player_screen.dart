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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
  });

  final PhotoItem video;
  /// When set, app bar shows prev/next and move-to-trash.
  final List<PhotoItem>? photos;
  final int? initialIndex;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  Player? _player;
  VideoController? _videoController;
  String? _errorMessage;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final deviceService = context.read<DeviceServicesCubit>();
    final serverUrl = deviceService.state.serverUrl;
    final user = deviceService.state.currentUser?.email;
    final deviceId = deviceService.state.id;

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
      widget.video.path,
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

  bool get _hasGallery => widget.photos != null &&
      widget.photos!.isNotEmpty &&
      widget.initialIndex != null &&
      widget.initialIndex! >= 0 &&
      widget.initialIndex! < widget.photos!.length;

  bool get _canGoPrevious =>
      _hasGallery && widget.initialIndex! > 0;

  bool get _canGoNext =>
      _hasGallery && widget.initialIndex! < widget.photos!.length - 1;

  void _goToPrevious() {
    if (!_canGoPrevious) return;
    final idx = widget.initialIndex! - 1;
    final item = widget.photos![idx];
    Navigator.of(context).pop();
    if (item.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            video: item,
            photos: widget.photos,
            initialIndex: idx,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PhotoViewerScreen(
            photos: widget.photos!,
            initialIndex: idx,
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            video: item,
            photos: widget.photos,
            initialIndex: idx,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PhotoViewerScreen(
            photos: widget.photos!,
            initialIndex: idx,
          ),
        ),
      );
    }
  }

  Future<void> _moveToTrash() async {
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
    try {
      final ok = await apiMoveToTrash(user, deviceId, [widget.video.path]);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moved to Trash')),
        );
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
          if (_canGoPrevious)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _goToPrevious,
              tooltip: 'Previous',
            ),
          if (_canGoNext)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _goToNext,
              tooltip: 'Next',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _moveToTrash,
            tooltip: 'Move to Trash',
          ),
        ],
      ),
      body: _buildBody(),
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
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: Video(controller: _videoController!),
    );
  }
}
