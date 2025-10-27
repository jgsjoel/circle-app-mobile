import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/entities/chat_participant.dart';
import 'package:chat/database/entities/contact.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:objectbox/objectbox.dart';
import 'package:chat/objectbox.g.dart'; // Importing generated query properties

class ChatObjectBoxDao {
  final Store _store = getIt<Store>();

  Box<ChatEntity> get _chatBox => _store.box<ChatEntity>();
  Box<ContactEntity> get _contactBox => _store.box<ContactEntity>();

  Future<void> saveChat(ChatEntity chat) async {
    _chatBox.put(chat);
  }

  ChatEntity? getChatById(int id) {
    return _chatBox.query(ChatEntity_.id.equals(id)).build().findFirst();
  }

  Stream<List<ChatDto>> watchAllChats() async* {
    final myPublicId = await SecureStoreService.getPublicUserId();

    yield* _chatBox.query().watch(triggerImmediately: true).asyncMap((query) async {
      final chats = query.find();
      final List<ChatDto> chatDtos = [];

      for (final chat in chats) {
        final messagesList = chat.messages.toList();
        messagesList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final lastMessage = messagesList.isNotEmpty ? messagesList.first : null;
        final unreadCount =
            messagesList.where((m) => m.status == 'received').length;

        String displayName = chat.name;
        String? phone;
        String? contactPublicId;

        if (!chat.isGroup) {
          final participant = chat.participants.firstWhere(
            (p) => p.contactPublicId != myPublicId,
            orElse: () => ChatParticipantEntity(contactPublicId: 'unknown'),
          );
          contactPublicId = participant.contactPublicId;

          if (contactPublicId.isNotEmpty && contactPublicId != 'unknown') {
            final contact = _contactBox
                .query(ContactEntity_.publicId.equals(contactPublicId))
                .build()
                .findFirst();
            if (contact != null) {
              displayName = contact.name;
              phone = contact.phone;
            }
          }
        }

        chatDtos.add(
          ChatDto(
            id: chat.id.toString(),
            name: displayName,
            isGroup: chat.isGroup,
            pubChatId: chat.publicChatId,
            publicUserId: contactPublicId ?? '',
            phone: phone,
            lastMessage: lastMessage?.message ?? 'No messages yet',
            time: lastMessage != null
                ? lastMessage.timestamp.toString()
                : DateTime.now().millisecondsSinceEpoch.toString(),
            messageCount: unreadCount,
          ),
        );
      }

      chatDtos.sort((a, b) {
        final aTime = int.tryParse(a.time ?? '0') ?? 0;
        final bTime = int.tryParse(b.time ?? '0') ?? 0;
        return bTime.compareTo(aTime);
      });

      return chatDtos;
    });
  }

  bool deleteChat(int id) {
    return _chatBox.remove(id);
  }

  ChatEntity createChat(ChatDto dto) {
    final chat = ChatEntity(
      name: dto.name,
      publicChatId: dto.pubChatId,
      isGroup: dto.isGroup,
      lastUpdated: DateTime.now(),
    );

    saveChat(chat);
    return chat;
  }

  void updateLastUpdated(ChatEntity chat) {
    chat.lastUpdated = DateTime.now();
    saveChat(chat);
  }
}
