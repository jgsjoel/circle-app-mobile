import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/chat_participant.dart';
import 'package:chat/database/collections/contact.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:isar/isar.dart';

class ChatIsarDao {
  final Isar _isar = getIt<Isar>();

  Future<void> saveChat(ChatCollection chat) async {
    await _isar.writeTxn(() async {
      await _isar.chatCollections.put(chat);
    });
  }

  Future<ChatCollection?> getChatById(String id) async {
    return await _isar.chatCollections.filter().idEqualTo(id).findFirst();
  }

  Future<ChatCollection?> getChatByIsarId(int isarId) async {
    return await _isar.chatCollections.get(isarId);
  }

  Stream<List<ChatDto>> watchAllChats() async* {
    final myPublicId = await SecureStoreService.getPublicUserId();

    await for (final chats in _isar.chatCollections.where().watch(
      fireImmediately: true,
    )) {
      final List<ChatDto> chatDtos = [];

      for (final chat in chats) {
        // Load links
        await chat.participants.load();
        await chat.messages.load();

        // Safely get messages
        final messagesList = chat.messages.toList();
        messagesList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final lastMessage = messagesList.isNotEmpty ? messagesList.first : null;
        final unreadCount =
            messagesList.where((m) => m.status == 'received').length;

        // Display name for 1:1 chat
        String displayName = chat.name ?? 'Unknown';
        String? phone;
        String? contactPublicId;

        if (!chat.isGroup) {
          final participant = chat.participants.firstWhere(
            (p) => p.contactPublicId != myPublicId,
            orElse:
                () => ChatParticipantCollection()..contactPublicId = 'unknown',
          );
          contactPublicId = participant.contactPublicId;

          if (contactPublicId.isNotEmpty && contactPublicId != 'unknown') {
            final contact =
                await _isar.contactCollections
                    .filter()
                    .publicIdEqualTo(contactPublicId)
                    .findFirst();
            if (contact != null) {
              displayName = contact.name;
              phone = contact.phone;
            }
          }
        }

        chatDtos.add(
          ChatDto(
            id: chat.id,
            name: displayName,
            isGroup: chat.isGroup,
            pubChatId: chat.publicChatId,
            publicUserId: contactPublicId ?? '',
            phone: phone,
            lastMessage: lastMessage?.message ?? 'No messages yet',
            time:
                lastMessage != null
                    ? lastMessage.timestamp.toString()
                    : DateTime.now().millisecondsSinceEpoch.toString(),
            messageCount: unreadCount,
          ),
        );
      }

      // Sort chats by last message timestamp descending
      chatDtos.sort((a, b) {
        final aTime = int.tryParse(a.time ?? '0') ?? 0;
        final bTime = int.tryParse(b.time ?? '0') ?? 0;
        return bTime.compareTo(aTime);
      });

      yield chatDtos;
    }
  }

  Future<bool> deleteChat(int isarId) async {
    return await _isar.writeTxn(() async {
      return await _isar.chatCollections.delete(isarId);
    });
  }
}
