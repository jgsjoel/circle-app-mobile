import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/entities/media_file.dart';
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
    );
  }
}
