import 'package:chat/database/entities/message.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class MediaFileEntity {
  int id;

  String url;
  String publicId;

  final message = ToOne<MessageEntity>();

  MediaFileEntity({
    this.id = 0,
    required this.url,
    required this.publicId,
  });
}