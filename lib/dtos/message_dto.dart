class MessageDto {
  final String id;
  final String text;
  final bool isMe;
  final int timestamp;

  MessageDto({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp
  });
}