// websocket_provider.dart
import 'dart:async';

import 'package:chat/database/dao/chat_dao.dart';
import 'package:chat/database/dao/chat_participant_dao.dart';
import 'package:chat/database/dao/contact_dao.dart';
import 'package:chat/database/dao/media_file_dao.dart';
import 'package:chat/database/dao/message_dao.dart';
import 'package:chat/database/db_modals/MediaFileModal.dart';
import 'package:chat/database/db_modals/chat_modal.dart';
import 'package:chat/database/db_modals/chat_participant_modal.dart';
import 'package:chat/database/db_modals/contact_modal.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/dtos/incomming_messages.dart';
import 'package:chat/dtos/media.dart';
import 'package:chat/dtos/message_content.dart';
import 'package:chat/dtos/message_type.dart';
import 'package:chat/dtos/status_update_content.dart';
import 'package:chat/provider/chats_screen_provider.dart';
import 'package:chat/provider/messaging_provider.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:chat/services/webSock_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class WebSocketNotifier extends StateNotifier<WebSocketService?> {
  final Ref ref;
  WebSocketNotifier(this.ref) : super(null);

  Stream<String>? get messages => state?.messages;

  StreamSubscription<String>? _subscription;
  final MessageDao _messageDao = getIt<MessageDao>();
  final MediaFileDao _mediaDao = getIt<MediaFileDao>();

  final ChatDao _chatDao = getIt<ChatDao>();
  final ChatParticipantsDao _chatParticipantsDao = getIt<ChatParticipantsDao>();
  final ContactDao _contactDao = getIt<ContactDao>();
  final _uuid = const Uuid();

  Future<void> connect() async {
    final service = WebSocketService();
    await service.connect();
    state = service;

    // Listen to incoming messages here
    _subscription = state!.messages.listen((msg) {
      // print("📩 Incoming message in state: $msg");
      _handleMessage(msg);
    });
  }

  void _handleMessage(String msg) async {
    try {
      final incoming = IncomingMessage.fromRawJson(msg);
      print(incoming);

      for (final content in incoming.content) {
        switch (incoming.type) {
          case MessageType.MESSAGE:
            saveMessages(incoming);
            break;

          case MessageType.STATUS_UPDATE:
            updateMessage(incoming);
            break;

          default:
            print(incoming);
            break;
        }
      }
    } catch (e, st) {
      print('❌ Error handling incoming message: $e');
      print(st);
    }
  }

  void send(String message) => state?.send(message);

  void disconnect() {
    state?.close();
    state = null;
  }

  //update all messages
  void updateMessage(IncomingMessage incoming) async {
    if (incoming.type != MessageType.STATUS_UPDATE) return;
    final contents = incoming.content.whereType<StatusUpdateContent>().toList();

    for (final content in contents) {
      print(
        "Updating message: ${content.messageId} → ${content.messageStatus}",
      );

      await _messageDao.updateMessageAndChat(content);
    }
  }

  /// Complete saveMessages method that handles chat creation and message saving
  void saveMessages(IncomingMessage incoming) async {
    print("📩 Processing incoming message: ${incoming.type}");
    
    if (incoming.type != MessageType.MESSAGE) return;

    final contents = incoming.content.whereType<MessageContent>().toList();
    print("📝 Processing ${contents.length} message contents");

    for (final content in contents) {
      try {
        // Get current user's public ID
        final currentUserId = await SecureStoreService.getPublicUserId();
        final senderId = content.senderId;
        
        print("🔍 Current user: $currentUserId, Sender: $senderId");

        // Check if chat exists between sender and receiver
        ChatModal? existingChat = await _chatDao.findChatBetweenParticipants(
          currentUserId, 
          senderId
        );

        String chatId;
        
        if (existingChat != null) {
          // Chat exists, use existing chat ID
          chatId = existingChat.id;
          print("✅ Found existing chat: $chatId");
        } else {
          // Chat doesn't exist, create a new one
          print("🆕 Creating new chat between $currentUserId and $senderId");
          chatId = await _createNewChat(senderId, currentUserId, content.pubChatId);
          print("✅ Created new chat: $chatId");
        }

        // Save the incoming message
        final messageModel = MessageModal(
          msgPubId: content.messagePubId,
          message: content.message,
          fromMe: false, // This is an incoming message
          chatId: chatId,
          status: "received",
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        final messageId = await _messageDao.insertMessage(messageModel);
        print("💾 Message saved with ID: $messageId");

        // Update the message model with the new ID
        final savedMessage = MessageModal(
          id: messageId,
          msgPubId: messageModel.msgPubId,
          message: messageModel.message,
          fromMe: messageModel.fromMe,
          chatId: messageModel.chatId,
          status: messageModel.status,
          timestamp: messageModel.timestamp,
        );

        // Save any attached media files
        await _saveAttachedMedia(content.mediaDtoList, messageId);

        // Notify providers about the new message
        await _notifyProvidersAboutNewMessage(savedMessage, chatId, content);
        
      } catch (e, stackTrace) {
        print("❌ Error processing message content: $e");
        print("Stack trace: $stackTrace");
      }
    }
  }

  /// Create a new chat between two participants
  Future<String> _createNewChat(String senderId, String currentUserId, String? publicChatId) async {
    try {
      // Create new chat
      final chatId = _uuid.v4();
      final chatModal = ChatModal(
        id: chatId,
        isGroup: false,
        publicChatId: publicChatId, // Use the public chat ID from the message
      );

      await _chatDao.insertChat(chatModal);
      print("💾 Chat created: $chatId");

      // Add both participants to the chat
      await _chatParticipantsDao.insertParticipant(
        ChatParticipantModal(
          chatId: chatId,
          contactPublicId: senderId,
        )
      );

      await _chatParticipantsDao.insertParticipant(
        ChatParticipantModal(
          chatId: chatId,
          contactPublicId: currentUserId,
        )
      );

      print("👥 Participants added to chat: $chatId");
      return chatId;
    } catch (e, stackTrace) {
      print("❌ Error creating new chat: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  /// Save attached media files for a message
  Future<void> _saveAttachedMedia(List<MediaDto> mediaList, int messageId) async {
    if (mediaList.isEmpty) {
      print("📎 No media files to save");
      return;
    }

    print("📎 Saving ${mediaList.length} media files");
    
    for (final media in mediaList) {
      try {
        final mediaFile = MediaFile(
          id: _uuid.v4(),
          url: media.url,
          publicId: media.publicId,
          messageId: messageId,
        );

        final mediaId = await _mediaDao.insertMediaFile(mediaFile);
        print("📎 Media file saved with ID: $mediaId");
      } catch (e, stackTrace) {
        print("❌ Error saving media file: $e");
        print("Stack trace: $stackTrace");
      }
    }
  }

  /// Notify messaging and chat screen providers about new incoming message
  Future<void> _notifyProvidersAboutNewMessage(MessageModal message, String chatId, MessageContent content) async {
    try {
      // Check if the user is currently viewing this chat
      final messageNotifier = ref.read(messageProvider.notifier);
      final chatScreenNotifier = ref.read(chatScreenProvider.notifier);
      
      final currentChatId = messageNotifier.getCurrentChatId();
      print("🔍 Current chat ID: $currentChatId, Incoming message chat ID: $chatId");
      
      // Update messaging provider if user is viewing this chat
      if (messageNotifier.isChatCurrentlyViewed(chatId)) {
        messageNotifier.addIncomingMessage(message);
        print("📱 ✅ User is viewing this chat - message added to current view");
      } else {
        print("📱 ❌ User is not viewing this chat (viewing: $currentChatId) - message will appear in chat list");
      }

      // Check if this is a new chat that needs to be added to the chat list
      final existingChats = chatScreenNotifier.state;
      final chatExists = existingChats.any((chat) => chat.id == chatId);
      
      if (!chatExists) {
        // This is a new chat, we need to add it to the chat list
        print("🆕 Adding new chat to chat list: $chatId");
        await _addNewChatToProvider(chatId, message, content);
      } else {
        // Update existing chat with new message
        // First, let's try to get the proper contact name for display
        await _updateExistingChatWithProperName(chatId, message);
      }
      
      print("📩 ✅ Providers notified about new message for chat: $chatId");
    } catch (e, stackTrace) {
      print("❌ Error notifying providers: $e");
      print("Stack trace: $stackTrace");
    }
  }

  /// Add a new chat to the chat screen provider
  Future<void> _addNewChatToProvider(String chatId, MessageModal message, MessageContent content) async {
    try {
      // Get chat details from database
      final chatModal = await _chatDao.getChatById(chatId);
      if (chatModal == null) {
        print("❌ Chat not found in database: $chatId");
        return;
      }

      // Get sender information from the message content
      final currentUserId = await SecureStoreService.getPublicUserId();
      
      // Find the sender's public ID from chat participants
      final participants = await _chatParticipantsDao.getParticipantsByChat(chatId);
      String? senderPublicId;
      for (final participant in participants) {
        if (participant.contactPublicId != currentUserId) {
          senderPublicId = participant.contactPublicId;
          break;
        }
      }

      String displayName = "Unknown Contact";
      String? phoneNumber;

      if (senderPublicId != null) {
        // Check if this contact exists in our contacts
        final existingContact = await _contactDao.getContactById(senderPublicId);
        
        if (existingContact != null) {
          // Contact exists, use their name
          displayName = existingContact.name;
          phoneNumber = existingContact.phone;
          print("📱 Found existing contact: ${existingContact.name}");
        } else {
          // Contact doesn't exist, save them as unknown contact
          // Use the actual phone number from the message content
          final actualPhoneNumber = content.senderMobile;
          displayName = actualPhoneNumber; // Display phone number as name
          phoneNumber = actualPhoneNumber;
          
          // Save as unknown contact
          final unknownContact = ContactModal(
            name: actualPhoneNumber, // Use actual phone number as name
            phone: actualPhoneNumber,
            pubContactId: senderPublicId, // Use the public ID for the contact ID
          );
          await _contactDao.insertContact(unknownContact);
          print("📱 Saved unknown contact: $actualPhoneNumber (Public ID: $senderPublicId)");
        }
      }

      final chatDto = ChatDto(
        id: chatId,
        name: displayName,
        isGroup: chatModal.isGroup,
        lastMessage: message.message,
        time: message.timestamp.toString(),
        messageCount: 1,
        pubChatId: chatModal.publicChatId,
        phone: phoneNumber,
        publicUserId: senderPublicId,
      );

      // Add the new chat to the provider
      final chatScreenNotifier = ref.read(chatScreenProvider.notifier);
      chatScreenNotifier.addChat(chatDto);
      
      print("✅ New chat added to provider: $chatId with name: $displayName");
    } catch (e, stackTrace) {
      print("❌ Error adding new chat to provider: $e");
      print("Stack trace: $stackTrace");
    }
  }

  /// Update existing chat with proper contact name
  Future<void> _updateExistingChatWithProperName(String chatId, MessageModal message) async {
    try {
      final chatScreenNotifier = ref.read(chatScreenProvider.notifier);
      
      // Get the current chat from the provider
      final currentChats = chatScreenNotifier.state;
      final existingChat = currentChats.firstWhere((chat) => chat.id == chatId);
      
      // If the chat already has a proper name (not "New Chat"), just update the message
      if (existingChat.name != "New Chat" && existingChat.name.isNotEmpty) {
        chatScreenNotifier.updateChatWithNewMessage(
          chatId,
          message.message,
          message.timestamp.toString(),
        );
        return;
      }

      // If the chat has "New Chat" as name, try to get the proper contact name
      final currentUserId = await SecureStoreService.getPublicUserId();
      final participants = await _chatParticipantsDao.getParticipantsByChat(chatId);
      String? senderPublicId;
      for (final participant in participants) {
        if (participant.contactPublicId != currentUserId) {
          senderPublicId = participant.contactPublicId;
          break;
        }
      }

      String displayName = existingChat.name; // Keep existing name as fallback
      if (senderPublicId != null) {
        final existingContact = await _contactDao.getContactById(senderPublicId);
        if (existingContact != null) {
          displayName = existingContact.name;
          print("📱 Updated chat with proper contact name: ${existingContact.name}");
        }
      }

      // Update the chat with proper name and new message
      final updatedChat = existingChat.copyWith(
        name: displayName,
        lastMessage: message.message,
        time: message.timestamp.toString(),
        messageCount: (existingChat.messageCount ?? 0) + 1,
      );

      chatScreenNotifier.updateChat(updatedChat);
      print("📩 Updated existing chat with proper name: $displayName");
    } catch (e, stackTrace) {
      print("❌ Error updating existing chat: $e");
      print("Stack trace: $stackTrace");
      
      // Fallback to basic update
      final chatScreenNotifier = ref.read(chatScreenProvider.notifier);
      chatScreenNotifier.updateChatWithNewMessage(
        chatId,
        message.message,
        message.timestamp.toString(),
      );
    }
  }
}

final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketService?>(
      (ref) => WebSocketNotifier(ref),
    );
