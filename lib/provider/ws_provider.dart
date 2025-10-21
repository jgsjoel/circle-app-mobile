import 'dart:async';
import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/chat_participant.dart';
import 'package:chat/database/collections/media_file.dart';
import 'package:chat/database/collections/message.dart';
import 'package:chat/dtos/incomming_messages.dart';
import 'package:chat/dtos/message_content.dart';
import 'package:chat/dtos/message_type.dart';
import 'package:chat/dtos/status_update_content.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:chat/services/webSock_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

class WebSocketNotifier extends StateNotifier<WebSocketService?> {
  final Ref ref;
  WebSocketNotifier(this.ref) : super(null);

  Stream<String>? get messages => state?.messages;
  StreamSubscription<String>? _subscription;
  final _uuid = const Uuid();
  final isar = getIt<Isar>();

  // 🔌 Connect WebSocket and listen to messages
  Future<void> connect() async {
    final service = WebSocketService();
    await service.connect();
    state = service;

    _subscription = service.messages.listen(_handleMessage);
  }

  void send(String message) => state?.send(message);

  void disconnect() {
    _subscription?.cancel();
    state?.close();
    state = null;
  }

  // 🔄 Handle incoming messages
  Future<void> _handleMessage(String msg) async {
    try {
      final incoming = IncomingMessage.fromRawJson(msg);

      switch (incoming.type) {
        case MessageType.MESSAGE:
          await _saveMessages(incoming);
          break;
        case MessageType.STATUS_UPDATE:
          await _updateMessageStatus(incoming);
          break;
        default:
          print("⚠️ Unknown incoming message type: ${incoming.type}");
      }
    } catch (e, st) {
      print("❌ Error in _handleMessage: $e\n$st");
    }
  }

  // 🟢 Update message status directly in Isar
  Future<void> _updateMessageStatus(IncomingMessage incoming) async {
    final updates = incoming.content.whereType<StatusUpdateContent>().toList();

    await isar.writeTxn(() async {
      for (final u in updates) {
        final msg =
            await isar.messageCollections
                .filter()
                .messageIdEqualTo(u.messageId)
                .findFirst();
        if (msg != null) {
          msg.status = u.messageStatus;
          msg.msgPubId = u.pubMsgId;
          await isar.messageCollections.put(msg);
        }
      }
    });
  }

  // 💾 Save new incoming messages
  Future<void> _saveMessages(IncomingMessage incoming) async {
    final messages = incoming.content.whereType<MessageContent>().toList();
    final currentUserId = await SecureStoreService.getPublicUserId();

    for (final content in messages) {
      try {
        final senderId = content.senderId;

        // Find or create chat between users
        ChatCollection? chat = await _findChatBetween(currentUserId, senderId);
        chat ??= await _createChat(senderId, currentUserId, content.pubChatId);

        // Create message collection
        final message =
            MessageCollection()
              ..msgPubId = content.messagePubId
              ..message = content.message
              ..fromMe = false
              ..status = "received"
              ..timestamp = DateTime.now().millisecondsSinceEpoch
              ..chat.value = chat;

        // Create media collections (if any)
        final mediaCollections = <MediaFileCollection>[];
        for (final media in content.mediaDtoList) {
          final mediaFile =
              MediaFileCollection()
                ..id = _uuid.v4()
                ..url = media.url
                ..publicId = media.publicId
                ..message.value = message; // Link media to message (1-to-1)
          mediaCollections.add(mediaFile);
        }

        // Link message to media files (forward link, 1-to-many)
        message.mediaFiles.addAll(mediaCollections);

        // Save everything atomically
        await isar.writeTxn(() async {
          // 1. Save the message
          await isar.messageCollections.put(message);
          await message.chat.save(); // Save message's link to chat

          // 2. Save media files and their links
          if (mediaCollections.isNotEmpty) {
            await isar.mediaFileCollections.putAll(mediaCollections);
            for (final mediaFile in mediaCollections) {
              await mediaFile.message.save(); // Save media's link to message
            }
            
            // 🚨 CRITICAL FIX: Persist the message's link to the media files
            // This is the link that MessageScreen.watchMessages depends on.
            await message.mediaFiles.save(); 
          }

          // 3. Update chat (Crucial for Chatstab update)
          // Link message to chat (forward link)
          chat!.messages.add(message);
          await chat.messages.save();

          // Update lastUpdated (Triggers chat stream for unread count/sorting)
          chat.lastUpdated = DateTime.now();
          await isar.chatCollections.put(chat);

          // NOTE: The two lines below were duplicates and have been removed for efficiency.
          // chat!.messages.add(message);
          // await chat.messages.save();
        });
      } catch (e, st) {
        print("❌ Error saving incoming message: $e\n$st");
      }
    }
  }

  // 🧩 Find an existing chat between two users
  Future<ChatCollection?> _findChatBetween(String userA, String userB) async {
    final chats = await isar.chatCollections.where().findAll();

    for (final chat in chats) {
      await chat.participants.load();
      final participantIds =
          chat.participants.map((p) => p.contactPublicId).toSet();
      if (participantIds.contains(userA) && participantIds.contains(userB)) {
        return chat;
      }
    }
    return null;
  }

  // 🆕 Create a new chat with both participants
  Future<ChatCollection> _createChat(
    String senderId,
    String receiverId,
    String? pubChatId,
  ) async {
    final chat =
        ChatCollection()
          ..id = _uuid.v4()
          ..isGroup = false
          ..publicChatId = pubChatId;

    final sender =
        ChatParticipantCollection()
          ..contactPublicId = senderId
          ..chat.value = chat;
    final receiver =
        ChatParticipantCollection()
          ..contactPublicId = receiverId
          ..chat.value = chat;

    await isar.writeTxn(() async {
      await isar.chatCollections.put(chat);
      await isar.chatParticipantCollections.putAll([sender, receiver]);
      await sender.chat.save();
      await receiver.chat.save();
    });

    return chat;
  }
  
  // 🗑️ The original _saveMediaFiles function is now unused/redundant
  // and has been removed for code clarity, as its logic is now merged
  // into the main _saveMessages function.
}

final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketService?>(
      (ref) => WebSocketNotifier(ref),
    );