// lib/services/enhanced_cache_service.dart

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_service.dart';

class EnhancedCacheService extends CacheService {
  static const String _thumbnailPrefix = 'cached_thumb_';
  static const String _fullImagePrefix = 'cached_image_';
  static const Duration _thumbnailCacheExpiry = Duration(days: 30);
  static const Duration _imageCacheExpiry = Duration(days: 7);

  // Thumbnail caching
  static Future<void> cacheThumbnail(String file, Uint8List data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_thumbnailPrefix${_sanitizeKey(file)}';

      // Compress if too large (SharedPreferences has size limits)
      final compressedData =
          data.length > 500000 ? await _compressImage(data, 0.5) : data;

      final base64String = base64Encode(compressedData);
      await prefs.setString(key, base64String);
      await prefs.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching thumbnail: $e');
    }
  }

  static Future<Uint8List?> getCachedThumbnail(String file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_thumbnailPrefix${_sanitizeKey(file)}';
      final base64String = prefs.getString(key);
      final cacheTime = prefs.getInt('${key}_time');

      if (base64String != null && cacheTime != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (cacheAge < _thumbnailCacheExpiry.inMilliseconds) {
          return base64Decode(base64String);
        }
      }
    } catch (e) {
      debugPrint('Error reading thumbnail cache: $e');
    }
    return null;
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
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_thumbnailPrefix) ||
          key.startsWith(_fullImagePrefix)) {
        await prefs.remove(key);
      }
    }
  }

  // Clear old cache entries
  static Future<void> clearOldCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final key in keys) {
      if (key.endsWith('_time')) {
        final cacheTime = prefs.getInt(key);
        if (cacheTime != null) {
          final age = now - cacheTime;

          // Remove if older than expiry
          if ((key.contains(_thumbnailPrefix) &&
                  age > _thumbnailCacheExpiry.inMilliseconds) ||
              (key.contains(_fullImagePrefix) &&
                  age > _imageCacheExpiry.inMilliseconds)) {
            final dataKey = key.substring(0, key.length - 5); // Remove '_time'
            await prefs.remove(dataKey);
            await prefs.remove(key);
          }
        }
      }
    }
  }

  // Get cache size
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

  // Simple image compression (you might want to use a proper image package)
  static Future<Uint8List> _compressImage(
      Uint8List data, double quality) async {
    // This is a placeholder - in production, use image package for proper compression
    // For now, just return the original data
    return data;
  }
}
