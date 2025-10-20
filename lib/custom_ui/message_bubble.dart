import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:chat/database/db_modals/MediaFileModal.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final Function(int? messageId) onDelete;
  final int? messageId;
  final int timeStamp;
  final List<MediaFile> mediaFiles;
  final Function(MediaFile media)? onMediaTap;

  const MessageBubble({
    Key? key,
    required this.text,
    required this.isMe,
    required this.onDelete,
    this.messageId,
    required this.timeStamp,
    this.mediaFiles = const [],
    this.onMediaTap,
  }) : super(key: key);

  String convertTime(int timeStamp) {
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(timeStamp);
    return DateFormat('HH:mm').format(dt);
  }

  String getMediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return "image";
    if (['mp4', 'mov', 'avi'].contains(ext)) return "video";
    if (['mp3', 'wav', 'm4a'].contains(ext)) return "audio";
    return "unknown";
  }

  @override
  Widget build(BuildContext context) {
    Widget messageContent = Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (text.isNotEmpty)
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 6),
        if (mediaFiles.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mediaFiles.map((media) {
              final type = getMediaType(media.url);
              Widget mediaWidget;

              switch (type) {
                case "image":
                  mediaWidget = ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(media.url),
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  );
                  break;

                case "video":
                  mediaWidget = SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(color: Colors.black26),
                        const Icon(Icons.play_circle_outline, size: 50, color: Colors.white),
                      ],
                    ),
                  );
                  break;

                case "audio":
                  mediaWidget = Container(
                    width: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.audiotrack, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            media.id,
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                  break;

                default:
                  mediaWidget = const SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () {
                  if (onMediaTap != null) onMediaTap!(media);
                },
                child: mediaWidget,
              );
            }).toList(),
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Text(
              convertTime(timeStamp),
              style: const TextStyle(
                fontSize: 12,
                color: Color.fromARGB(255, 207, 206, 206),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              const Icon(Icons.done_all, size: 16, color: Colors.white70),
            ],
          ],
        ),
      ],
    );

    Widget card = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Card(
        color: isMe
            ? const Color.fromARGB(255, 4, 117, 209)
            : const Color.fromARGB(255, 86, 86, 86),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
          ),
        ),
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: messageContent,
        ),
      ),
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (messageId == null)
          card
        else
          Slidable(
            key: ValueKey(messageId),
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => onDelete(messageId),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.redAccent,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => onDelete(messageId),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.redAccent,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: card,
          ),
      ],
    );
  }
}
