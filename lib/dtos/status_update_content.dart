import 'package:chat/dtos/message_content_base.dart';

class StatusUpdateContent extends MessageContentBase {
  final String messageId;
  final String pubMsgId;
  final String chatId;
  final String pubChatId;
  final String messageStatus;

  StatusUpdateContent({
    required this.messageId,
    required this.pubMsgId,
    required this.chatId,
    required this.pubChatId,
    required this.messageStatus,
  });

  factory StatusUpdateContent.fromJson(Map<String, dynamic> json) {
    return StatusUpdateContent(
      messageId: json['messageId'] ?? '',
      pubMsgId: json['pubMsgId'] ?? '',
      chatId: json['chatId'] ?? '',
      pubChatId: json['pubChatId'] ?? '',
      messageStatus: json['messageStatus'] ?? '',
    );
  }
}
