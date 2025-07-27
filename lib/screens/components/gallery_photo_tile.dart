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

  const GalleryPhotoTile({
    Key? key,
    required this.photo,
    required this.onTap,
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

  Future<Uint8List?> _loadImage(DeviceServicesCubit deviceService) async {
    try {
      // Check cache first
      final cachedThumb =
          await EnhancedCacheService.getCachedThumbnail(widget.photo.path);
      if (cachedThumb != null) {
        return cachedThumb;
      }

      // Load from server
      final data = await apiGetImageBytes(
        deviceService.state.currentUser!.email,
        deviceService.state.id,
        widget.photo.path,
      );

      if (data != null && data.isNotEmpty) {
        // Cache for future use
        await EnhancedCacheService.cacheThumbnail(widget.photo.path, data);
        return data;
      }

      return null;
    } catch (e) {
      debugPrint('Error loading image ${widget.photo.path}: $e');
      return null;
    }
  }
}
