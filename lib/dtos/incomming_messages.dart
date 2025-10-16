import 'dart:convert';
import 'package:chat/dtos/message_content_base.dart';
import 'package:chat/dtos/message_type.dart';

class IncomingMessage<T extends MessageContentBase> {
  final MessageType type;
  final List<T> content;

  IncomingMessage({
    required this.type,
    required this.content,
  });

  factory IncomingMessage.fromJson(Map<String, dynamic> json) {
    final type = MessageType.fromString(json['type']);
    final rawContent = json['content'];

    List<T> parsedContent = [];

    if (rawContent is List) {
      parsedContent = rawContent
          .map((e) => MessageContentBase.fromJson(type, e) as T)
          .toList();
    } else if (rawContent is Map<String, dynamic>) {
      parsedContent = [MessageContentBase.fromJson(type, rawContent) as T];
    } else {
      throw const FormatException('Invalid content format');
    }

    return IncomingMessage(
      type: type,
      content: parsedContent,
    );
  }

  static IncomingMessage fromRawJson(String rawJson) {
    return IncomingMessage.fromJson(jsonDecode(rawJson));
  }
}
