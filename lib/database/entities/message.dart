import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/entities/media_file.dart';
import 'package:chat/database/db_modals/MediaFileModal.dart' as db;
import 'package:objectbox/objectbox.dart';

@Entity()
class MessageEntity {
  int id;

  String messageId;
  String? msgPubId;
  String message;
  bool fromMe;
  int timestamp;
  String status;

  final chat = ToOne<ChatEntity>();

  @Backlink('message')
  final mediaFiles = ToMany<MediaFileEntity>();

  MessageEntity({
    this.id = 0,
    required this.messageId,
    this.msgPubId,
    required this.message,
    required this.fromMe,
    required this.timestamp,
    required this.status,
  });

  MessageModal toModel() {
    return MessageModal(
      chatId: chat.target?.publicChatId ?? '',
      id: id,
      messageId: messageId,
      msgPubId: msgPubId,
      message: message,
      fromMe: fromMe,
      timestamp: timestamp,
      status: status,
      mediaFiles: mediaFiles
          .map((mediaFile) => db.MediaFile(
                id: mediaFile.id.toString(),
                source: mediaFile.source,
                publicId: mediaFile.publicId,
                messageId: id,
              ))
          .toList(),
    );
  }
}
