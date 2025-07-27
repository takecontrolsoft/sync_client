import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/models/photo_item.dart';
import 'package:sync_client/core/core.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sync_client/config/theme/app_theme.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<PhotoItem> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    Key? key,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = true;
  final Map<int, Uint8List?> _thumbnailCache = {};
  final Map<int, Uint8List?> _fullImageCache = {};
  final Map<int, bool> _loadingStates = {};
  final Map<int, bool> _fullImageLoadingStates = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Start loading current image in full quality immediately
    _loadFullQualityImage(_currentIndex);

    // Preload adjacent images
    _preloadAdjacentImages();

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Request focus for keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: GalleryAnimations.pageTransition,
        curve: GalleryAnimations.defaultCurve,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.photos.length - 1) {
      _pageController.nextPage(
        duration: GalleryAnimations.pageTransition,
        curve: GalleryAnimations.defaultCurve,
      );
    }
  }

  void _preloadAdjacentImages() {
    // Load full quality for current and adjacent images
    final indices = [
      _currentIndex - 1,
      _currentIndex,
      _currentIndex + 1,
    ];

    for (final index in indices) {
      if (index >= 0 && index < widget.photos.length) {
        // Load thumbnail first for quick display
        _loadThumbnail(index);

        // Then load full quality
        if (index == _currentIndex || (index - _currentIndex).abs() <= 1) {
          _loadFullQualityImage(index);
        }
      }
    }
  }

  Future<void> _loadThumbnail(int index) async {
    if (_thumbnailCache.containsKey(index) || _loadingStates[index] == true) {
      return;
    }

    setState(() {
      _loadingStates[index] = true;
    });

    try {
      final photo = widget.photos[index];
      final deviceService = context.read<DeviceServicesCubit>();

      // Check cache for thumbnail
      final cachedImage =
          await EnhancedCacheService.getCachedThumbnail(photo.path);
      if (cachedImage != null) {
        if (mounted) {
          setState(() {
            _thumbnailCache[index] = cachedImage;
            _loadingStates[index] = false;
          });
        }
        return;
      }

      // Load thumbnail from server
      final data = await apiGetImageBytes(
        deviceService.state.currentUser!.email,
        deviceService.state.id,
        photo.path,
        fullQuality: false,
      );

      if (data != null && mounted) {
        setState(() {
          _thumbnailCache[index] = data;
          _loadingStates[index] = false;
        });

        // Cache the thumbnail
        await EnhancedCacheService.cacheThumbnail(photo.path, data);
      }
    } catch (e) {
      debugPrint('Error loading thumbnail: $e');
      if (mounted) {
        setState(() {
          _loadingStates[index] = false;
        });
      }
    }
  }

  Future<void> _loadFullQualityImage(int index) async {
    if (_fullImageCache.containsKey(index) ||
        _fullImageLoadingStates[index] == true) {
      return;
    }

    // Ensure we update the UI when starting to load
    if (mounted) {
      setState(() {
        _fullImageLoadingStates[index] = true;
      });
    }

    try {
      final photo = widget.photos[index];
      final deviceService = context.read<DeviceServicesCubit>();

      debugPrint('Loading full quality image for index $index: ${photo.path}');

      // Check cache for full quality image
      final cachedFullImage =
          await EnhancedCacheService.getCachedImage(photo.path);
      if (cachedFullImage != null) {
        debugPrint('Found cached full quality image for: ${photo.path}');
        if (mounted) {
          setState(() {
            _fullImageCache[index] = cachedFullImage;
            _fullImageLoadingStates[index] = false;
          });
        }
        return;
      }

      // Load full quality from server
      debugPrint('Loading full quality from server: ${photo.path}');
      final data = await apiGetImageBytes(
        deviceService.state.currentUser!.email,
        deviceService.state.id,
        photo.path,
        fullQuality: true,
      );

      if (data != null && mounted) {
        debugPrint('Loaded full quality image: ${data.length} bytes');

        // Force UI update with setState
        setState(() {
          _fullImageCache[index] = data;
          _fullImageLoadingStates[index] = false;
        });

        // Force a rebuild if current index
        if (index == _currentIndex) {
          // Add a small delay to ensure the image is decoded
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            setState(() {
              // Force rebuild by updating a dummy variable if needed
            });
          }
        }

        // Cache the full quality image asynchronously
        EnhancedCacheService.cacheImage(photo.path, data).catchError((e) {
          debugPrint('Failed to cache image: $e');
        });
      } else {
        debugPrint('Failed to load full quality image - no data received');
        if (mounted) {
          setState(() {
            _fullImageLoadingStates[index] = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading full quality image: $e');
      if (mounted) {
        setState(() {
          _fullImageLoadingStates[index] = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Load full quality for current image
    _loadFullQualityImage(index);

    // Preload adjacent images
    _preloadAdjacentImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _goToPrevious();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _goToNext();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
            } else if (event.logicalKey == LogicalKeyboardKey.space) {
              setState(() {
                _showOverlay = !_showOverlay;
              });
            }
          }
        },
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showOverlay = !_showOverlay;
            });
          },
          child: Stack(
            children: [
              // Photo gallery
              PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: widget.photos.length,
                onPageChanged: _onPageChanged,
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                builder: (context, index) {
                  final photo = widget.photos[index];
                  final fullImage = _fullImageCache[index];
                  final thumbnail = _thumbnailCache[index];
                  final isFullQuality = fullImage != null;
                  final isLoadingFull = _fullImageLoadingStates[index] == true;

                  if (thumbnail != null || fullImage != null) {
                    return PhotoViewGalleryPageOptions.customChild(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedCrossFade(
                            firstChild: thumbnail != null
                                ? PhotoView(
                                    imageProvider: MemoryImage(thumbnail),
                                    minScale: PhotoViewComputedScale.contained,
                                    maxScale:
                                        PhotoViewComputedScale.covered * 3,
                                    backgroundDecoration: const BoxDecoration(
                                        color: Colors.black),
                                    heroAttributes: PhotoViewHeroAttributes(
                                      tag:
                                          '${widget.photos[index].path}_$index',
                                    ),
                                    gaplessPlayback: true,
                                  )
                                : const SizedBox.shrink(),
                            secondChild: fullImage != null
                                ? PhotoView(
                                    imageProvider: MemoryImage(fullImage),
                                    minScale: PhotoViewComputedScale.contained,
                                    maxScale:
                                        PhotoViewComputedScale.covered * 3,
                                    backgroundDecoration: const BoxDecoration(
                                        color: Colors.black),
                                    heroAttributes: PhotoViewHeroAttributes(
                                      tag:
                                          '${widget.photos[index].path}_$index',
                                    ),
                                    gaplessPlayback: true,
                                  )
                                : const SizedBox.shrink(),
                            crossFadeState: isFullQuality
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 1000),
                            layoutBuilder: (Widget topChild, Key topChildKey,
                                Widget bottomChild, Key bottomChildKey) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Positioned.fill(
                                    key: bottomChildKey,
                                    child: bottomChild,
                                  ),
                                  Positioned.fill(
                                    key: topChildKey,
                                    child: topChild,
                                  ),
                                ],
                              );
                            },
                          ),

                          // Video play button overlay
                          if (photo.isVideo)
                            Center(
                              child: GestureDetector(
                                onTap: () => _playVideo(photo),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),

                          // HD loading indicator - Fixed positioning
                          if (isLoadingFull && !isFullQuality)
                            Positioned(
                              bottom: 120,
                              left: 0,
                              right: 0,
                              child: AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white
                                                  .withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Upgrading to HD',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  // No image at all yet - show loading
                  return PhotoViewGalleryPageOptions.customChild(
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              photo.isVideo
                                  ? 'Loading video preview...'
                                  : 'Loading photo...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Navigation arrows - Left
              if (_currentIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showOverlay ? 1.0 : 0.0,
                      duration: GalleryAnimations.overlayFade,
                      child: IgnorePointer(
                        ignoring: !_showOverlay,
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
                  ),
                ),

              // Navigation arrows - Right
              if (_currentIndex < widget.photos.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showOverlay ? 1.0 : 0.0,
                      duration: GalleryAnimations.overlayFade,
                      child: IgnorePointer(
                        ignoring: !_showOverlay,
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
                  ),
                ),

              // Overlay with controls
              AnimatedOpacity(
                opacity: _showOverlay ? 1.0 : 0.0,
                duration: GalleryAnimations.overlayFade,
                child: IgnorePointer(
                  ignoring: !_showOverlay,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: PhotoViewerStyles.overlayGradientColors,
                        stops: PhotoViewerStyles.overlayGradientStops,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Top bar
                        SafeArea(
                          child: Padding(
                            padding: PhotoViewerStyles.topBarPadding,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: Text(
                                    '${_currentIndex + 1} / ${widget.photos.length}',
                                    style:
                                        PhotoViewerStyles.pageIndicatorStyle(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // Quality indicator
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child:
                                      _fullImageCache.containsKey(_currentIndex)
                                          ? Container(
                                              key: const ValueKey('hd-badge'),
                                              padding: PhotoViewerStyles
                                                  .qualityIndicatorPadding,
                                              decoration: PhotoViewerStyles
                                                  .qualityIndicatorDecoration(),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.hd,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'HD',
                                                    style: PhotoViewerStyles
                                                        .qualityIndicatorTextStyle,
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox(
                                              key: ValueKey('empty'),
                                              width: 50),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.white),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'share':
                                        _shareImage();
                                        break;
                                      case 'delete':
                                        _deleteImage();
                                        break;
                                      case 'info':
                                        _showImageInfo();
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'share',
                                      child: ListTile(
                                        leading: Icon(Icons.share),
                                        title: Text('Share'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete),
                                        title: Text('Delete'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'info',
                                      child: ListTile(
                                        leading: Icon(Icons.info),
                                        title: Text('Info'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Bottom info
                        SafeArea(
                          child: Padding(
                            padding: PhotoViewerStyles.bottomInfoPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (widget
                                        .photos[_currentIndex].isVideo) ...[
                                      const Icon(
                                        Icons.videocam,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        widget.photos[_currentIndex].path
                                            .split('/')
                                            .last,
                                        style:
                                            PhotoViewerStyles.photoTitleStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.photos[_currentIndex].folder,
                                  style: PhotoViewerStyles.photoSubtitleStyle(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.photos[_currentIndex].date !=
                                    null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d, yyyy • h:mm a').format(
                                      widget.photos[_currentIndex].date!,
                                    ),
                                    style:
                                        PhotoViewerStyles.photoSubtitleStyle(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Page indicator dots (only show for reasonable number of photos)
              if (widget.photos.length > 1 &&
                  widget.photos.length <= 10 &&
                  _showOverlay)
                Positioned(
                  bottom: 90,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showOverlay ? 1.0 : 0.0,
                    duration: GalleryAnimations.overlayFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.photos.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: index == _currentIndex ? 24 : 8,
                          height: 8,
                          margin: PhotoViewerStyles.pageDotSpacing,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: index == _currentIndex
                                ? PhotoViewerStyles.activeDotColor
                                : PhotoViewerStyles.inactiveDotColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _playVideo(PhotoItem video) {
    // For now, show a dialog. You'll want to implement a proper video player
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    video.path.split('/').last,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Video playback coming soon',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // TODO: Implement actual video player
    // You can use packages like video_player or better_player
    // Example:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => VideoPlayerScreen(video: video),
    //   ),
    // );
  }

  Future<void> _shareImage() async {
    // Use full quality image if available, otherwise use thumbnail
    final imageData =
        _fullImageCache[_currentIndex] ?? _thumbnailCache[_currentIndex];
    if (imageData == null) return;

    try {
      // Save image to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.photos[_currentIndex].path.split('/').last;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageData);

      // Create ShareParams with the image file
      final params = ShareParams(
        text: 'Shared from Sync Client',
        files: [XFile(file.path)],
      );

      // Share using SharePlus.instance
      final result = await SharePlus.instance.share(params);

      if (result.status == ShareResultStatus.success) {
        debugPrint('Share successful');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image shared successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing image: $e')),
        );
      }
    }
  }

  Future<void> _deleteImage() async {
    final photo = widget.photos[_currentIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: Text(
            'Are you sure you want to delete ${photo.path.split('/').last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implement delete functionality
      // You'll need to add an API call to delete the image
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete functionality not implemented')),
      );
    }
  }

  void _showImageInfo() {
    final photo = widget.photos[_currentIndex];
    final imageData =
        _fullImageCache[_currentIndex] ?? _thumbnailCache[_currentIndex];
    final isFullQuality = _fullImageCache.containsKey(_currentIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: PhotoViewerStyles.infoSheetDecoration(context).color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: PhotoViewerStyles.infoSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  photo.isVideo ? 'Video Information' : 'Image Information',
                  style: PhotoViewerStyles.infoSheetTitleStyle,
                ),
                if (isFullQuality && !photo.isVideo)
                  Container(
                    padding: PhotoViewerStyles.qualityIndicatorPadding,
                    decoration: PhotoViewerStyles.qualityIndicatorDecoration(),
                    child: const Text(
                      'Full Quality',
                      style: PhotoViewerStyles.qualityIndicatorTextStyle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow('Name', photo.path.split('/').last),
            _InfoRow('Type', photo.isVideo ? 'Video' : 'Photo'),
            _InfoRow('Folder', photo.folder),
            if (photo.date != null)
              _InfoRow(
                  'Date', DateFormat('MMM d, yyyy h:mm a').format(photo.date!)),
            if (imageData != null && !photo.isVideo)
              _InfoRow('Size',
                  '${(imageData.length / 1024 / 1024).toStringAsFixed(2)} MB'),
            _InfoRow('Path', photo.path),
            if (!photo.isVideo)
              _InfoRow(
                  'Quality', isFullQuality ? 'Full Resolution' : 'Thumbnail'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: PhotoViewerStyles.infoRowLabelWidth,
            child: Text(
              label,
              style: PhotoViewerStyles.infoRowLabelStyle(context),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
