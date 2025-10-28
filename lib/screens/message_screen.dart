import 'dart:convert';
import 'package:chat/custom_ui/bottom_sheet.dart';
import 'package:chat/custom_ui/message_bubble.dart';
import 'package:chat/custom_ui/message_input.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/database/daos/message_dao.dart';
import 'package:chat/provider/chat_provider.dart';
import 'package:chat/screens/media_view.dart';
import 'package:chat/services/message_serivce.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final MessageService _messageService = getIt<MessageService>();
  final FocusNode _focusNode = FocusNode();

  bool _emojiShowing = false;
  bool _showAttachmentSheet = false; 

  late final MessageDao _messageDao;
  late final Stream<List<MessageModal>> _messageStream;

  @override
  void initState() {
    super.initState();
    _messageDao = getIt<MessageDao>();
    _messageStream =
        _messageDao.watchMessages(widget.chatDto.id!).asBroadcastStream();

    _messageDao.markMessagesAsRead(widget.chatDto.id!);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) setState(() => _emojiShowing = false);
    });
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

  @override
  Widget build(BuildContext context) {
    final chatAsyncValue = ref.watch(selectedChatProvider(widget.chatDto.id!));
    
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBack),
          title: chatAsyncValue.when(
            data: (updatedChat) => Text(
              updatedChat.name,
              style: const TextStyle(fontSize: 16),
            ),
            loading: () => Text(
              widget.chatDto.name,
              style: const TextStyle(fontSize: 16),
            ),
            error: (_, __) => Text(
              widget.chatDto.name,
              style: const TextStyle(fontSize: 16),
            ),
          ),
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
                            status:message.status,
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
                    final sentMessage = await _messageService.addMessageLocally(
                      text,
                      widget.chatDto,
                    );

                    // 3. Prepare and Send message DTO for WebSocket
                    final outgoingPayload = _messageService.buildMessageDtoPayload(
                      message: sentMessage,
                      senderPublicId: myPublicId,
                      chatId: widget.chatDto.id!,
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
                      _messageService.handleMediaSelected(mediafiles, widget.chatDto),
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
