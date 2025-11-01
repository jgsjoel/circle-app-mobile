import 'package:chat/database/entities/message.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class MediaFileEntity {
  int id;

  String source;  // Local file path for sender, Cloudinary URL for receiver
  String publicId;

  final message = ToOne<MessageEntity>();

  MediaFileEntity({
    this.id = 0,
    required this.source,
    required this.publicId,
  });
}