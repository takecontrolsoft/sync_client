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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const String _manifestFilename = 'manifest.txt';

/// Thumbnails stored as files on the device. No expiry – thumbnails don't change
/// unless deleted on server. Cache is cleared when user presses Sync.
class ThumbnailCacheService {
  static const int _maxMemoryEntries = 120;

  static Directory? _cacheDir;
  static final Map<String, _CacheEntry> _memoryCache = {};
  static final List<String> _memoryLru = [];

  /// Thumbnail files on device (e.g. ...\Roaming\...\thumbnails on Windows).
  /// Prefer support dir; fallback to cache then temp.
  static Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;

    Future<Directory> tryBase(Future<Directory> baseFuture, String label) async {
      final base = await baseFuture;
      if (!await base.exists()) {
        await base.create(recursive: true);
      }
      final thumbDir = Directory(p.join(base.path, 'thumbnails'));
      await thumbDir.create(recursive: true);
      debugPrint('ThumbnailCacheService: using $label: ${thumbDir.path}');
      return thumbDir;
    }

    try {
      _cacheDir = await tryBase(getApplicationSupportDirectory(), 'support');
      return _cacheDir!;
    } catch (e) {
      debugPrint('ThumbnailCacheService: support dir failed ($e), trying cache dir');
      try {
        _cacheDir = await tryBase(getApplicationCacheDirectory(), 'cache');
        return _cacheDir!;
      } catch (e2) {
        debugPrint('ThumbnailCacheService: cache dir failed ($e2), using temp dir');
        try {
          _cacheDir = await tryBase(getTemporaryDirectory(), 'temp');
          return _cacheDir!;
        } catch (e3) {
          debugPrint('ThumbnailCacheService: all dirs failed ($e3)');
          rethrow;
        }
      }
    }
  }

  static String _sanitizeKey(String path) {
    final safe = path
        .replaceAll(RegExp(r'[/\\]'), '_')
        .replaceAll(RegExp(r'[^\w\-.]'), '_');
    if (safe.length > 200) {
      return '${safe.hashCode.abs()}_${safe.substring(safe.length - 50)}';
    }
    return safe.isEmpty ? 'empty' : safe;
  }

  /// Returns cached thumbnail bytes: device files first, then in-memory cache.
  /// Returns null if not on device → caller should fetch from server and call put().
  /// Never throws; on timeout or disk error returns null so caller fetches from server.
  static Future<Uint8List?> get(String path) async {
    try {
      final key = _sanitizeKey(path);

      // 2) In-memory cache first (no disk I/O)
      final mem = _memoryCache[key];
      if (mem != null) {
        _touchLru(key);
        return mem.bytes;
      }

      // 1) Device files (with timeout so we don't hang on Windows)
      try {
        final dir = await _getCacheDir()
            .timeout(const Duration(seconds: 3), onTimeout: () => throw TimeoutException('getCacheDir'));
        final file = File(p.join(dir.path, key));
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _putMemory(key, bytes);
          return bytes;
        }
      } on TimeoutException catch (e) {
        debugPrint('ThumbnailCacheService get (disk) timeout: $e');
      } catch (e) {
        debugPrint('ThumbnailCacheService get (disk) error: $e');
      }
    } catch (e) {
      debugPrint('ThumbnailCacheService get error: $e');
    }
    return null;
  }

  /// Saves thumbnail as a file on the device and keeps a copy in memory.
  /// Never throws; if disk write fails, memory copy still used this session.
  static Future<void> put(String path, Uint8List bytes) async {
    try {
      final key = _sanitizeKey(path);
      _putMemory(key, bytes);

      try {
        final dir = await _getCacheDir();
        final filePath = p.join(dir.path, key);
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);
        final ok = await file.exists();
        debugPrint('ThumbnailCacheService put: ${ok ? "OK" : "FAIL"} $filePath');
        if (!ok) {
          debugPrint('ThumbnailCacheService put: file missing after write');
        }
        await _manifestAdd(dir, path);
      } on FileSystemException catch (e) {
        debugPrint('ThumbnailCacheService put (disk) FileSystemException: ${e.message} path=${e.path}');
      } catch (e, st) {
        debugPrint('ThumbnailCacheService put (disk) error: $e');
        debugPrint('ThumbnailCacheService put stack: $st');
      }
    } catch (e) {
      debugPrint('ThumbnailCacheService put error: $e');
    }
  }

  static File _manifestFile(Directory dir) =>
      File(p.join(dir.path, _manifestFilename));

  static Future<void> _manifestAdd(Directory dir, String path) async {
    try {
      final file = _manifestFile(dir);
      final lines = await file.exists() ? await file.readAsLines() : <String>[];
      if (lines.contains(path)) return;
      await file.writeAsString('${path.replaceAll('\n', ' ')}\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('ThumbnailCacheService _manifestAdd error: $e');
    }
  }

  /// All paths that have a cached thumbnail (from manifest).
  static Future<List<String>> listCachedPaths() async {
    try {
      final dir = await _getCacheDir();
      final file = _manifestFile(dir);
      if (!await file.exists()) return [];
      final lines = await file.readAsLines();
      return lines.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } catch (e) {
      debugPrint('ThumbnailCacheService listCachedPaths error: $e');
      return [];
    }
  }

  /// Removes one cached thumbnail (file + manifest entry + memory). Path must match manifest.
  static Future<void> delete(String path) async {
    final key = _sanitizeKey(path);
    _memoryCache.remove(key);
    _memoryLru.remove(key);
    try {
      final dir = await _getCacheDir();
      final file = File(p.join(dir.path, key));
      if (await file.exists()) await file.delete();
      final manifest = _manifestFile(dir);
      if (await manifest.exists()) {
        final lines = await manifest.readAsLines();
        final rest = lines.where((s) => s.trim() != path).toList();
        await manifest.writeAsString(rest.isEmpty ? '' : '${rest.join('\n')}\n');
      }
    } catch (e) {
      debugPrint('ThumbnailCacheService delete error: $e');
    }
  }

  static void _putMemory(String key, Uint8List bytes) {
    while (_memoryLru.length >= _maxMemoryEntries && _memoryLru.isNotEmpty) {
      final evict = _memoryLru.removeAt(0);
      _memoryCache.remove(evict);
    }
    _memoryCache[key] = _CacheEntry(bytes, DateTime.now());
    _touchLru(key);
  }

  static void _touchLru(String key) {
    _memoryLru.remove(key);
    _memoryLru.add(key);
  }

  static Future<void> clear() async {
    _memoryCache.clear();
    _memoryLru.clear();
    try {
      final dir = await _getCacheDir();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) await entity.delete();
        }
      }
      final manifest = _manifestFile(dir);
      if (await manifest.exists()) await manifest.delete();
    } catch (e) {
      debugPrint('ThumbnailCacheService clear error: $e');
    }
  }
}

class _CacheEntry {
  final Uint8List bytes;
  final DateTime at;
  _CacheEntry(this.bytes, this.at);
}
