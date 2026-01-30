// lib/screens/components/gallery_photo_tile.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/config/theme/app_theme.dart';
import 'package:sync_client/models/photo_item.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/core/core.dart';

class MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String month;

  MonthHeaderDelegate({required this.month});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: GalleryStyles.monthHeaderDecoration(context),
      padding: GalleryStyles.monthHeaderPadding,
      child: Text(
        month,
        style: GalleryStyles.monthHeaderTextStyle(context),
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant MonthHeaderDelegate oldDelegate) {
    return month != oldDelegate.month;
  }
}

// Enhanced photo tile with lazy loading
class GalleryPhotoTile extends StatefulWidget {
  final PhotoItem photo;
  final VoidCallback onTap;
  final bool isSelectionMode;
  final bool isSelected;

  const GalleryPhotoTile({
    Key? key,
    required this.photo,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<GalleryPhotoTile> createState() => _GalleryPhotoTileState();
}

class _GalleryPhotoTileState extends State<GalleryPhotoTile>
    with AutomaticKeepAliveClientMixin {
  bool _shouldLoad = false;
  Future<Uint8List?>? _imageFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: Key(widget.photo.path),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0 && !_shouldLoad) {
          setState(() {
            _shouldLoad = true;
            final deviceService = context.read<DeviceServicesCubit>();
            _imageFuture = _loadImage(deviceService);
          });
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: GalleryStyles.photoTileDecoration(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail image
              _shouldLoad
                  ? FutureBuilder<Uint8List?>(
                      future: _imageFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: SizedBox(
                              width: GalleryStyles.loadingIndicatorSize,
                              height: GalleryStyles.loadingIndicatorSize,
                              child: CircularProgressIndicator(
                                strokeWidth:
                                    GalleryStyles.loadingIndicatorStrokeWidth,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  GalleryStyles.loadingIndicatorColor(context),
                                ),
                              ),
                            ),
                          );
                        } else if (snapshot.hasData && snapshot.data != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(
                                GalleryStyles.borderRadius),
                            child: Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildErrorWidget();
                              },
                            ),
                          );
                        } else {
                          return _buildErrorWidget();
                        }
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.image,
                        color: GalleryStyles.errorIconColor(context),
                        size: GalleryStyles.errorIconSize,
                      ),
                    ),

              // Video play button overlay
              if (widget.photo.isVideo)
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

              // Selection overlay (checkbox)
              if (widget.isSelectionMode)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                ),

              // Video duration badge (optional)
              if (widget.photo.isVideo)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Icon(
        Icons.broken_image,
        color: GalleryStyles.errorIconColor(context),
        size: GalleryStyles.errorIconSize,
      ),
    );
  }

  static const Duration _loadTimeout = Duration(seconds: 20);

  Future<Uint8List?> _loadImage(DeviceServicesCubit deviceService) async {
    final fullPath = widget.photo.fullPath;
    if (fullPath.isEmpty) {
      debugPrint('Thumbnail load: empty path, skipping');
      return null;
    }
    try {
      // 1) Cache first (memory then disk), then server
      final cachedThumb =
          await EnhancedCacheService.getCachedThumbnail(fullPath);
      if (cachedThumb != null && cachedThumb.isNotEmpty) {
        return cachedThumb;
      }

      // 2) Load from server – always when not in cache
      debugPrint('Thumbnail load from server: $fullPath');
      final data = await apiGetImageBytes(
        deviceService.state.currentUser!.email,
        deviceService.state.id,
        fullPath,
      ).timeout(_loadTimeout, onTimeout: () {
        debugPrint('Thumbnail load timeout: $fullPath');
        return null;
      });

      if (data != null && data.isNotEmpty) {
        debugPrint('Thumbnail loaded from server (${data.length} bytes): $fullPath');
        await EnhancedCacheService.cacheThumbnail(fullPath, data);
        return data;
      }

      debugPrint('Thumbnail load: server returned no data: $fullPath');
      return null;
    } catch (e) {
      debugPrint('Error loading image $fullPath: $e');
      return null;
    }
  }
}
