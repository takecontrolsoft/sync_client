// lib/services/cache_service.dart

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _foldersKey = 'cached_folders';
  static const String _foldersTimeKey = 'cached_folders_time';
  static const String _filesPrefix = 'cached_files_';
  static const String _imagesPrefix = 'cached_image_';
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _imageCacheExpiry = Duration(days: 7);

  static Future<List<String>?> getCachedFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_foldersKey);
      final cacheTime = prefs.getInt(_foldersTimeKey);

      if (cachedData != null && cacheTime != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (cacheAge < _cacheExpiry.inMilliseconds) {
          final List<dynamic> decoded = json.decode(cachedData);
          return decoded.cast<String>();
        }
      }
    } catch (e) {
      debugPrint('Error reading folder cache: $e');
    }
    return null;
  }

  static Future<void> cacheFolders(List<String> folders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_foldersKey, json.encode(folders));
      await prefs.setInt(
          _foldersTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching folders: $e');
    }
  }

  static Future<List<String>?> getCachedFiles(String folder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_filesPrefix$folder';
      final cachedData = prefs.getString(key);

      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        return decoded.cast<String>();
      }
    } catch (e) {
      debugPrint('Error reading files cache: $e');
    }
    return null;
  }

  static Future<void> cacheFiles(String folder, List<String> files) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_filesPrefix$folder';
      await prefs.setString(key, json.encode(files));
    } catch (e) {
      debugPrint('Error caching files: $e');
    }
  }

  static Future<void> cacheImage(String file, Uint8List data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_imagesPrefix$file';
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
      final key = '$_imagesPrefix$file';
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

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_foldersKey) ||
          key.startsWith(_filesPrefix) ||
          key.startsWith(_imagesPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
