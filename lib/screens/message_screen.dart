import 'package:chat/custom_ui/bottom_sheet.dart';
import 'package:chat/custom_ui/message_bubble.dart';
import 'package:chat/custom_ui/message_input.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/database/daos/message_dao.dart';
import 'package:chat/provider/chat_provider.dart';
import 'package:chat/provider/ws_provider.dart';
import 'package:chat/screens/media_view.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat/provider/message_provider.dart';
import 'dart:async';

class MessageScreen extends ConsumerStatefulWidget {
  final ChatDto chatDto;
  const MessageScreen({super.key, required this.chatDto});

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _emojiShowing = false;
  bool _showAttachmentSheet = false;

  late final MessageDao _messageDao;
  late final Stream<List<MessageModal>> _messageStream;
  StreamSubscription<List<MessageModal>>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _messageDao = getIt<MessageDao>();
    _messageStream =
        _messageDao.watchMessages(widget.chatDto.id!).asBroadcastStream();

    // Immediately mark all existing 'received' messages as 'read' when opening the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Mark all received messages as read
      final receivedMessages = _messageDao.markMessagesAsRead(widget.chatDto.id!);
      for (final message in receivedMessages) {
        ref.read(webSocketProvider.notifier).sendStatusUpdate(message.messageId, 'read');
      }
      
      print("✅ Marked ${receivedMessages.length} messages as read on screen open");
    });

    // Listen to message stream and auto-mark any new 'received' messages as 'read'
    _messageSubscription = _messageStream.listen((messages) {
      // Check if widget is still mounted before processing
      if (!mounted) return;
      
      // Process only messages with 'received' status
      for (final message in messages) {
        if (message.status == 'received' && !message.fromMe && message.messageId != null) {
          print("🔄 Auto-marking message as read: ${message.messageId}");
          
          // Mark as read locally
          final messageEntity = _messageDao.getMessageByMessageId(message.messageId!);
          if (messageEntity != null) {
            messageEntity.status = 'read';
            _messageDao.updateMessage(messageEntity);
            
            // Only send status update if still mounted
            if (mounted) {
              ref.read(webSocketProvider.notifier).sendStatusUpdate(message.messageId!, 'read');
            }
          }
        }
      }
    });

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
    final messageService = ref.watch(messageServiceProvider);

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
                          return MessageBubble(
                            text: message.message,
                            status: message.status,
                            mediaFiles: message.mediaFiles,
                            isMe: message.fromMe,
                            messageId: message.id,
                            timeStamp: message.timestamp,
                            onDelete: (id) => _messageDao.deleteMessage(id!),
                            onRetry: () async {
                              // Retry failed message
                              print("🔄 Retrying message: ${message.messageId}");
                              final result = await messageService.retryMessage(
                                message,
                                widget.chatDto,
                              );
                              if (result['success'] == true) {
                                print("✅ Message retry successful");
                              } else {
                                print("❌ Message retry failed: ${result['error']}");
                              }
                            },
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

                    // Use the sendTextMessage method which has offline support
                    final result = await messageService.sendTextMessage(
                      text,
                      widget.chatDto,
                    );

                    if (result['success'] == true) {
                      print("✅ Message sent/queued successfully");
                    } else {
                      print("❌ Failed to send message: ${result['error']}");
                      // Message is still saved locally with 'failed' status
                      // User can retry by tapping the error icon
                    }

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
                      messageService.handleMediaSelected(mediafiles, widget.chatDto),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel message subscription
    _messageSubscription?.cancel();
    
    // Dispose controllers
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    
    super.dispose();
  }
}
