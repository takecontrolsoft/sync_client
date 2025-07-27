import 'package:intl/intl.dart';

class PhotoItem {
  final String path;
  final String folder;
  final DateTime? date;
  final String? month;
  final bool isVideo;

  PhotoItem(
      {required this.path,
      required this.folder,
      this.date,
      this.month,
      required this.isVideo});

  factory PhotoItem.fromPath(String path, String folder) {
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
    final lowerPath = path.toLowerCase();
    final isVideo = videoExtensions.any((ext) => lowerPath.endsWith(ext));

    final filename = path.split('/').last;
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
        extractedDate = DateTime.now();
        monthKey = 'Recent';
      }
    } else {
      extractedDate = DateTime.now();
      monthKey = 'Recent';
    }

    return PhotoItem(
      path: path,
      folder: folder,
      date: extractedDate,
      month: monthKey,
      isVideo: isVideo,
    );
  }
}
