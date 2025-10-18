class ChatParticipantModal {
  final int? id;
  final String chatId;
  final String contactPublicId;

  ChatParticipantModal({
    this.id,
    required this.chatId,
    required this.contactPublicId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'contact_public_id': contactPublicId,
    };
  }

  factory ChatParticipantModal.fromMap(Map<String, dynamic> map) {
    return ChatParticipantModal(
      id: map['id'],
      chatId: map['chat_id'],
      contactPublicId: map['contact_public_id'],
    );
  }
}
