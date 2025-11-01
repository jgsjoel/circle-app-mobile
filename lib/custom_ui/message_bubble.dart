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
  final String? status;
  final VoidCallback? onRetry; // 🆕 Add retry callback

  const MessageBubble({
    Key? key,
    required this.text,
    required this.isMe,
    required this.onDelete,
    this.messageId,
    required this.timeStamp,
    this.mediaFiles = const [],
    this.onMediaTap,
    this.status,
    this.onRetry, // 🆕 Add this
  }) : super(key: key);

  String convertTime(int timeStamp) {
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(timeStamp);
    return DateFormat('HH:mm').format(dt);
  }

  String getMediaType(String path) {
    final isRemote = path.startsWith('http://') || path.startsWith('https://');
    if (isRemote) {
      if (path.contains('.mp4') || path.contains('.mov')) return "video";
      if (path.contains('.mp3') || path.contains('.wav')) return "audio";
      return "image";
    }
    final ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return "image";
    if (['mp4', 'mov', 'avi'].contains(ext)) return "video";
    if (['mp3', 'wav', 'm4a'].contains(ext)) return "audio";
    return "unknown";
  }

  // 🆕 Helper to pick status icon based on message.status
  Widget _buildStatusIcon() {
    if (status == null) return const SizedBox.shrink();
    
    switch (status!.toLowerCase()) {
      case 'pending':
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        );
      case 'failed':
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.redAccent,
          ),
        );
      case 'sending':
        return const Icon(Icons.access_time, size: 16, color: Colors.white54);
      case 'sent':
        return const Icon(Icons.check, size: 16, color: Colors.white54);
      case 'received':
        return const Icon(Icons.done_all, size: 16, color: Colors.white54);
      case 'read':
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMediaUnavailableWidget() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Colors.white70,
          ),
          SizedBox(height: 8),
          Text(
            'Media Unavailable',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(MediaFile media) {
    // For local files, check if the file exists first
    if (media.source.startsWith('/') || media.source.startsWith('file://')) {
      final file = File(media.source.replaceFirst('file://', ''));
      if (!file.existsSync()) {
        print("❌ Local file not found: ${media.source}");
        return _buildMediaUnavailableWidget();
      }
      return Image.file(
        file,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("❌ Error loading local image: $error");
          return _buildMediaUnavailableWidget();
        },
      );
    }
    
    // For network URLs
    return Image.network(
      media.source,
      width: 150,
      height: 150,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: 150,
          height: 150,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print("❌ Error loading network image: $error");
        return _buildMediaUnavailableWidget();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add debug logging for media files
    if (mediaFiles.isNotEmpty) {
      print("📸 Message has ${mediaFiles.length} media files:");
      for (var media in mediaFiles) {
        print("   - Source: ${media.source}");
        print("   - Public ID: ${media.publicId}");
      }
    }

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
              final type = getMediaType(media.source);
              Widget mediaWidget;

              switch (type) {
                case "image":
                  mediaWidget = ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWidget(media),
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
                        const Icon(Icons.play_circle_outline,
                            size: 50, color: Colors.white),
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
              _buildStatusIcon(), // 🔁 replaced fixed icon with dynamic one
            ],
          ],
        ),
      ],
    );

    Widget card = ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      child: Card(
        color: isMe
            ? const Color.fromARGB(255, 2, 99, 138)
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
