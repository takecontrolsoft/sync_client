// lib/services/enhanced_cache_service.dart

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_service.dart';
import 'thumbnail_cache_service.dart';

class EnhancedCacheService extends CacheService {
  static const String _thumbnailPrefix = 'cached_thumb_';
  static const String _fullImagePrefix = 'cached_image_';
  static const Duration _imageCacheExpiry = Duration(days: 7);

  // Thumbnail caching: disk + memory via ThumbnailCacheService for fast lists
  static Future<void> cacheThumbnail(String file, Uint8List data) async {
    await ThumbnailCacheService.put(file, data);
  }

  static Future<Uint8List?> getCachedThumbnail(String file) async {
    return ThumbnailCacheService.get(file);
  }

  // Full image caching
  static Future<void> cacheImage(String file, Uint8List data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_fullImagePrefix${_sanitizeKey(file)}';

      final base64String = base64Encode(data);
      await prefs.setString(key, base64String);
      await prefs.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
  }

  static Future<Uint8List?> getCachedImage(String file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_fullImagePrefix${_sanitizeKey(file)}';
      final base64String = prefs.getString(key);
      final cacheTime = prefs.getInt('${key}_time');

      if (base64String != null && cacheTime != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (cacheAge < _imageCacheExpiry.inMilliseconds) {
          return base64Decode(base64String);
        }
      }
    } catch (e) {
      debugPrint('Error reading image cache: $e');
    }
    return null;
  }

  // Clear all caches
  static Future<void> clearCache() async {
    await ThumbnailCacheService.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_thumbnailPrefix) ||
          key.startsWith(_fullImagePrefix)) {
        await prefs.remove(key);
      }
    }
  }

  // Clear old cache entries (SharedPreferences only; disk thumbnail cache has its own expiry)
  static Future<void> clearOldCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final key in keys) {
      if (key.endsWith('_time')) {
        final cacheTime = prefs.getInt(key);
        if (cacheTime != null) {
          final age = now - cacheTime;

          // Remove if older than expiry (full image only; thumbnails are on disk)
          if (key.contains(_fullImagePrefix) &&
              age > _imageCacheExpiry.inMilliseconds) {
            final dataKey = key.substring(0, key.length - 5); // Remove '_time'
            await prefs.remove(dataKey);
            await prefs.remove(key);
          }
        }
      }
    }
  }

  // Get cache size (SharedPreferences only)
  static Future<int> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int totalSize = 0;

    for (final key in keys) {
      if ((key.startsWith(_thumbnailPrefix) ||
              key.startsWith(_fullImagePrefix)) &&
          !key.endsWith('_time')) {
        final data = prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
        }
      }
    }

    return totalSize;
  }

  // Sanitize key to remove invalid characters
  static String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^\w\-.]'), '_');
  }
}
