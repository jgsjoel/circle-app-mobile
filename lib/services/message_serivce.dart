import 'dart:convert';
import 'dart:io';
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
import 'package:chat/services/media_upload_service.dart';
import 'package:chat/provider/ws_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat/database/db_modals/MediaFileModal.dart' as db;

class MessageService {
  final ChatObjectBoxDao _chatDao = getIt<ChatObjectBoxDao>();
  final ChatParticipantObjectBoxDao _participantDao = getIt<ChatParticipantObjectBoxDao>();
  final MessageDao _messageDao = getIt<MessageDao>();
  final MediaFileObjectBoxDao _mediaFileDao = getIt<MediaFileObjectBoxDao>();
  final MediaUploadService _mediaUploadService = MediaUploadService.instance;
  final Ref _ref;

  MessageService(this._ref);

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

  // Send text message with offline support
  Future<Map<String, dynamic>> sendTextMessage(String text, ChatDto chatDto) async {
    final myPublicId = await SecureStoreService.getPublicUserId();
    final receiverPublicId = chatDto.publicUserId;

    if (receiverPublicId == null) {
      return {'error': 'Receiver ID missing', 'success': false};
    }

    // 1️⃣ Find or create chat
    ChatEntity? chat = _chatDao.getChatById(chatDto.id != null ? int.parse(chatDto.id!) : 0);
    if (chat == null) {
      chat = _chatDao.createChat(chatDto);
      _participantDao.addParticipants(chat, chatDto);
    }

    // 2️⃣ Create message locally with 'pending' status
    final message = _messageDao.createMessage(text, chat);
    message.status = 'pending';
    _messageDao.updateMessage(message);

    // 3️⃣ Update chat timestamp
    _chatDao.updateLastUpdated(chat);

    // 4️⃣ Check if WebSocket is connected
    final wsService = _ref.read(webSocketProvider);
    if (wsService == null || !wsService.isConnected) {
      print("❌ WebSocket not connected - message saved locally as failed");
      message.status = 'failed';
      _messageDao.updateMessage(message);
      return {'success': true, 'error': 'Offline', 'message': message.toModel(), 'offline': true};
    }

    // 5️⃣ Try to send via WebSocket
    try {
      final chatId = chatDto.pubChatId?.isNotEmpty == true ? chatDto.pubChatId! : chatDto.id ?? '0';
      final sentMessage = message.toModel();
      final payload = buildMessageDtoPayload(
        message: sentMessage,
        senderPublicId: myPublicId,
        receiverPublicId: receiverPublicId,
        chatId: chatId,
        contentType: 'TEXT',
      );

      final jsonString = jsonEncode(payload);
      _ref.read(webSocketProvider.notifier).send(jsonString);
      
      // Keep as 'pending' - will be updated to 'sent' when server confirms
      print("✅ Message sent via WebSocket, waiting for confirmation");
      
      return {'success': true, 'message': message.toModel()};
    } catch (e) {
      print("❌ Failed to send message: $e");
      message.status = 'failed';
      _messageDao.updateMessage(message);
      return {'success': true, 'error': 'Failed to send message', 'message': message.toModel(), 'offline': true};
    }
  }

  // Handle media selection and send with offline support
  Future<Map<String, dynamic>> handleMediaSelected(
    List<MediaFile> mediaFiles,
    ChatDto chatDto,
  ) async {
    print("handleMediaSelected triggered-------------");
    final receiverPublicId = chatDto.publicUserId;

    if (receiverPublicId == null) {
      print("❌ Cannot send message: receiver ID missing.");
      return {'error': 'Receiver ID missing', 'success': false};
    }

    final chatId = chatDto.pubChatId?.isNotEmpty == true 
        ? chatDto.pubChatId!
        : chatDto.id ?? '0';

    // 1️⃣ Find or create chat
    ChatEntity? chat = _chatDao.getChatById(int.parse(chatDto.id ?? '0'));
    if (chat == null) {
      chat = _chatDao.createChat(chatDto);
      _participantDao.addParticipants(chat, chatDto);
    }

    // 2️⃣ Create message locally with 'pending' status
    final message = _messageDao.createMessage(
      mediaFiles.first.caption ?? '',
      chat,
    );
    message.status = 'pending';
    _messageDao.updateMessage(message);

    // 3️⃣ Try to upload and send (this will fail gracefully if offline)
    try {
      // Get signed URLs to obtain public IDs
      final signedUrlsResponse = await _mediaUploadService.getSignedUrls(chatId, mediaFiles);
      final urls = signedUrlsResponse['urls'] as List;
      
      // Store media files with local paths and real public IDs
      final dbMediaFiles = List.generate(mediaFiles.length, (index) {
        final file = mediaFiles[index];
        final urlInfo = urls[index] as Map<String, dynamic>;
        return db.MediaFile(
          source: file.localPath ?? file.file.path,  // Store local file path
          publicId: urlInfo['publicId'],  // Real public ID from server
          messageId: message.id,
          id: file.id,
        );
      }).toList();
      
      _mediaFileDao.saveMediaFiles(dbMediaFiles, message);
      
      // 4️⃣ Update chat timestamp
      _chatDao.updateLastUpdated(chat);
      
      // Upload and send
      await _uploadAndSendMediaMessage(message, mediaFiles, chatDto, urls);
      return {'success': true, 'message': message.toModel()};
    } catch (e) {
      print("❌ Failed to upload/send media (offline mode): $e");
      
      // Store media files with local paths (use temporary public IDs for offline)
      final dbMediaFiles = List.generate(mediaFiles.length, (index) {
        final file = mediaFiles[index];
        return db.MediaFile(
          source: file.localPath ?? file.file.path,  // Store local file path
          publicId: 'temp_${DateTime.now().millisecondsSinceEpoch}_$index',  // Temporary ID
          messageId: message.id,
          id: file.id,
        );
      }).toList();
      
      _mediaFileDao.saveMediaFiles(dbMediaFiles, message);
      
      // 4️⃣ Update chat timestamp
      _chatDao.updateLastUpdated(chat);
      
      message.status = 'failed';
      _messageDao.updateMessage(message);
      // Still return success because message is saved locally
      return {'success': true, 'message': message.toModel(), 'offline': true};
    }
  }

  // Upload media and send message
  Future<void> _uploadAndSendMediaMessage(
    dynamic message,  // MessageEntity
    List<MediaFile> mediaFiles,
    ChatDto chatDto,
    List<dynamic> signedUrls,
  ) async {
    final myPublicId = await SecureStoreService.getPublicUserId();
    final receiverPublicId = chatDto.publicUserId!;
    final chatId = chatDto.pubChatId?.isNotEmpty == true ? chatDto.pubChatId! : chatDto.id ?? '0';

    // Upload files to Cloudinary
    final uploadedUrls = await _mediaUploadService.uploadMediaToCloudinary(
      mediaFiles,
      signedUrls,
    );

    // Build payload with Cloudinary URLs
    final sentMessage = message.toModel();
    final mediaList = List.generate(uploadedUrls.length, (index) {
      return {
        "url": uploadedUrls[index],
        "public_id": (signedUrls[index] as Map<String, dynamic>)['publicId'],
      };
    });

    final payload = {
      "msg_type": "message",
      "message": {
        "message_id": sentMessage.messageId,
        "message": sentMessage.message,
        "chat_id": chatId,
        "sender_id": myPublicId,
        "receiver_id": receiverPublicId,
        "sender_timestamp": DateTime.fromMillisecondsSinceEpoch(sentMessage.timestamp).toUtc().toIso8601String(),
        "message_type": "MEDIA",
        "media_list": mediaList,
      }
    };

    // Send via WebSocket
    final jsonString = jsonEncode(payload);
    _ref.read(webSocketProvider.notifier).send(jsonString);
    
    message.status = 'sent';
    _messageDao.updateMessage(message);
  }

  // Retry sending a failed message
  Future<Map<String, dynamic>> retryMessage(MessageModal messageModal, ChatDto chatDto) async {
    if (messageModal.messageId == null) {
      return {'error': 'Message ID is null', 'success': false};
    }
    
    final message = _messageDao.getMessageByMessageId(messageModal.messageId!);
    if (message == null) {
      return {'error': 'Message not found', 'success': false};
    }

    message.status = 'pending';
    _messageDao.updateMessage(message);

    try {
      if (messageModal.mediaFiles.isNotEmpty) {
        // Retry media message
        return await retryMediaMessage(messageModal, chatDto);
      } else {
        // Retry text message
        return await retryTextMessage(messageModal, chatDto);
      }
    } catch (e) {
      message.status = 'failed';
      _messageDao.updateMessage(message);
      return {'success': false, 'error': e.toString()};
    }
  }

  // Retry text message
  Future<Map<String, dynamic>> retryTextMessage(MessageModal messageModal, ChatDto chatDto) async {
    // Check if WebSocket is connected
    final wsService = _ref.read(webSocketProvider);
    if (wsService == null || !wsService.isConnected) {
      print("❌ WebSocket not connected - cannot retry message");
      if (messageModal.messageId != null) {
        final message = _messageDao.getMessageByMessageId(messageModal.messageId!);
        if (message != null) {
          message.status = 'failed';
          _messageDao.updateMessage(message);
        }
      }
      return {'success': false, 'error': 'Not connected to server'};
    }

    final myPublicId = await SecureStoreService.getPublicUserId();
    final receiverPublicId = chatDto.publicUserId!;
    final chatId = chatDto.pubChatId?.isNotEmpty == true ? chatDto.pubChatId! : chatDto.id ?? '0';

    final payload = buildMessageDtoPayload(
      message: messageModal,
      senderPublicId: myPublicId,
      receiverPublicId: receiverPublicId,
      chatId: chatId,
      contentType: 'TEXT',
    );

    final jsonString = jsonEncode(payload);
    _ref.read(webSocketProvider.notifier).send(jsonString);

    if (messageModal.messageId != null) {
      final message = _messageDao.getMessageByMessageId(messageModal.messageId!);
      if (message != null) {
        // Keep as pending until server confirms
        message.status = 'pending';
        _messageDao.updateMessage(message);
      }
    }

    return {'success': true};
  }

  // Retry media message
  Future<Map<String, dynamic>> retryMediaMessage(MessageModal messageModal, ChatDto chatDto) async {
    if (messageModal.messageId == null) {
      return {'error': 'Message ID is null', 'success': false};
    }
    
    final message = _messageDao.getMessageByMessageId(messageModal.messageId!);
    if (message == null) {
      return {'error': 'Message not found', 'success': false};
    }

    final chatId = chatDto.pubChatId?.isNotEmpty == true ? chatDto.pubChatId! : chatDto.id ?? '0';

    // Get media files from database
    final dbMediaFiles = message.mediaFiles.toList();
    
    // Reconstruct MediaFile objects from stored data
    final mediaFiles = dbMediaFiles.map((dbFile) {
      final file = File(dbFile.source);  // source contains local path
      return MediaFile(
        id: dbFile.publicId,
        file: file,
        type: MediaType.image,  // You may need to store type
        name: file.path.split('/').last,
        size: file.existsSync() ? file.lengthSync() : 0,
        localPath: dbFile.source,
      );
    }).toList();

    // Get new signed URLs
    final signedUrlsResponse = await _mediaUploadService.getSignedUrls(chatId, mediaFiles);
    final urls = signedUrlsResponse['urls'] as List;

    // Upload and send
    await _uploadAndSendMediaMessage(message, mediaFiles, chatDto, urls);

    return {'success': true};
  }

  Map<String, dynamic> buildMessageDtoPayload({
    required MessageModal message,
    required String senderPublicId,
    required String receiverPublicId,
    required String contentType,
    required String chatId, 
  }) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(message.timestamp)
        .toUtc()
        .toIso8601String();

    final mediaList = message.mediaFiles.map((m) => {
      "url": m.source,  // Use source field instead of url
      "public_id": m.publicId
    }).toList();

    final messageDto = {
      "msg_type": "message",
      "message": {
        "message_id": message.messageId,
        "message": message.message,
        "chat_id": chatId,
        "sender_id": senderPublicId,
        "receiver_id": receiverPublicId,
        "sender_timestamp": timestamp,
        "message_type": contentType,
        "media_list": mediaList.isNotEmpty ? mediaList : null,
      }
    };

    return messageDto;
  }
}
