import 'dart:async';
import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/entities/chat_participant.dart';
import 'package:chat/database/entities/media_file.dart';
import 'package:chat/database/entities/message.dart';
import 'package:chat/dtos/incomming_messages.dart';
import 'package:chat/dtos/message_content.dart';
import 'package:chat/dtos/message_type.dart';
import 'package:chat/dtos/status_update_content.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:chat/services/webSock_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';
import 'package:chat/objectbox.g.dart';

class WebSocketNotifier extends StateNotifier<WebSocketService?> {
  final Ref ref;
  final Store _store = getIt<Store>();
  
  Box<MessageEntity> get _messageBox => _store.box<MessageEntity>();
  Box<ChatEntity> get _chatBox => _store.box<ChatEntity>();
  Box<MediaFileEntity> get _mediaFileBox => _store.box<MediaFileEntity>();
  Box<ChatParticipantEntity> get _participantBox => _store.box<ChatParticipantEntity>();

  WebSocketNotifier(this.ref) : super(null);

  Stream<String>? get messages => state?.messages;
  StreamSubscription<String>? _subscription;

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
          await _newSaveMessages(incoming);
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

  // 🟢 Update message status directly in ObjectBox
  Future<void> _updateMessageStatus(IncomingMessage incoming) async {
    print("🟢 Updating message status");
    final updates = incoming.content.whereType<StatusUpdateContent>().toList();
    
    for (final u in updates) {
      final msg = _messageBox
          .query(MessageEntity_.messageId.equals(u.messageId))
          .build()
          .findFirst();
          
      if (msg != null) {
        // Update message status and public ID
        msg.status = u.messageStatus;
        msg.msgPubId = u.pubMsgId;
        _messageBox.put(msg);

        // Update chat's public ID if provided
        if (u.pubChatId.isNotEmpty) {
          final chat = msg.chat.target;
          if (chat != null && (chat.publicChatId?.isEmpty ?? true)) {
            chat.publicChatId = u.pubChatId;
            _chatBox.put(chat);
            print("✅ Updated chat public ID to: ${u.pubChatId}");
          }
        }
      }
    }
  }

  // 💾 Save new incoming messages
  Future<void> _newSaveMessages(IncomingMessage incoming) async {
    final messages = incoming.content.whereType<MessageContent>().toList();
    final currentUserId = await SecureStoreService.getPublicUserId();

    for (final content in messages) {
      try {
        final senderId = content.senderId;

        // Find or create chat between users
        ChatEntity? chat = await _findChat(content.pubChatId);
        chat ??= await _createChat(senderId, currentUserId, content.pubChatId);

        // Create message
        final message = MessageEntity(
          messageId: content.messagePubId,
          message: content.message,
          fromMe: false,
          status: "received",
          timestamp: DateTime.now().millisecondsSinceEpoch,
        )..chat.target = chat;

        // Create media files
        final mediaFiles = <MediaFileEntity>[];
        for (final media in content.mediaDtoList) {
          final mediaFile = MediaFileEntity(
            url: media.url,
            publicId: media.publicId,
          )..message.target = message;
          mediaFiles.add(mediaFile);
        }

        // Save message
        _messageBox.put(message);

        // Save media files
        if (mediaFiles.isNotEmpty) {
          _mediaFileBox.putMany(mediaFiles);
          message.mediaFiles.addAll(mediaFiles);
        }

        // Update chat
        chat.messages.add(message);
        chat.lastUpdated = DateTime.now();
        _chatBox.put(chat);

      } catch (e, st) {
        print("❌ Error saving incoming message: $e\n$st");
      }
    }
  }

  // 🧩 Find an existing chat by publicChatId
  Future<ChatEntity?> _findChat(String? publicChatId) async {
    if (publicChatId == null) return null;
    return _chatBox
        .query(ChatEntity_.publicChatId.equals(publicChatId))
        .build()
        .findFirst();
  }

  // 🆕 Create a new chat with both participants
  Future<ChatEntity> _createChat(
    String senderId,
    String receiverId,
    String? pubChatId,
  ) async {
    final chat = ChatEntity(
      publicChatId: pubChatId ?? '',
      isGroup: false,
      lastUpdated: DateTime.now(),
      name: '',
    );

    final sender = ChatParticipantEntity(
      contactPublicId: senderId,
    )..chat.target = chat;

    final receiver = ChatParticipantEntity(
      contactPublicId: receiverId,
    )..chat.target = chat;

    _chatBox.put(chat);
    _participantBox.putMany([sender, receiver]);
    chat.participants.addAll([sender, receiver]);
    _chatBox.put(chat);

    return chat;
  }
}

final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketService?>(
      (ref) => WebSocketNotifier(ref),
    );