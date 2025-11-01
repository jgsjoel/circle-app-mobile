import 'package:uuid/uuid.dart';

class MediaFile {
  final String id;
  final String source;  // Local file path for sender, Cloudinary URL for receiver
  final String publicId;
  final int messageId; // FK to message.id

  MediaFile({
    String? id,
    required this.source,
    required this.publicId,
    required this.messageId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source': source,
      'public_id': publicId,
      'message_id': messageId,
    };
  }

  factory MediaFile.fromMap(Map<String, dynamic> map) {
    return MediaFile(
      id: map['id'],
      source: map['source'],
      publicId: map['public_id'],
      messageId: map['message_id'],
    );
  }
}
