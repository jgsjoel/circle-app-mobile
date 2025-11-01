import 'dart:convert';

import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/entities/message.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';
import 'package:chat/objectbox.g.dart'; // Importing generated query properties

class MessageDao {
  final Store _store = getIt<Store>();
  final _uuid = const Uuid();

  Box<MessageEntity> get _messageBox => _store.box<MessageEntity>();
  Box<ChatEntity> get _chatBox => _store.box<ChatEntity>();

  MessageModal saveMessage(
    String chatId,
    String message, {
    bool fromMe = true,
    String? msgPubId,
    String status = 'sending',
  }) {
    final chat = _chatBox.query(ChatEntity_.id.equals(int.parse(chatId))).build().findFirst();
    if (chat == null) throw Exception("Chat not found: $chatId");

    final msg = MessageEntity(
      messageId: _uuid.v4(),
      msgPubId: msgPubId,
      message: message,
      fromMe: fromMe,
      status: status,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    )..chat.target = chat;

    _messageBox.put(msg);
    return msg.toModel();
  }

  List<MessageEntity> getMessagesByChatId(int chatId) {
    final chat = _chatBox.query(ChatEntity_.id.equals(chatId)).build().findFirst();
    if (chat == null) return [];

    final messages = chat.messages.toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  void deleteMessage(int id) {
    _messageBox.remove(id);
  }

  List<MessageEntity> markMessagesAsRead(String chatId) {
    final chat = _chatBox.query(ChatEntity_.id.equals(int.parse(chatId))).build().findFirst();
    if (chat == null) return [];

    final receivedMessages = chat.messages.where((m) => m.status == 'received').toList();
    if (receivedMessages.isEmpty) return [];

    for (final message in receivedMessages) {
      message.status = 'read';
    }
    _messageBox.putMany(receivedMessages);

    chat.lastUpdated = DateTime.now();
    _chatBox.put(chat);

    return receivedMessages;
  }

  Stream<List<MessageModal>> watchMessages(String chatId) {
    print("🔍 Watching messages for chat: $chatId");
    return _messageBox
        .query(MessageEntity_.chat.equals(int.parse(chatId)))
        .watch(triggerImmediately: true)
        .map((query) {
          final messages = query.find();
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          // Add logging for media files
          for (var message in messages) {
            if (message.mediaFiles.isNotEmpty) {
              print("📦 Message ${message.messageId} has ${message.mediaFiles.length} media files in database");
              for (var mediaFile in message.mediaFiles) {
                print("   - Source: ${mediaFile.source}");
                print("   - Public ID: ${mediaFile.publicId}");
              }
            }
          }
          
          return messages.map((e) => e.toModel()).toList();
        });
  }

  MessageEntity createMessage(String text, ChatEntity chat) {
    final message = MessageEntity(
      messageId: _uuid.v4(),
      message: text,
      fromMe: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: 'sending',
    )..chat.target = chat;

    _messageBox.put(message);
    chat.messages.add(message);
    _chatBox.put(chat);

    return message;
  }

  void updateMessage(MessageEntity message) {
    _messageBox.put(message);
  }

  MessageEntity? getMessageByMessageId(String messageId) {
    return _messageBox
        .query(MessageEntity_.messageId.equals(messageId))
        .build()
        .findFirst();
  }
}
