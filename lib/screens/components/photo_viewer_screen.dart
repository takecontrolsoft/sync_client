import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/config/theme/app_theme.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/models/photo_item.dart';
import 'package:sync_client/screens/components/video_player_screen.dart';
import 'package:path/path.dart' as p;
import 'package:sync_client/services/services.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<PhotoItem> photos;
  final int initialIndex;

  /// When true (e.g. opened from Trash), hide "Move to Trash" option.
  final bool isFromTrash;

  const PhotoViewerScreen({
    Key? key,
    required this.photos,
    required this.initialIndex,
    this.isFromTrash = false,
  }) : super(key: key);

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = true;
  final Map<int, Uint8List?> _thumbnailCache = {};
  final Map<int, Uint8List?> _highImageCache = {};
  final Map<int, Uint8List?> _fullImageCache = {};
  final Map<int, bool> _loadingStates = {};
  final Map<int, bool> _highImageLoadingStates = {};
  final Map<int, bool> _fullImageLoadingStates = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Thumbnail first, then "high" (compressed, fast), then "full" in background
    _loadThumbnail(_currentIndex);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _loadHighThenFullQualityImage(_currentIndex);
    });
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
    // Restore same mode as main shell (immersive sticky on Android)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

        // Then load high (fast) then full for current and adjacent
        if (index == _currentIndex || (index - _currentIndex).abs() <= 1) {
          _loadHighThenFullQualityImage(index);
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

      // Check cache for thumbnail (disk + memory)
      final fullPath = photo.fullPath;
      final cachedImage =
          await EnhancedCacheService.getCachedThumbnail(fullPath);
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
      final deviceId = photo.deviceIdOverride ?? deviceService.state.id;
      final data = await apiGetImageBytes(
        deviceService.state.currentUser!.email,
        deviceId,
        fullPath,
        fullQuality: false,
      );

      if (data != null && mounted) {
        setState(() {
          _thumbnailCache[index] = data;
          _loadingStates[index] = false;
        });

        // Cache the thumbnail (disk + memory)
        await EnhancedCacheService.cacheThumbnail(fullPath, data);
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

  /// Load "high" (compressed, fast) first, then "full" in background. Display: full > high > thumbnail.
  Future<void> _loadHighThenFullQualityImage(int index) async {
    final photo = widget.photos[index];
    if (photo.isVideo) return;
    final deviceService = context.read<DeviceServicesCubit>();
    final fullPath = photo.fullPath;

    // 1) If we have full in cache, use it
    final cachedFull = await EnhancedCacheService.getCachedImage(fullPath);
    if (cachedFull != null && mounted) {
      setState(() {
        _fullImageCache[index] = cachedFull;
        _fullImageLoadingStates[index] = false;
        _highImageLoadingStates[index] = false;
      });
      return;
    }

    // 2) Load "high" first (server: max 1920px, JPEG 85% — fast)
    if (!_highImageCache.containsKey(index) &&
        _highImageLoadingStates[index] != true) {
      if (mounted) {
        setState(() => _highImageLoadingStates[index] = true);
      }
      try {
        final deviceId = photo.deviceIdOverride ?? deviceService.state.id;
        final highData = await apiGetImageBytes(
          deviceService.state.currentUser!.email,
          deviceId,
          fullPath,
          quality: 'high',
        );
        if (highData != null && mounted) {
          setState(() {
            _highImageCache[index] = highData;
            _highImageLoadingStates[index] = false;
          });
        } else if (mounted) {
          setState(() => _highImageLoadingStates[index] = false);
        }
      } catch (e) {
        debugPrint('Error loading high quality: $e');
        if (mounted) {
          setState(() => _highImageLoadingStates[index] = false);
        }
      }
    }

    // 3) Load "full" in background (server: JPEG 92%)
    if (_fullImageCache.containsKey(index) ||
        _fullImageLoadingStates[index] == true) {
      return;
    }
    if (mounted) {
      setState(() => _fullImageLoadingStates[index] = true);
    }
    try {
      final deviceId = photo.deviceIdOverride ?? deviceService.state.id;
      final fullData = await apiGetImageBytes(
        deviceService.state.currentUser!.email,
        deviceId,
        fullPath,
        quality: 'full',
      );
      if (fullData != null && mounted) {
        setState(() {
          _fullImageCache[index] = fullData;
          _fullImageLoadingStates[index] = false;
        });
        EnhancedCacheService.cacheImage(fullPath, fullData)
            .catchError((Object e) {
          debugPrint('Failed to cache image: $e');
        });
      } else if (mounted) {
        setState(() => _fullImageLoadingStates[index] = false);
      }
    } catch (e) {
      debugPrint('Error loading full quality: $e');
      if (mounted) {
        setState(() => _fullImageLoadingStates[index] = false);
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      // When swiping to a video, hide overlay so play button is tappable and video is visible
      if (widget.photos[index].isVideo) _showOverlay = false;
    });

    _loadHighThenFullQualityImage(index);
    _preloadAdjacentImages();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sideTapWidth = (screenWidth * 0.15).clamp(56.0, 120.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _goToPrevious();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _goToNext();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.space) {
              setState(() {
                _showOverlay = !_showOverlay;
              });
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showOverlay = !_showOverlay;
            });
          },
          child: Stack(
            children: [
              // Photo gallery (horizontal swipe already supported by PageView)
              PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: widget.photos.length,
                onPageChanged: _onPageChanged,
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                builder: (context, index) {
                  final photo = widget.photos[index];
                  final fullImage = _fullImageCache[index];
                  final highImage = _highImageCache[index];
                  final thumbnail = _thumbnailCache[index];
                  final bestDisplay = fullImage ?? highImage;
                  final isFullQuality = fullImage != null;
                  final isLoadingFull = _fullImageLoadingStates[index] == true;

                  if (thumbnail != null || bestDisplay != null) {
                    return PhotoViewGalleryPageOptions.customChild(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedCrossFade(
                            // When thumbnail-only: disable zoom/pan so horizontal swipe goes to gallery (next/prev)
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
                                    disableGestures: !isFullQuality,
                                  )
                                : const SizedBox.shrink(),
                            secondChild: bestDisplay != null
                                ? PhotoView(
                                    imageProvider: MemoryImage(bestDisplay),
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
                                    disableGestures: !isFullQuality,
                                  )
                                : const SizedBox.shrink(),
                            crossFadeState: bestDisplay != null
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

              // When overlay hidden: tap center shows controls — but NOT when current is video (so play button receives tap)
              if (!_showOverlay && !widget.photos[_currentIndex].isVideo)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _showOverlay = true),
                  ),
                ),

              // Always-active left/right tap zones for previous/next (work even when overlay hidden)
              if (widget.photos.length > 1 && _currentIndex > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: sideTapWidth,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _goToPrevious,
                  ),
                ),
              if (widget.photos.length > 1 &&
                  _currentIndex < widget.photos.length - 1)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: sideTapWidth,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _goToNext,
                  ),
                ),

              // Navigation arrows - left and right sides of photo (clear of top bar)
              if (widget.photos.length > 1 && _currentIndex > 0)
                Positioned(
                  left: 20,
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

              if (widget.photos.length > 1 &&
                  _currentIndex < widget.photos.length - 1)
                Positioned(
                  right: 20,
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

              // Overlay with controls; center ignores pointer so video play button receives taps
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
                                      case 'download':
                                        _downloadImage();
                                        break;
                                      case 'trash':
                                        _moveToTrash();
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
                                      value: 'download',
                                      child: ListTile(
                                        leading: Icon(Icons.download),
                                        title: Text('Download (full quality)'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    if (!widget.isFromTrash)
                                      const PopupMenuItem(
                                        value: 'trash',
                                        child: ListTile(
                                          leading: Icon(Icons.delete_outline),
                                          title: Text('Move to Trash'),
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

                        // Center: ignore pointer so taps reach gallery (e.g. video play button)
                        Expanded(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors:
                                      PhotoViewerStyles.overlayGradientColors,
                                  stops: PhotoViewerStyles.overlayGradientStops,
                                ),
                              ),
                            ),
                          ),
                        ),

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

              // When overlay hidden: always-visible back button so user can always exit
              if (!_showOverlay)
                Positioned(
                  left: 0,
                  top: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 8),
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
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
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => VideoPlayerScreen(
          video: video,
          photos: widget.photos,
          initialIndex: _currentIndex,
          isFromTrash: widget.isFromTrash,
        ),
      ),
    );
  }

  Future<void> _shareImage() async {
    final imageData = _fullImageCache[_currentIndex] ??
        _highImageCache[_currentIndex] ??
        _thumbnailCache[_currentIndex];
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

  Future<void> _downloadImage() async {
    final photo = widget.photos[_currentIndex];
    if (photo.isVideo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download is for photos only')),
        );
      }
      return;
    }

    // Prefer full quality; load from server if not cached
    Uint8List? bytes = _fullImageCache[_currentIndex];
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading full quality…')),
        );
      }
      final deviceService = context.read<DeviceServicesCubit>();
      final user = deviceService.state.currentUser?.email;
      final deviceId = photo.deviceIdOverride ?? deviceService.state.id;
      if (user == null || deviceId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not signed in')),
          );
        }
        return;
      }
      try {
        bytes = await apiGetImageBytes(
          user,
          deviceId,
          photo.fullPath,
          quality: 'full',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load: $e')),
          );
        }
        return;
      }
      if (bytes == null || !mounted) return;
    }

    final fileName = photo.path.split('/').last;
    try {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download is not supported on web')),
          );
        }
        return;
      }
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await SaverGallery.saveImage(
          bytes,
          fileName: fileName,
          skipIfExists: false,
        );
        if (!mounted) return;
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to gallery'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: ${result.errorMessage}')),
          );
        }
      } else {
        // Desktop: save to Pictures
        String picturesPath;
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'] ?? '';
          picturesPath = '$userProfile\\Pictures';
        } else {
          final home = Platform.environment['HOME'] ?? '';
          picturesPath = '$home/Pictures';
        }
        final dir = Directory(picturesPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File(p.join(picturesPath, fileName));
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to $picturesPath'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _moveToTrash() async {
    final photo = widget.photos[_currentIndex];
    final deviceService = context.read<DeviceServicesCubit>();
    final user = deviceService.state.currentUser?.email;
    final deviceId = photo.deviceIdOverride ?? deviceService.state.id;
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
        title: const Text('Move to Trash'),
        content: Text(
            'Move ${photo.path.split('/').last} to Trash? You can restore it later from Trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      final ok = await apiMoveToTrash(user, deviceId, [photo.path]);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moved to Trash')),
        );
        context.read<GalleryRefreshCubit>().requestTrashRefresh();
        Navigator.of(context).pop(photo.path);
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

  void _showImageInfo() {
    final photo = widget.photos[_currentIndex];
    final imageData = _fullImageCache[_currentIndex] ??
        _highImageCache[_currentIndex] ??
        _thumbnailCache[_currentIndex];
    final isFullQuality = _fullImageCache.containsKey(_currentIndex);

    showModalBottomSheet<void>(
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
