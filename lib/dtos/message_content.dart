import 'package:chat/dtos/media.dart';
import 'message_content_base.dart'; // make sure this import exists

class MessageContent extends MessageContentBase {
  final String messagePubId;
  final String message;
  final String senderId;
  final String senderMobile;
  final String pubChatId;
  final List<MediaDto> mediaDtoList;

  MessageContent({
    required this.messagePubId,
    required this.message,
    required this.senderId,
    required this.senderMobile,
    required this.pubChatId,
    required this.mediaDtoList,
  });

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      messagePubId: json['pubMessageId'] ?? '',
      message: json['message'] ?? '',
      senderId: json['senderId'] ?? '',
      senderMobile: json['senderMobile'] ?? '',
      pubChatId: json['pubChatId'] ?? '',
      mediaDtoList: (json['mediaDtoList'] as List?)
              ?.map((item) => MediaDto.fromJson(item))
              .toList() ??
          [],
    );
  }
}
