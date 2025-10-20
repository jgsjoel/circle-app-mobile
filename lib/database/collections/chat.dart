import 'package:chat/database/collections/chat_participant.dart';
import 'package:chat/database/collections/message.dart';
import 'package:chat/database/db_modals/chat_modal.dart';
import 'package:isar/isar.dart';

part 'chat.g.dart';

@Collection()
class ChatCollection {
  Id? isarId;

  late String id;
  String? name;
  String? publicChatId;
  late bool isGroup;

  // ✅ Always initialize this safely to avoid LateInitializationError
  @Index()
  DateTime lastUpdated = DateTime.now();

  final messages = IsarLinks<MessageCollection>();
  final participants = IsarLinks<ChatParticipantCollection>();

  ChatCollection();

  ChatCollection copyWith({
    Id? isarId,
    String? id,
    String? name,
    String? publicChatId,
    bool? isGroup,
    DateTime? lastUpdated,
  }) {
    return ChatCollection()
      ..isarId = isarId ?? this.isarId
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..publicChatId = publicChatId ?? this.publicChatId
      ..isGroup = isGroup ?? this.isGroup
      ..lastUpdated = lastUpdated ?? this.lastUpdated;
  }

  ChatModal toModel() {
    return ChatModal(
      id: id,
      name: name,
      isGroup: isGroup,
      publicChatId: publicChatId,
    );
  }

  factory ChatCollection.fromModel(ChatModal model) {
    return ChatCollection()
      ..id = model.id
      ..name = model.name
      ..isGroup = model.isGroup
      ..publicChatId = model.publicChatId
      ..lastUpdated = DateTime.now();
  }
}
