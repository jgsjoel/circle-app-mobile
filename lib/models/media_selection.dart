import 'dart:io';

enum MediaType { image, video, audio }

class MediaFile {
  final String id;
  final File file;
  final MediaType type;
  final String name;
  final int size;
  final String? caption;
  final String? thumbnailPath;

  MediaFile({
    required this.id,
    required this.file,
    required this.type,
    required this.name,
    required this.size,
    this.caption,
    this.thumbnailPath,
  });

  bool get isValidSize => size <= 16 * 1024 * 1024; // 16MB limit

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  MediaFile copyWith({
    String? id,
    File? file,
    MediaType? type,
    String? name,
    int? size,
    String? caption,
    String? thumbnailPath,
  }) {
    return MediaFile(
      id: id ?? this.id,
      file: file ?? this.file,
      type: type ?? this.type,
      name: name ?? this.name,
      size: size ?? this.size,
      caption: caption ?? this.caption,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}


