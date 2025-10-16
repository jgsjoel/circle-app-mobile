import 'package:chat/dtos/message_content.dart';
import 'package:chat/dtos/message_type.dart';
import 'package:chat/dtos/status_update_content.dart';

abstract class MessageContentBase {
  MessageContentBase();

  factory MessageContentBase.fromJson(MessageType type, Map<String, dynamic> json) {
    switch (type) {
      case MessageType.MESSAGE:
        return MessageContent.fromJson(json);
      case MessageType.STATUS_UPDATE:
        return StatusUpdateContent.fromJson(json);
      default:
        throw Exception('Unknown message type');
    }
  }
}
