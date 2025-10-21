import 'dart:convert';
import 'package:chat/custom_ui/bottom_sheet.dart';
import 'package:chat/custom_ui/message_bubble.dart';
import 'package:chat/custom_ui/message_input.dart';
import 'package:chat/database/collections/chat_participant.dart';
import 'package:chat/database/collections/media_file.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/database/isar_dao/message_isar_dao.dart';
import 'package:chat/models/media_selection.dart';
import 'package:chat/screens/media_view.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/message.dart';
import 'package:uuid/uuid.dart';
import 'package:chat/provider/ws_provider.dart';

// Changed to ConsumerStatefulWidget
class MessageScreen extends ConsumerStatefulWidget {
  final ChatDto chatDto;
  const MessageScreen({super.key, required this.chatDto});

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

// Changed state to ConsumerState
class _MessageScreenState extends ConsumerState<MessageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Isar _isar = getIt<Isar>();
  final FocusNode _focusNode = FocusNode();
  final _uuid = const Uuid();

  bool _emojiShowing = false;
  bool _showAttachmentSheet = false;

  late final MessageIsarDao _messageDao;
  late final Stream<List<MessageModal>> _messageStream;

  @override
  void initState() {
    super.initState();
    _messageDao = getIt<MessageIsarDao>();
    _messageStream =
        _messageDao.watchMessages(widget.chatDto.id!).asBroadcastStream();

    _messageDao.markMessagesAsRead(widget.chatDto.id!);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) setState(() => _emojiShowing = false);
    });
  }

  // 💡 Helper to build the server-expected payload structure
  Map<String, dynamic> _buildMessageDtoPayload({
    required MessageModal message,
    required String senderPublicId,
    required String receiverPublicId,
    required String contentType, // Renamed for clarity: TEXT or MEDIA
  }) {
    // 1. Map MediaFileModal to MediaDto structure (snake_case)
    final mediaList = message.mediaFiles
        .map((m) => {"url": m.url, "public_id": m.publicId})
        .toList();

    // 2. Construct the core MessageDto structure (snake_case)
    final messageDto = {
      "message_id": message.msgPubId,
      "message": message.message,
      "chat_id": widget.chatDto.id,
      "sender_id": senderPublicId,
      "receiver_id": receiverPublicId,
      "sender_timestamp": message.timestamp.toString(), // Server expects String
      "message_type":
          contentType, // The actual type of the message content (TEXT/MEDIA)
      "media_list":
          mediaList.isNotEmpty ? mediaList : null, // Use null if empty
    };

    // 3. Wrap in the standard WebSocket envelope (InComingMsgStruct format)
    return {
      "msg_type": "message",
      "message": messageDto, // 👈 FIX: Send the DTO object directly, not an array.
    };
  }

  void _toggleAttachmentSheet() {
    setState(() {
      _showAttachmentSheet = !_showAttachmentSheet;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleBack() {
    if (_emojiShowing) {
      setState(() => _emojiShowing = false);
      return;
    }
    if (_showAttachmentSheet) {
      setState(() => _showAttachmentSheet = false);
      return;
    }
    Navigator.pop(context);
  }

  void _toggleEmojiKeyboard() {
    if (_emojiShowing) {
      FocusScope.of(context).requestFocus(_focusNode);
      setState(() => _emojiShowing = false);
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() => _emojiShowing = true);
      });
    }
  }

  Future<MessageModal> addMessageLocally(String text, ChatDto chatDto) async {
    // ... (unchanged: logic to find/create chat, included for context)
    ChatCollection? chat =
        await _isar.chatCollections
            .filter()
            .idEqualTo(chatDto.id ?? '')
            .findFirst();

    // 1️⃣ If chat doesn't exist, create it along with participants
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
        // Save chat first
        await _isar.chatCollections.put(chat!);

        // Create participant objects
        final participantCollections = <ChatParticipantCollection>[];

        // The other user
        if (chatDto.publicUserId != null) {
          final otherParticipant =
              ChatParticipantCollection()
                ..contactPublicId = chatDto.publicUserId!
                ..chat.value = chat;
          participantCollections.add(otherParticipant);
        }

        // Myself
        final myPublicId = await SecureStoreService.getPublicUserId();
        final meParticipant =
            ChatParticipantCollection()
              ..contactPublicId = myPublicId
              ..chat.value = chat;
        participantCollections.add(meParticipant);

        // Save participants and persist links
        await _isar.chatParticipantCollections.putAll(participantCollections);
        for (final participant in participantCollections) {
          await participant.chat.save();
        }

        // Link participants to chat
        chat.participants.addAll(participantCollections);
        await chat.participants.save();
      });
    }

    // 2️⃣ Create the message
    final message =
        MessageCollection()
          ..msgPubId = _uuid.v4()
          ..message = text
          ..fromMe = true
          ..timestamp = DateTime.now().millisecondsSinceEpoch
          ..status = 'sending'
          ..chat.value = chat; // one-to-one link

    // 3️⃣ Save the message and update the chat link
    await _isar.writeTxn(() async {
      await _isar.messageCollections.put(message);
      await message.chat.save();

      // Link message to chat
      chat!.messages.add(message);
      await chat.messages.save();

      // Update lastUpdated
      chat.lastUpdated = DateTime.now();
      await _isar.chatCollections.put(chat);
    });

    return message.toModel();
  }

  // 💡 Updated _handleMediaSelected to use the new payload structure
  void _handleMediaSelected(List<MediaFile> mediaFiles, ChatDto chatDto) async {
    setState(() {
      _showAttachmentSheet = false;
    });

    // 1️⃣ Prepare participant IDs and check for valid receiver
    final myPublicId = await SecureStoreService.getPublicUserId();
    final receiverPublicId = widget.chatDto.publicUserId;

    if (receiverPublicId == null) {
      print("Error: Cannot send message, receiver ID is missing.");
      return;
    }

    // 2️⃣ (unchanged: logic to find/create chat)
    ChatCollection? chat =
        await _isar.chatCollections
            .filter()
            .idEqualTo(chatDto.id ?? '')
            .findFirst();

    if (chat == null) {
      // Chat creation logic here
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

        final participantCollections = <ChatParticipantCollection>[];

        if (chatDto.publicUserId != null) {
          final otherParticipant =
              ChatParticipantCollection()
                ..contactPublicId = chatDto.publicUserId!
                ..chat.value = chat;
          participantCollections.add(otherParticipant);
        }

        final meParticipant =
            ChatParticipantCollection()
              ..contactPublicId = myPublicId
              ..chat.value = chat;
        participantCollections.add(meParticipant);

        await _isar.chatParticipantCollections.putAll(participantCollections);
        for (final participant in participantCollections) {
          await participant.chat.save();
        }

        chat.participants.addAll(participantCollections);
        await chat.participants.save();
      });
    }

    // 3️⃣ Create a message (one message per media group)
    final publicMessageId = _uuid.v4();
    final message =
        MessageCollection()
          ..msgPubId = publicMessageId
          ..message = mediaFiles.first.caption ?? ''
          ..fromMe = true
          ..timestamp = DateTime.now().millisecondsSinceEpoch
          ..status = 'sending'
          ..chat.value = chat;

    // 4️⃣ Create MediaFileCollections and link them to the message
    final mediaCollections =
        mediaFiles.map((mediaFile) {
          final media =
              MediaFileCollection()
                ..id = mediaFile.name
                ..url =
                    mediaFile
                        .file
                        .path // local path
                ..publicId = ''
                ..message.value = message;
          return media;
        }).toList();

    // 5️⃣ Save everything atomically
    await _isar.writeTxn(() async {
      await _isar.messageCollections.put(message);
      await message.chat.save();

      for (final media in mediaCollections) {
        await _isar.mediaFileCollections.put(media);
        await media.message.save();

        message.mediaFiles.add(media);
      }

      await message.mediaFiles.save();

      chat!.messages.add(message);
      await chat.messages.save();

      chat.lastUpdated = DateTime.now();
      await _isar.chatCollections.put(chat);
    });

    // 6️⃣ Send message via WebSocket
    final sentMessage = message.toModel();
    final outgoingPayload = _buildMessageDtoPayload(
      message: sentMessage,
      senderPublicId: myPublicId,
      receiverPublicId: receiverPublicId,
      contentType: 'MEDIA', // Set inner message type
    );

    final wsNotifier = ref.read(webSocketProvider.notifier);
    wsNotifier.send(jsonEncode(outgoingPayload));

    print(
      "✅ Message with ${mediaCollections.length} media files saved and sent successfully!",
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBack),
          title: Text(widget.chatDto.name),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<MessageModal>>(
                    stream: _messageStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final messages = snapshot.data!;

                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom(),
                      );

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          // ... (MessageBubble rendering logic)
                          return MessageBubble(
                            text: message.message,
                            mediaFiles: message.mediaFiles,
                            isMe: message.fromMe,
                            messageId: message.id,
                            timeStamp: message.timestamp,
                            onDelete: (id) => _messageDao.deleteMessage(id!),
                            onMediaTap: (media) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => MediaViewerScreen(media: media),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                MessageInput(
                  controller: _controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  emojiShowing: _emojiShowing,
                  toggleEmojiKeyboard: _toggleEmojiKeyboard,
                  toggleAttachmentSheet: _toggleAttachmentSheet,

                  onSend: (text) async {
                    if (text.trim().isEmpty) return;

                    // 1. Prepare participant IDs and check for valid receiver
                    final myPublicId =
                        await SecureStoreService.getPublicUserId();
                    final receiverPublicId = widget.chatDto.publicUserId;

                    if (receiverPublicId == null) {
                      print(
                        "Error: Cannot send message, receiver ID is missing.",
                      );
                      return;
                    }

                    // 2. Save to local db and get the model
                    final sentMessage = await addMessageLocally(
                      text,
                      widget.chatDto,
                    );

                    // 3. Prepare and Send message DTO for WebSocket
                    final outgoingPayload = _buildMessageDtoPayload(
                      message: sentMessage,
                      senderPublicId: myPublicId,
                      receiverPublicId: receiverPublicId,
                      contentType: 'TEXT', // Set inner message type
                    );

                    final wsNotifier = ref.read(webSocketProvider.notifier);
                    wsNotifier.send(jsonEncode(outgoingPayload));

                    // Clear controller and scroll to bottom
                    _controller.clear();
                    _scrollToBottom();
                  },
                ),
              ],
            ),
            if (_showAttachmentSheet)
              Positioned(
                bottom: 65,
                left: 0,
                right: 0,
                child: CustomBottomSheet.buildInlineSheet(
                  context,
                  (mediafiles) =>
                      _handleMediaSelected(mediafiles, widget.chatDto),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
