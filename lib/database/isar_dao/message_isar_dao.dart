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

  Future<void> markMessagesAsRead(String chatId) async {
    // 1. Find the ChatCollection using the external ID
    final chat =
        await _isar.chatCollections.filter().idEqualTo(chatId).findFirst();

    if (chat == null) return;

    // 2. Load the messages link
    await chat.messages.load();

    // 3. Filter for received messages
    final receivedMessages =
        chat.messages.where((m) => m.status == 'received').toList();

    if (receivedMessages.isEmpty) return;

    // 4. Update the status and perform a transaction to save changes
    await _isar.writeTxn(() async {
      for (final message in receivedMessages) {
        message.status = 'read';
      }
      // Put all updated messages back into the database
      await _isar.messageCollections.putAll(receivedMessages);

      // 🚨 CRITICAL FIX: Explicitly update the ChatCollection 🚨
      // This modification forces the chatCollections.watch() stream to fire.
      chat.lastUpdated = DateTime.now();
      await _isar.chatCollections.put(chat);
      // 🚨 END CRITICAL FIX
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
