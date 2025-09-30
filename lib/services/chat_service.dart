import 'package:chat/database/dao/chat_dao.dart';
import 'package:chat/database/dao/chat_participant_dao.dart';
import 'package:chat/database/modals/chat_modal.dart';
import 'package:chat/database/modals/chat_participant_modal.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/api_service.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final ChatDao _chatDao = getIt<ChatDao>();
  final ChatParticipantsDao _chatParticipantsDao = getIt<ChatParticipantsDao>();
  final _dio = ApiService.instance.dio;
  final _uuid = const Uuid();

  /// Create or insert a new chat
  Future<ChatModal> createChat(ChatDto chatDto) async {
      //create new chat
      var chatModal = ChatModal(id: _uuid.v4(), isGroup: false);

      await _chatDao.insertChat(chatModal);

      await _chatParticipantsDao.insertParticipant(ChatParticipantModal(chatId: chatModal.id, contactPublicId: chatDto.publicUserId!));
      String localUserPublicId = await SecureStoreService.getPublicUserId();
      await _chatParticipantsDao.insertParticipant(ChatParticipantModal(chatId: chatModal.id, contactPublicId: localUserPublicId));

      return chatModal;
  }

  /// Get all chats
  Future<List<ChatDto>> getAllChats() async {
    return await _chatDao.getAllChats();
  }

  /// Update chat info (e.g. rename group, update participants)
  Future<void> updateChat(ChatModal chat) async {
    await _chatDao.updateChat(chat);
  }

  /// Delete a chat and cascade messages (thanks to FK in schema)
  Future<void> deleteChat(String id) async {
    await _chatDao.deleteChat(id);
  }

  /// (Optional) Sync chats with server if you add backend support later
  // Future<void> syncChatsWithServer() async {
  //   try {
  //     final response = await _dio.get(
  //       "/chats",
  //       options: Options(extra: {"requiresAuth": true}),
  //     );

  //     // Parse response and save into local DB
  //     // Example: assume response.data is List<Map<String,dynamic>>
  //     final List<dynamic> chatList = response.data;
  //     for (var chatMap in chatList) {
  //       final chat = ChatModal.fromMap(chatMap);
  //       await _chatDao.insertChat(chat);
  //     }
  //   } catch (e) {
  //     print("Failed to sync chats: $e");
  //   }
  // }
}
