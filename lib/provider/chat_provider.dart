import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/service_locator.dart';
import 'package:chat/database/daos/chat_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedChatProvider = StreamProvider.family<ChatDto, String>((ref, chatId) {
  final chatDao = getIt<ChatObjectBoxDao>();
  return chatDao.watchAllChats().map((chats) {
    return chats.firstWhere(
      (chat) => chat.id == chatId,
      orElse: () => ChatDto(
        id: chatId,
        name: 'Unknown',
        isGroup: false,
        pubChatId: '',
        publicUserId: '',
      ),
    );
  });
});