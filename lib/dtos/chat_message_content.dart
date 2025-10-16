import 'package:chat/dtos/media.dart';
import 'package:chat/dtos/message_content_base.dart';

class ChatMessageContent extends MessageContentBase {
  final String pubMessageId;
  final String message;
  final String senderId;
  final String senderMobile;
  final String pubChatId;
  final List<MediaDto> mediaDtoList;

  ChatMessageContent({
    required this.pubMessageId,
    required this.message,
    required this.senderId,
    required this.senderMobile,
    required this.pubChatId,
    required this.mediaDtoList,
  });

  factory ChatMessageContent.fromJson(Map<String, dynamic> json) {
    return ChatMessageContent(
      pubMessageId: json['pubMessageId'] ?? '',
      message: json['message'] ?? '',
      senderId: json['senderId'] ?? '',
      senderMobile: json['senderMobile'] ?? '',
      pubChatId: json['pubChatId'] ?? '',
      mediaDtoList: (json['mediaDtoList'] as List?)
              ?.map((e) => MediaDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}
