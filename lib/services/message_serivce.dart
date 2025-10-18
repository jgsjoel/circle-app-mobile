import 'package:chat/database/dao/message_dao.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/services/api_service.dart';
import 'package:chat/services/service_locator.dart';

class MessageService {
  final MessageDao _messageDao = getIt<MessageDao>();
  final _dio = ApiService.instance.dio;

  Future<MessageModal> saveMessage(
    String message,
    String chatId, {
    String? msgPubId,
  }) async { 
    final messageModal = MessageModal(
      msgPubId: msgPubId,
      message: message,
      fromMe: true,
      chatId: chatId,
      status: "pending",
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final int id = await _messageDao.insertMessage(messageModal);
    final savedMessage = messageModal..id = id;

    return savedMessage;
  }

  Future<List<MessageModal>> getMessagesByChatId(String id) async{
    return _messageDao.getMessagesByChat(id);
  }

  Future<void> deleteMessageById(int id) async {
    await _messageDao.deleteMessageById(id);
  }

  Future<void> updateMessageStatus(String msgPubId, String status) async {
    await _messageDao.updateMessageStatus(msgPubId, status);
  }
}
