import 'dart:convert';

import 'package:chat/database/modals/chat_modal.dart';
import 'package:chat/database/modals/message_modal.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/provider/chats_screen_provider.dart';
import 'package:chat/provider/ws_provider.dart';
import 'package:chat/services/chat_service.dart';
import 'package:chat/services/message_serivce.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageNotifier extends StateNotifier<List<MessageModal>> {
  final Ref ref; // Add this

  MessageNotifier(this.ref) : super([]);

  final MessageService _messageService = getIt<MessageService>();
  final ChatService _chatService = getIt<ChatService>();

  Future<void> loadMessages(String chatId) async {
    final messages = await _messageService.getMessagesByChatId(chatId);
    print("chatId: $chatId");
    int count = messages.length;
    print("message count: $count");
    state = messages;
  }

  // void addMessage(String text, ChatDto chatDto) async {
  //   final pubChatId = chatDto.pubChatId ?? '';
  //   final id = chatDto.id ?? '';

  //   MessageModal messageModal;

  //   if (pubChatId.isEmpty && id.isEmpty) {
  //     // Create chat if it doesn't exist
  //     ChatModal chatModal = await _chatService.createChat(chatDto);
  //     chatDto.id = chatModal.id;
  //     chatDto.pubChatId = chatModal.publicChatId;
  //     messageModal = await _messageService.saveMessage(text, chatModal.id);

  //     //add new chatDto to chat screen notifier state

  //   } else {
  //     messageModal = await _messageService.saveMessage(text, id);
  //   }

  //   state = [...state, messageModal];

  //   // update lastMessage in ChatScreenNotifier
  //   final updatedChat = chatDto.copyWith(lastMessage: messageModal.message);

  //   // access chatScreenProvider and update state
  //   ref.read(chatScreenProvider.notifier).updateChat(updatedChat);
  // }

  void addMessage(String text, ChatDto chatDto) async {
    final pubChatId = chatDto.pubChatId ?? '';
    final id = chatDto.id ?? '';

    MessageModal messageModal;

    if (pubChatId.isEmpty && id.isEmpty) {
      // 1️⃣ Create chat if it doesn't exist
      ChatModal chatModal = await _chatService.createChat(chatDto);
      chatDto.id = chatModal.id;
      chatDto.pubChatId = chatModal.publicChatId;

      // 2️⃣ Save the message
      messageModal = await _messageService.saveMessage(text, chatModal.id);

      // 3️⃣ Add new chatDto to ChatScreenNotifier with lastMessage & time
      final newChatDto = chatDto.copyWith(
        id: chatModal.id,
        lastMessage: messageModal.message,
        time:
            messageModal.timestamp
                .toString(), // assuming MessageModal has timestamp as String
      );

      ref.read(chatScreenProvider.notifier).addChat(newChatDto);
    } else {
      // 4️⃣ Existing chat: save message
      messageModal = await _messageService.saveMessage(text, id);

      // 5️⃣ Update lastMessage and time in ChatScreenNotifier
      final updatedChat = chatDto.copyWith(
        lastMessage: messageModal.message,
        time: messageModal.timestamp.toString(),
      );
      ref.read(chatScreenProvider.notifier).updateChat(updatedChat);
    }

    sendToServer(messageModal,chatDto);

    // 6️⃣ Update messages state
    state = [...state, messageModal];
  }

  Future<void> sendToServer(MessageModal messageModal, ChatDto chatDto, {List<Map<String, String>>? mediaList}) async {
  final webSocketNotifier = ref.read(webSocketProvider.notifier);

  // Ensure chat ID and receiver ID are resolved
  final chatId = chatDto.id ?? "";
  final receiverId = chatDto.publicUserId ?? "";
  final senderId = await SecureStoreService.getPublicUserId();

  final Map<String, dynamic> messageJson = {
    "msg_type": "message",
    "message": {
      "message_id": messageModal.id,
      "message": messageModal.message,
      "chat_id": chatId,
      "sender_id": senderId,
      "receiver_id": receiverId,
      "sender_timestamp": DateTime.now().toUtc().toIso8601String(),
      "message_type": mediaList != null && mediaList.isNotEmpty ? "MEDIA" : "TEXT",
      "media_list": mediaList ?? []
    }
  };

  final String jsonString = jsonEncode(messageJson);
  webSocketNotifier.send(jsonString);
  print("📤 Sent message to server: $jsonString");
}


  void clear() => state = [];

  /// Add an incoming message to the current chat's message list
  void addIncomingMessage(MessageModal message) {
    // Only add if the message belongs to the currently loaded chat
    if (state.isNotEmpty && state.first.chatId == message.chatId) {
      state = [...state, message];
      print("📩 Added incoming message to current chat: ${message.message}");
    } else {
      print("📩 Incoming message for different chat: ${message.chatId}");
    }
  }

  /// Check if a specific chat is currently being viewed
  bool isChatCurrentlyViewed(String chatId) {
    return state.isNotEmpty && state.first.chatId == chatId;
  }

  /// Get the currently loaded chat ID
  String? getCurrentChatId() {
    return state.isNotEmpty ? state.first.chatId : null;
  }
}

final messageProvider =
    StateNotifierProvider<MessageNotifier, List<MessageModal>>((ref) {
      return MessageNotifier(ref);
    });
