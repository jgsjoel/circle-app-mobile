import 'dart:async';
import 'dart:convert';
import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/entities/chat_participant.dart';
import 'package:chat/database/entities/contact.dart';
import 'package:chat/database/entities/media_file.dart';
import 'package:chat/database/entities/message.dart';
import 'package:chat/dtos/incomming_messages.dart';
import 'package:chat/dtos/message_content.dart';
import 'package:chat/dtos/message_type.dart';
import 'package:chat/dtos/status_update_content.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:chat/services/webSock_service.dart';
import 'package:chat/services/media_download_service.dart';
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
  Box<ContactEntity> get _contactBox => _store.box<ContactEntity>();

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

  // 📤 Send message status update to server
  Future<void> sendStatusUpdate(String messageId, String status) async {
    try {
      final currentUserId = await SecureStoreService.getPublicUserId();
      
      final statusUpdate = {
        "msg_type": "status",
        "message": {
          "message_id": messageId,
          "updated_by_id": currentUserId,
          "status": status,
        }
      };

      final jsonString = jsonEncode(statusUpdate);
      send(jsonString);
      print("📤 Sent status update: $status for message: $messageId");
    } catch (e) {
      print("❌ Error sending status update: $e");
    }
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
      final msg = (u.messageId != null && u.messageId.isNotEmpty)
    ? _messageBox
        .query(MessageEntity_.messageId.equals(u.messageId))
        .build()
        .findFirst()
    : _messageBox
        .query(MessageEntity_.msgPubId.equals(u.pubMsgId))
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
    final mediaDownloadService = MediaDownloadService.instance;

    for (final content in messages) {
      try {
        final senderId = content.senderId;

        // Create contact for unknown user if needed
        await _ensureContactExists(senderId,content.senderMobile);

        // Find or create chat between users
        ChatEntity? chat = await _findChat(content.pubChatId);
        chat ??= await _createChat(senderId, currentUserId, content.pubChatId);

        // Always mark incoming messages as "received" initially
        // The message screen will upgrade to "read" if the user is viewing the chat
        final messageStatus = "received";
        print("➡️ Setting incoming message status to: $messageStatus for chat: ${chat.publicChatId}");

        // Create message
        final message = MessageEntity(
          messageId: content.messagePubId,
          message: content.message,
          fromMe: false,
          status: messageStatus,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        )..chat.target = chat;

        // Create and download media files
        final mediaFiles = <MediaFileEntity>[];
        for (final media in content.mediaDtoList) {
          // Download and cache the media file
          final localPath = await mediaDownloadService.downloadAndCacheMedia(
            media.url,
            media.publicId,
          );

          final mediaFile = MediaFileEntity(
            source: localPath ?? media.url,  // Use local path if downloaded, otherwise use URL
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

        // Send "received" status update to server so sender sees double tick
        await sendStatusUpdate(content.messagePubId, messageStatus);
        print("✅ Message saved with status: $messageStatus");

      } catch (e, st) {
        print("❌ Error saving incoming message: $e\n$st");
      }
    }
  }

  // 🆕 Ensure contact exists for the given public ID
  Future<void> _ensureContactExists(String publicId,String phone) async {
    // Check if contact already exists
    final existingContact = _contactBox
        .query(ContactEntity_.publicId.equals(publicId))
        .build()
        .findFirst();

    if (existingContact == null) {
      // Create a placeholder contact with public ID as name
      final newContact = ContactEntity(
        name: "${phone} (unknown)",  // Use public ID as temporary name
        phone: phone,  // No phone number available
        publicId: publicId,
      );
      
      _contactBox.put(newContact);
      print("✅ Created placeholder contact for unknown user: $publicId");
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