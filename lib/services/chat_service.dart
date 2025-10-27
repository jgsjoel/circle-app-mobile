import 'package:chat/database/daos/chat_dao.dart'; // Corrected import path
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/database/entities/chat.dart';

class ChatService {
  final ChatObjectBoxDao _chatObjectBoxDao = ChatObjectBoxDao();

  Future<List<ChatDto>> getAllChats() async {
    return _chatObjectBoxDao.watchAllChats().first;
  }

  Future<ChatEntity?> getChatById(int id) async {
    return _chatObjectBoxDao.getChatById(id);
  }

  Future<void> createChat(ChatDto chatDto) async {
    _chatObjectBoxDao.createChat(chatDto);
  }

  Future<bool> deleteChat(int id) async {
    return _chatObjectBoxDao.deleteChat(id);
  }
}
