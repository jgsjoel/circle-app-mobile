class MessageModal {
  int? id;
  final String? msgPubId;
  final String message;
  final bool fromMe;
  final String chatId;
  final String? status;
  final int timestamp;

  MessageModal({
    this.id,
    this.msgPubId,
    required this.message,
    required this.fromMe,
    required this.chatId,
    this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'msg_pub_id': msgPubId,
      'message': message,
      'from_me': fromMe ? 1 : 0,
      'chat_id': chatId,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory MessageModal.fromMap(Map<String, dynamic> map) {
    return MessageModal(
      id: map['id'] as int?,
      msgPubId: map['msg_pub_id'] as String?,
      message: map['message'] as String,
      fromMe: (map['from_me'] as int) == 1,
      chatId: map['chat_id'] as String,
      status: map['status'] as String?,
      timestamp: map['timestamp'] as int,
    );
  }
}
