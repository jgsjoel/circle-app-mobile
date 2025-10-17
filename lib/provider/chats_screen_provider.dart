// Provider for ChatDao
import 'package:chat/database/dao/chat_dao.dart';
import 'package:chat/database/dao/chat_participant_dao.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatDaoProvider = Provider<ChatDao>((ref) => getIt<ChatDao>());
final chatParticipantsDao = Provider<ChatParticipantsDao>(
  (ref) => getIt<ChatParticipantsDao>(),
);

// StateNotifier
class ChatScreenNotifier extends StateNotifier<List<ChatDto>> {
  final ChatDao _chatDao;

  ChatScreenNotifier(this._chatDao) : super([]) {
    loadChats();
  }

  Future<void> loadChats() async {
    final chatDtos = await _chatDao.getAllChats();
    state = chatDtos;
  }

  void addChat(ChatDto chatDto) => state = [...state, chatDto];

  void updateChat(ChatDto updatedChat) {
    final updatedList = [
      for (final chat in state)
        if (chat.id == updatedChat.id) updatedChat else chat,
    ];
    _sortChatsByTime(updatedList);
    state = updatedList;
    print("----last message: ${state.first.lastMessage}");
  }

  void _sortChatsByTime(List<ChatDto> chats) {
    chats.sort((a, b) {
      final aTime = int.tryParse(a.time ?? '') ?? 0;
      final bTime = int.tryParse(b.time ?? '') ?? 0;
      return bTime.compareTo(aTime);
    });
  }

  /// Update chat with new incoming message
  void updateChatWithNewMessage(String chatId, String lastMessage, String timestamp) {
    final updatedList = [
      for (final chat in state)
        if (chat.id == chatId) 
          chat.copyWith(
            lastMessage: lastMessage,
            time: timestamp,
            messageCount: (chat.messageCount ?? 0) + 1,
          )
        else chat,
    ];
    _sortChatsByTime(updatedList);
    state = updatedList;
    print("📩 Updated chat list with new message for chat: $chatId");
  }

  /// Force refresh the chat list from database
  Future<void> refreshChats() async {
    print("🔄 Refreshing chat list from database");
    await loadChats();
  }

  /// Remove a specific chat from the list
  void removeChat(String chatId) {
    final updatedList = state.where((chat) => chat.id != chatId).toList();
    state = updatedList;
    print("🗑️ Removed chat from list: $chatId");
  }
}

// Provider for the notifier
final chatScreenProvider =
    StateNotifierProvider<ChatScreenNotifier, List<ChatDto>>(
      (ref) => ChatScreenNotifier(ref.read(chatDaoProvider)),
    );
