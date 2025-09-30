class ChatModal {
  final String id;
  final String? publicChatId;
  final bool isGroup;
  final String? name;

  ChatModal({
    required this.id,
    this.publicChatId,
    required this.isGroup,
    this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'public_chat_id': publicChatId,
      'is_group': isGroup ? 1 : 0,
      'name':name,
    };
  }

  factory ChatModal.fromMap(Map<String, dynamic> map) {
    return ChatModal(
      id: map['id'],
      publicChatId: map['public_chat_id'],
      isGroup: map['is_group'] == 1,
      name:map['name']
    );
  }
}

