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
import 'package:isar/isar.dart';
import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/message.dart';

class MessageScreen extends StatefulWidget {
  final ChatDto chatDto;
  const MessageScreen({super.key, required this.chatDto});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Isar _isar = getIt<Isar>();
  // final MessageService _messageService = getIt<MessageService>();
  final FocusNode _focusNode = FocusNode();
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

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) setState(() => _emojiShowing = false);
    });
  }

  void _toggleAttachmentSheet() {
    setState(() {
      _showAttachmentSheet = !_showAttachmentSheet;
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _messageDao.saveMessage(widget.chatDto.id!, text, fromMe: true);
    _controller.clear();
    _scrollToBottom();
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
      Future.delayed(Duration(milliseconds: 100), () {
        setState(() => _emojiShowing = true);
      });
    }
  }

  Future<MessageModal> addMessageLocally(String text, ChatDto chatDto) async {
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
          ..message = text
          ..fromMe = true
          ..timestamp = DateTime.now().millisecondsSinceEpoch
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

  void _handleMediaSelected(List<MediaFile> mediaFiles, ChatDto chatDto) async {
    setState(() {
      _showAttachmentSheet = false;
    });

    // 1️⃣ Make sure the chat exists (or create it along with participants)
    ChatCollection? chat =
        await _isar.chatCollections
            .filter()
            .idEqualTo(chatDto.id ?? '')
            .findFirst();

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

        // Other user
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

    // 2️⃣ Create a message (one message per media group)
    final message =
        MessageCollection()
          ..message =
              mediaFiles.first.caption ??
              '' // optional caption
          ..fromMe = true
          ..timestamp = DateTime.now().millisecondsSinceEpoch
          ..chat.value = chat;

    // 3️⃣ Create MediaFileCollections and link them to the message
    final mediaCollections =
        mediaFiles.map((mediaFile) {
          final media =
              MediaFileCollection()
                ..id = mediaFile.name
                ..url = mediaFile.file.path
                ..publicId =
                    '' // will update after upload
                ..message.value = message;
          return media;
        }).toList();

    // 4️⃣ Save everything atomically
    await _isar.writeTxn(() async {
      await _isar.messageCollections.put(message);
      await message.chat.save();

      for (final media in mediaCollections) {
        await _isar.mediaFileCollections.put(media);
        await media.message.save();

        // Link both directions
        message.mediaFiles.add(media);
      }

      await message.mediaFiles.save();

      // Link message to chat and update
      chat!.messages.add(message);
      await chat.messages.save();

      chat.lastUpdated = DateTime.now();
      await _isar.chatCollections.put(chat);
    });

    // 5️⃣ (Optional) Upload to Cloudinary and update the DB
    // for (final media in mediaCollections) {
    //   final uploaded = await uploadToCloudinary(media.url);
    //   await _isar.writeTxn(() async {
    //     media.publicId = uploaded.publicId;
    //     media.url = uploaded.secureUrl;
    //     await _isar.mediaFileCollections.put(media);
    //   });
    // }

    print(
      "✅ Message with ${mediaCollections.length} media files saved successfully!",
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
                                  builder: (_) => MediaViewerScreen(media: media),
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
                  
                  onSend: (text) {
                    //1. save in db
                    //2. save in message list

                    // save message to local db first
                    addMessageLocally(text, widget.chatDto);

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients &&
                          _scrollController.positions.isNotEmpty) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent + 60,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
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
