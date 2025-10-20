import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/message.dart';
import 'package:chat/database/dao/message_dao.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/api_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:isar/isar.dart';

class MessageService {
  final MessageDao _messageDao = getIt<MessageDao>();
  final _dio = ApiService.instance.dio;
  final Isar _isar = getIt<Isar>();

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

  Future<MessageModal> addMessageLocally(String text, ChatDto chatDto) async {
    ChatCollection? chat =
        await _isar.chatCollections
            .filter()
            .idEqualTo(chatDto.id ?? '')
            .findFirst();

    // 1️⃣ If chat doesn't exist, create it
    if (chat == null) {
      chat =
          ChatCollection()
            ..id =
                chatDto.id ?? DateTime.now().millisecondsSinceEpoch.toString()
            ..name = chatDto.name
            ..publicChatId = chatDto.pubChatId
            ..isGroup = chatDto.isGroup ?? false
            ..lastUpdated = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.chatCollections.put(chat!);
      });
    }

    // 2️⃣ Create the message
    final message =
        MessageCollection()
          ..message = text
          ..fromMe = true
          ..timestamp = DateTime.now().millisecondsSinceEpoch
          ..chat.value = chat; // one-to-one link

    // 3️⃣ Save the message and update the chat link
    await _isar.writeTxn(() async {
      print("-----------before saving the message update---------");
      await _isar.messageCollections.put(message);
      await message.chat.save();

      // 🔗 Properly link message to chat
      print("-----------before linking the message---------");
      chat!.messages.add(message);
      await chat.messages.save();

      // 🕓 Update lastUpdated
      print("-----------before last update---------");
      chat.lastUpdated = DateTime.now();
      await _isar.chatCollections.put(chat);
    });

    return message.toModel();
  }

  Future<List<MessageModal>> getMessagesByChatId(String id) async {
    return _messageDao.getMessagesByChat(id);
  }

  Future<void> deleteMessageById(int id) async {
    await _messageDao.deleteMessageById(id);
  }

  Future<void> updateMessageStatus(String msgPubId, String status) async {
    await _messageDao.updateMessageStatus(msgPubId, status);
  }
}
