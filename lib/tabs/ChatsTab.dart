import 'package:chat/provider/chats_screen_provider.dart';
import 'package:chat/services/chat_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat/custom_ui/chats_card.dart';

class Chatstab extends ConsumerWidget {
  const Chatstab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the provider

    ChatService _chatService = getIt<ChatService>();
    final chats = ref.watch(chatScreenProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/contacts");
        },
        child: Icon(Icons.chat),
      ),
      body:
          chats.isEmpty
              ? Center(child: Text('No chats yet'))
              : ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return ChatsCard(
                    key: ValueKey(chat.id),
                    chatDto: chat,
                    onDelete: () {
                      _chatService.deleteChat(chat.id!);
                      ref.read(chatScreenProvider.notifier).removeChat(chat.id!);
                    },
                  );
                },
              ),
    );
  }
}
