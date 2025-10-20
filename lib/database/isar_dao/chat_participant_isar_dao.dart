import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/chat_participant.dart';
import 'package:chat/services/service_locator.dart';
import 'package:isar/isar.dart';

class ChatParticipantIsarDao {
  final Isar _isar = getIt<Isar>();

  Future<void> saveParticipant(
      ChatParticipantCollection participant, ChatCollection chat) async {
    await _isar.writeTxn(() async {
      await _isar.chatParticipantCollections.put(participant);
      participant.chat.value = chat;
      await participant.chat.save();
    });
  }

  Future<List<ChatParticipantCollection>> getParticipantsForChat(int chatIsarId) async {
    return await _isar.chatParticipantCollections
        .filter()
        .chat((q) => q.isarIdEqualTo(chatIsarId))
        .findAll();
  }
}