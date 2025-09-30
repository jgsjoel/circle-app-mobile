import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final bool emojiShowing;
  final VoidCallback toggleEmojiKeyboard;
  final VoidCallback toggleAttachmentSheet;
  final void Function(String text) onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    required this.emojiShowing,
    required this.toggleEmojiKeyboard,
    required this.toggleAttachmentSheet,
    required this.onSend,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool isTyping = false;

  void _handleSend() {
  final message = widget.controller.text.trim();
  if (message.isNotEmpty) {
    widget.onSend(message); // 👈 push to provider
    widget.controller.clear();
    setState(() => isTyping = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input Row
        Row(
          children: [
            Container(
              width: MediaQuery.sizeOf(context).width - 55,
              child: Card(
                color: const Color.fromARGB(255, 47, 45, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  style: const TextStyle(color: Colors.white),
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  minLines: 1,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Message...",
                    hintStyle: TextStyle(color: Colors.white60),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    prefixIcon: IconButton(
                      icon: Icon(
                        widget.emojiShowing
                            ? Icons.keyboard
                            : Icons.emoji_emotions,
                        color: Colors.white,
                      ),
                      onPressed: widget.toggleEmojiKeyboard,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: widget.toggleAttachmentSheet,
                          icon: Icon(Icons.attach_file, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CircleAvatar(
              backgroundColor: const Color.fromARGB(255, 28, 103, 55),
              child: IconButton(
                onPressed: () {
                  _handleSend();
                },
                icon: Icon(Icons.send),
              ),
            ),
          ],
        ),

        // Emoji Picker
        Offstage(
          offstage: !widget.emojiShowing,
          child: SizedBox(
            height: 256,
            child: EmojiPicker(
              textEditingController: widget.controller,
              scrollController: widget.scrollController,
              config: Config(
                height: 256,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax:
                      28 *
                      (foundation.defaultTargetPlatform == TargetPlatform.iOS
                          ? 1.2
                          : 1.0),
                  columns: 8,
                  backgroundColor: const Color(0xFF202C33),
                  verticalSpacing: 8,
                  horizontalSpacing: 8,
                  gridPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  noRecents: const Text(
                    "No Recents",
                    style: TextStyle(fontSize: 16, color: Color(0xFF8696A0)),
                    textAlign: TextAlign.center,
                  ),
                  loadingIndicator: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF25D366)),
                  ),
                  recentsLimit: 40,
                  replaceEmojiOnLimitExceed: true,
                ),
                categoryViewConfig: const CategoryViewConfig(
                  backgroundColor: Color(0xFF202C33),
                  tabBarHeight: 46,
                  indicatorColor: Color(0xFF25D366),
                  iconColor: Color(0xFF8696A0),
                  iconColorSelected: Color(0xFFE9EDEF),
                  backspaceColor: Color(0xFF25D366),
                  initCategory: Category.RECENT,
                  recentTabBehavior: RecentTabBehavior.RECENT,
                  extraTab: CategoryExtraTab.BACKSPACE,
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  backgroundColor: Color(0xFF202C33),
                  buttonColor: Color(0xFF202C33),
                  buttonIconColor: Color(0xFF8696A0),
                  showBackspaceButton: false,
                  showSearchViewButton: true,
                ),
                searchViewConfig: const SearchViewConfig(
                  backgroundColor: Color(0xFF121B22),
                  buttonIconColor: Color(0xFFE9EDEF),
                  hintText: "Search",
                ),
                skinToneConfig: const SkinToneConfig(
                  dialogBackgroundColor: Color(0xFF202C33),
                  indicatorColor: Color(0xFF25D366),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
