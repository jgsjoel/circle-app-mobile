import 'package:chat/dtos/message_content_base.dart';

class UnknownContent extends MessageContentBase {
  final Map<String, dynamic> raw;

  UnknownContent({required this.raw});

  factory UnknownContent.fromJson(Map<String, dynamic> json) {
    return UnknownContent(raw: Map<String, dynamic>.from(json));
  }

  @override
  String toString() => 'UnknownContent(raw: $raw)';
}
