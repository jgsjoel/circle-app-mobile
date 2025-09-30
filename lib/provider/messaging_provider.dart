import 'package:chat/database/modals/chat_modal.dart';
import 'package:chat/database/modals/message_modal.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/provider/chats_screen_provider.dart';
import 'package:chat/services/chat_service.dart';
import 'package:chat/services/message_serivce.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageNotifier extends StateNotifier<List<MessageModal>> {
  final Ref ref; // Add this

  MessageNotifier(this.ref) : super([]);

  final MessageService _messageService = getIt<MessageService>();
  final ChatService _chatService = getIt<ChatService>();

  Future<void> loadMessages(String chatId) async {
    final messages = await _messageService.getMessagesByChatId(chatId);
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

    // 6️⃣ Update messages state
    state = [...state, messageModal];
  }

  void clear() => state = [];
}

final messageProvider =
    StateNotifierProvider<MessageNotifier, List<MessageModal>>((ref) {
      return MessageNotifier(ref);
    });
