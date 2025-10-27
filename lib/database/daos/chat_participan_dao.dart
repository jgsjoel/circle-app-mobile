import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/entities/chat_participant.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:objectbox/objectbox.dart';
import 'package:chat/objectbox.g.dart'; // Importing generated query properties

class ChatParticipantObjectBoxDao {
  final Store _store = getIt<Store>();

  Box<ChatParticipantEntity> get _participantBox => _store.box<ChatParticipantEntity>();
  Box<ChatEntity> get _chatBox => _store.box<ChatEntity>();

  void saveParticipant(ChatParticipantEntity participant, ChatEntity chat) {
    participant.chat.target = chat;
    _participantBox.put(participant);
  }

  List<ChatParticipantEntity> getParticipantsForChat(int chatId) {
    return _participantBox.query(ChatParticipantEntity_.chat.equals(chatId)).build().find();
  }

  Future<void> addParticipants(ChatEntity chat, ChatDto dto) async {
    final participants = <ChatParticipantEntity>[];

    // Other participant
    if (dto.publicUserId != null) {
      participants.add(ChatParticipantEntity(contactPublicId: dto.publicUserId!)
        ..chat.target = chat);
    }

    // Myself
    final myPublicId = await SecureStoreService.getPublicUserId();
    participants.add(ChatParticipantEntity(contactPublicId: myPublicId)
      ..chat.target = chat);

    _participantBox.putMany(participants);
    chat.participants.addAll(participants);
    _chatBox.put(chat);
  }
}