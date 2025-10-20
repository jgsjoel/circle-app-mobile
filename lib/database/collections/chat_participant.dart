import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/db_modals/chat_participant_modal.dart';
import 'package:isar/isar.dart';

part 'chat_participant.g.dart';

@Collection()
class ChatParticipantCollection {
  Id id = Isar.autoIncrement;

  late String contactPublicId;
  final chat = IsarLink<ChatCollection>();

  ChatParticipantCollection();

  ChatParticipantCollection copyWith({
    Id? id,
    String? contactPublicId,
  }) {
    return ChatParticipantCollection()
      ..id = id ?? this.id
      ..contactPublicId = contactPublicId ?? this.contactPublicId;
  }

  ChatParticipantModal toModel() {
    // The chatId for the old model is a String, which we get from the linked ChatCollection.
    final chatValue = chat.value;
    return ChatParticipantModal(
      id: id,
      chatId: chatValue?.id ?? '',
      contactPublicId: contactPublicId,
    );
  }

  factory ChatParticipantCollection.fromModel(ChatParticipantModal model) {
    return ChatParticipantCollection()
      ..id = model.id ?? Isar.autoIncrement
      ..contactPublicId = model.contactPublicId;
    // The `chat` IsarLink must be associated separately after creation.
  }
}