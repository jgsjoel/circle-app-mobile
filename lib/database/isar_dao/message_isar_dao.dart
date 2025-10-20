import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/message.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/services/service_locator.dart';
import 'package:isar/isar.dart';

class MessageIsarDao {
  final Isar _isar = getIt<Isar>();

  /// Save a new message for a chat
  Future<MessageModal> saveMessage(
    String chatId,
    String message, {
    bool fromMe = true,
    String? msgPubId,
    String? status,
  }) async {
    final chat =
        await _isar.chatCollections.filter().idEqualTo(chatId).findFirst();
    if (chat == null) throw Exception("Chat not found: $chatId");

    final msg =
        MessageCollection()
          ..msgPubId = msgPubId
          ..message = message
          ..fromMe = fromMe
          ..status = status
          ..timestamp = DateTime.now().millisecondsSinceEpoch;

    msg.chat.value = chat;

    await _isar.writeTxn(() async {
      await _isar.messageCollections.put(msg);
      await msg.chat.save();
    });

    return msg.toModel();
  }

  /// Get all messages for a chat sorted by timestamp ascending
  Future<List<MessageModal>> getMessagesByChat(String chatId) async {
    final chat =
        await _isar.chatCollections.filter().idEqualTo(chatId).findFirst();
    if (chat == null) return [];

    await chat.messages.load();
    final sorted =
        chat.messages.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted.map((e) => e.toModel()).toList();
  }

  /// Delete message by ID
  Future<void> deleteMessage(int id) async {
    await _isar.writeTxn(() async {
      await _isar.messageCollections.delete(id);
    });
  }

  /// Live stream messages for a chat
  Stream<List<MessageModal>> watchMessages(String chatId) {
    return _isar.messageCollections
        .filter()
        .chat((q) => q.idEqualTo(chatId))
        .watch(fireImmediately: true)
        .asyncMap((messages) async {
          final sorted =
              messages.toList()
                ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // load media for all messages
          for (final msg in sorted) {
            await msg.mediaFiles.load();
          }

          return sorted.map((e) => e.toModel()).toList();
        });
  }
}
