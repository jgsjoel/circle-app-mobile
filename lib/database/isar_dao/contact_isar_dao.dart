import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/contact.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/service_locator.dart';
import 'package:isar/isar.dart';

class ContactIsarDao {
  final Isar _isar = getIt<Isar>();

  Future<void> saveContact(ContactCollection contact) async {
    await _isar.writeTxn(() async {
      await _isar.contactCollections.put(contact);
    });
  }

  Future<ContactCollection?> getContactByPublicId(String publicId) async {
    return await _isar.contactCollections
        .filter()
        .publicIdEqualTo(publicId)
        .findFirst();
  }

  Future<ContactCollection?> getContactById(int id) async {
    return await _isar.contactCollections.get(id);
  }

  Future<List<ContactCollection>> getAllContacts() async {
    return await _isar.contactCollections.where().findAll();
  }

  Future<bool> deleteContact(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.contactCollections.delete(id);
    });
  }

  Future<void> updateContactByPublicId(
    String publicId, {
    String? name,
    String? phone,
  }) async {
    await _isar.writeTxn(() async {
      final existing =
          await _isar.contactCollections
              .filter()
              .publicIdEqualTo(publicId)
              .findFirst();

      if (existing == null) return;

      final updated = existing.copyWith(name: name, phone: phone);

      await _isar.contactCollections.put(updated);
    });
  }

  Future<List<ChatDto>> getAllContactsAndGroups() async {
    // 1. Load all chats and contacts
    final allChats = await _isar.chatCollections.where().findAll();
    final allContacts = await _isar.contactCollections.where().findAll();

    // 2. Eagerly load all participants for each chat
    for (final chat in allChats) {
      await chat.participants.load();
    }

    // 3. Map all group chats to DTOs
    final groupDtos =
        allChats.where((chat) => chat.isGroup).map((chat) {

          return ChatDto(
            id: chat.id,
            name: chat.name ?? 'Group',
            isGroup: true,
            pubChatId: chat.publicChatId,
          );
        }).toList();

    // 4. Build map of contactPublicId → chat for 1-on-1 chats
    final Map<String, ChatCollection> contactToChatMap = {};
    for (final chat in allChats.where((c) => !c.isGroup)) {
      for (final participant in chat.participants) {
        contactToChatMap[participant.contactPublicId] = chat;
      }
    }

    // 5. Build contact DTOs (linked to chat if exists)
    final contactDtos =
        allContacts.map((contact) {
          final associatedChat = contactToChatMap[contact.publicId];
          return ChatDto(
            id: contact.id.toString(),
            name: contact.name,
            isGroup: false,
            publicUserId: contact.publicId,
            phone: "+94 ${contact.phone}",
            pubChatId: associatedChat?.publicChatId,
          );
        }).toList();

    // 6. Combine and return
    return [...groupDtos, ...contactDtos];
  }
}
