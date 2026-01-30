import 'package:intl/intl.dart';

class PhotoItem {
  final String path;
  final String folder;
  final DateTime? date;
  final String? month;
  final bool isVideo;

  /// When set (e.g. from "all devices" view), use this device for img/stream requests.
  final String? deviceIdOverride;

  PhotoItem(
      {required this.path,
      required this.folder,
      this.date,
      this.month,
      required this.isVideo,
      this.deviceIdOverride});

  /// Full path for API and cache. Avoid duplicating folder when path already
  /// contains it (e.g. server returns "2026/1/file.mp4" for folder "2026/1").
  /// Always uses forward slashes for server/cache.
  String get fullPath {
    final pathSlash = path.replaceAll(r'\', '/');
    final folderSlash = folder.replaceAll(r'\', '/');
    if (folderSlash.isEmpty) return pathSlash;
    // Path may already be full (e.g. "2026/1/file.mp4") – don't prepend folder again
    if (pathSlash == folderSlash || pathSlash.startsWith('$folderSlash/')) {
      return pathSlash;
    }
    return '$folderSlash/$pathSlash';
  }

  /// File extensions treated as documents (for "move documents to trash").
  static const List<String> documentExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
    '.rtf',
    '.odt',
    '.ods',
    '.odp',
    '.pages',
    '.numbers',
    '.key',
  ];

  static bool isDocumentPath(String path) {
    final lower = path.toLowerCase();
    return documentExtensions.any((ext) => lower.endsWith(ext));
  }

  /// Parse server file entry: when from "all devices" the entry is "deviceId/path".
  /// Returns [deviceId, path] or [null, path] when no deviceId prefix.
  static List<String?> parseDeviceIdPath(String entry) {
    final idx = entry.indexOf('/');
    if (idx <= 0) return [null, entry];
    return [entry.substring(0, idx), entry.substring(idx + 1)];
  }

  factory PhotoItem.fromPath(String path, String folder,
      {String? deviceIdOverride}) {
    // Normalize to forward slashes (server/cache expect /; Windows may give \)
    final pathNorm = path.replaceAll(r'\', '/');
    final folderNorm = folder.replaceAll(r'\', '/');

    DateTime? extractedDate;
    String? monthKey;

    // Detect video files
    final videoExtensions = [
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.webm',
      '.m4v',
      '.3gp'
    ];
    final lowerPath = pathNorm.toLowerCase();
    final isVideo = videoExtensions.any((ext) => lowerPath.endsWith(ext));

    final filename = pathNorm.split('/').last;

    // 1) Try date from filename (capture/taken date patterns)
    //    YYYY-MM-DD, YYYY_MM_DD, YYYYMMDD, IMG_20240115_*, 20240115_*, etc.
    final dateRegex = RegExp(r'(\d{4})[-_]?(\d{2})[-_]?(\d{2})');
    final match = dateRegex.firstMatch(filename);
    if (match != null) {
      try {
        extractedDate = DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
        monthKey = DateFormat('MMMM yyyy').format(extractedDate);
      } catch (e) {
        // fall through to folder or Recent
      }
    }

    // 2) If no date in filename, use folder (server often stores as Year/Month = date taken)
    if (extractedDate == null && folderNorm.isNotEmpty) {
      final parts = folderNorm.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 1) {
        final year = int.tryParse(parts[0]);
        if (year != null && year >= 1900 && year <= 2100) {
          final month = parts.length >= 2 ? int.tryParse(parts[1]) : 1;
          if (month != null && month >= 1 && month <= 12) {
            try {
              extractedDate = DateTime(year, month, 1);
              monthKey = DateFormat('MMMM yyyy').format(extractedDate);
            } catch (e) {
              // use year only
              extractedDate = DateTime(year, 1, 1);
              monthKey = DateFormat('MMMM yyyy').format(extractedDate);
            }
          } else {
            extractedDate = DateTime(year, 1, 1);
            monthKey = DateFormat('MMMM yyyy').format(extractedDate);
          }
        }
      }
    }

    // 3) Only use "Recent" when we truly have no date (unknown capture date)
    if (extractedDate == null) {
      extractedDate = DateTime.now();
      monthKey = 'Recent';
    }

    return PhotoItem(
      path: pathNorm,
      folder: folderNorm,
      date: extractedDate,
      month: monthKey,
      isVideo: isVideo,
      deviceIdOverride: deviceIdOverride,
    );
  }
}
