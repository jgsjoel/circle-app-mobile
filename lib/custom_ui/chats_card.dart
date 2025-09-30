import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/screens/message_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatsCard extends StatelessWidget {
  final ChatDto chatDto;
  final VoidCallback onDelete; // callback to delete chat
  const ChatsCard({super.key, required this.chatDto, required this.onDelete});

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final millis = int.tryParse(timestamp);
      if (millis == null) return '';

      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      final now = DateTime.now();

      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return DateFormat.Hm().format(dt); 
      } else {
        return DateFormat('dd/MM/yyyy').format(dt);
      }
    } catch (_) {
      return '';
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop(); // close bottom sheet
                  if (onDelete != null) onDelete!(); // trigger delete callback
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = (chatDto.messageCount ?? 0) > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageScreen(chatDto: chatDto),
          ),
        );
      },
      onLongPress: () => _showDeleteDialog(context), // ✅ long press
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[400],
            child: chatDto.icon ?? const Icon(Icons.person),
          ),
          title: Text(
            chatDto.name ?? chatDto.phone ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            chatDto.lastMessage ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(chatDto.time),
                style: const TextStyle(
                    fontSize: 12, color: Color.fromARGB(255, 114, 113, 113)),
              ),
              const SizedBox(height: 5),
              if (hasUnread)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chatDto.messageCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
