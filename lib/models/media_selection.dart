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
  final String? url;  // Added for Cloudinary URL
  final String? localPath;  // Added for local file path

  MediaFile({
    required this.id,
    required this.file,
    required this.type,
    required this.name,
    required this.size,
    this.caption,
    this.thumbnailPath,
    this.url,
    this.localPath,  // Added localPath parameter
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
    String? url,
    String? localPath,  // Added localPath parameter
  }) {
    return MediaFile(
      id: id ?? this.id,
      file: file ?? this.file,
      type: type ?? this.type,
      name: name ?? this.name,
      size: size ?? this.size,
      caption: caption ?? this.caption,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,  // Added localPath field
    );
  }
}




