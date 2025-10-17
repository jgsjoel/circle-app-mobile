import 'package:chat/custom_ui/bottom_sheet.dart';
import 'package:chat/custom_ui/message_input.dart';
import 'package:chat/custom_ui/message_bubble.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/provider/messaging_provider.dart';
import 'package:chat/services/message_serivce.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageScreen extends ConsumerStatefulWidget {
  final ChatDto chatDto;
  const MessageScreen({super.key, required this.chatDto});

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _emojiShowing = false;
  bool _showAttachmentSheet = false;
  MessageService _messageService = getIt<MessageService>();

  void _toggleAttachmentSheet() {
    setState(() {
      _showAttachmentSheet = !_showAttachmentSheet;
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

    ref.read(messageProvider.notifier).clear();

    Navigator.pop(context); // default pop
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _emojiShowing = false;
        });
      }
    });

    if (widget.chatDto.id != null) {
      Future.microtask(() {
        ref.read(messageProvider.notifier).loadMessages(widget.chatDto.id!);

        // optional: auto-scroll to bottom after messages load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients &&
              _scrollController.positions.isNotEmpty) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      });
    }
  }

  void _toggleEmojiKeyboard() async {
    if (_emojiShowing) {
      FocusScope.of(context).requestFocus(_focusNode);
      setState(() {
        _emojiShowing = false;
      });
    } else {
      FocusScope.of(context).unfocus();
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {
        _emojiShowing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: 28),
            onPressed: () => _handleBack(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[400],
                child: widget.chatDto.icon ?? Icon(Icons.person, size: 16),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.chatDto.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(icon: Icon(Icons.call), onPressed: () {}),
            IconButton(
              icon: Icon(Icons.video_call, size: 30),
              onPressed: () {},
            ),
            PopupMenuButton(
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    child: Text("View Profile"),
                    value: "New Group",
                  ),
                  PopupMenuItem(child: Text("Block User"), value: "Settings"),
                ];
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final messages = ref.watch(
                          messageProvider,
                        ); // <-- listen to provider

                        // Auto-scroll to bottom when new messages arrive
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients &&
                              _scrollController.positions.isNotEmpty) {
                            // Only auto-scroll if user is near the bottom (within 100px)
                            final position = _scrollController.position;
                            final isNearBottom = position.maxScrollExtent - position.pixels < 100;
                            
                            if (isNearBottom) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          }
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];

                            return MessageBubble(
                              text: message.message,
                              isMe: message.fromMe,
                              onDelete: (id) {
                                if (id != null) {
                                  try {
                                    _messageService.deleteMessageById(id);
                                  } catch (e) {
                                    print("Delete failed: $e");
                                  }
                                }
                              },

                              messageId: message.id,
                              timeStamp: message.timestamp,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  MessageInput(
                    controller: _controller,
                    scrollController: _scrollController,
                    focusNode: _focusNode,
                    emojiShowing: _emojiShowing,
                    toggleEmojiKeyboard: _toggleEmojiKeyboard,
                    toggleAttachmentSheet:
                        _toggleAttachmentSheet, // <-- new prop
                    onSend: (text) {
                      //1. save in db
                      //2. save in message list
                      ref
                          .read(messageProvider.notifier)
                          .addMessage(text, widget.chatDto);
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
                  bottom: 65, // just above the message input
                  left: 0,
                  right: 0,
                  child: CustomBottomSheet.buildInlineSheet(context),
                ),
            ],
          ),
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
