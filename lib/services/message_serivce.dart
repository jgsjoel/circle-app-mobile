import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/database/daos/chat_dao.dart';
import 'package:chat/database/daos/chat_participan_dao.dart';
import 'package:chat/database/daos/media_file_dao.dart';
import 'package:chat/database/daos/message_dao.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/models/media_selection.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';

class MessageService {
  final ChatObjectBoxDao _chatDao = getIt<ChatObjectBoxDao>();
  final ChatParticipantObjectBoxDao _participantDao = getIt<ChatParticipantObjectBoxDao>();
  final MessageDao _messageDao = getIt<MessageDao>();
  final MediaFileObjectBoxDao _mediaFileDao = getIt<MediaFileObjectBoxDao>();

  Future<MessageModal> addMessageLocally(String text, ChatDto chatDto) async {
    // 1️⃣ Find or create chat
    ChatEntity? chat = _chatDao.getChatById(chatDto.id != null ? int.parse(chatDto.id!) : 0);
    if (chat == null) {
      chat = _chatDao.createChat(chatDto);
      _participantDao.addParticipants(chat, chatDto);
    }

    // 2️⃣ Create message
    final message = _messageDao.createMessage(text, chat);

    // 3️⃣ Update chat timestamp
    _chatDao.updateLastUpdated(chat);

    return message.toModel();
  }

  Future<Map<String, dynamic>> handleMediaSelected(
    List<MediaFile> mediaFiles,
    ChatDto chatDto,
  ) async {
    final myPublicId = await SecureStoreService.getPublicUserId();
    final receiverPublicId = chatDto.publicUserId;

    if (receiverPublicId == null) {
      print("❌ Cannot send message: receiver ID missing.");
      return {'error': 'Receiver ID missing', 'success': false};
    }

    // 1️⃣ Find or create chat
    ChatEntity? chat = _chatDao.getChatById(int.parse(chatDto.id ?? '0'));
    if (chat == null) {
      chat = _chatDao.createChat(chatDto);
      _participantDao.addParticipants(chat, chatDto);
    }

    // 2️⃣ Create message (empty text or media caption)
    final message = _messageDao.createMessage(
      mediaFiles.first.caption ?? '',
      chat,
    );

    // 3️⃣ Link media files to message
    _mediaFileDao.saveMediaFiles(mediaFiles, message);

    // 4️⃣ Update chat timestamp
    _chatDao.updateLastUpdated(chat);

    // 5️⃣ Send message over WebSocket
    final sentMessage = message.toModel();
    return buildMessageDtoPayload(
      message: sentMessage,
      senderPublicId: myPublicId,
      receiverPublicId: receiverPublicId,
      chatId: chatDto.id!,
      contentType: 'MEDIA',
    );
  }

  Map<String, dynamic> buildMessageDtoPayload({
    required MessageModal message,
    required String senderPublicId,
    required String receiverPublicId,
    required String contentType,
    required String chatId,
  }) {
    final mediaList =
        message.mediaFiles
            .map((m) => {"url": m.url, "public_id": m.publicId})
            .toList();

    // 2. Construct the core MessageDto structure (snake_case)
    final messageDto = {
      "message_id": message.messageId,
      "message": message.message,
      "chat_id": chatId,
      "sender_id": senderPublicId,
      "receiver_id": receiverPublicId,
      "sender_timestamp": message.timestamp.toString(),
      "message_type": contentType,
      "media_list": mediaList.isNotEmpty ? mediaList : null,
    };

    return {"msg_type": "message", "message": messageDto};
  }
}
