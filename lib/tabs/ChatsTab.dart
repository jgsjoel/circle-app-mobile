import 'package:chat/database/isar_dao/chat_isar_dao.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:chat/custom_ui/chats_card.dart';

class Chatstab extends StatefulWidget {
  const Chatstab({super.key});

  @override
  State<Chatstab> createState() => _ChatstabState();
}

class _ChatstabState extends State<Chatstab> {
  late final Stream<List<ChatDto>> chatStream;

  @override
  void initState() {
    super.initState();
    final chatDao = getIt<ChatIsarDao>();
    chatStream = chatDao.watchAllChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, "/contacts"),
        child: Icon(Icons.chat),
      ),
      body: StreamBuilder<List<ChatDto>>(
        stream: chatStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) return Center(child: Text('No chats yet'));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatsCard(
                key: ValueKey(chat.id),
                chatDto: chat,
                onDelete: () async {
                  final chatDao = getIt<ChatIsarDao>();
                  // await chatDao.deleteChat(chat.id!);
                },
              );
            },
          );
        },
      ),
    );
  }
}
