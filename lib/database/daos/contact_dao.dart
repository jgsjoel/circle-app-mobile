import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/entities/contact.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/objectbox.g.dart'; // Importing generated query properties
import 'package:chat/services/service_locator.dart';
import 'package:objectbox/objectbox.dart';

class ContactObjectBoxDao {
  final Store _store = getIt<Store>();

  Box<ContactEntity> get _contactBox => _store.box<ContactEntity>();
  Box<ChatEntity> get _chatBox => _store.box<ChatEntity>();

  void saveContact(ContactEntity contact) {
    _contactBox.put(contact);
  }

  ContactEntity? getContactByPublicId(String publicId) {
    return _contactBox.query(ContactEntity_.publicId.equals(publicId)).build().findFirst();
  }

  ContactEntity? getContactById(int id) {
    return _contactBox.get(id);
  }

  List<ContactEntity> getAllContacts() {
    return _contactBox.getAll();
  }

  bool deleteContact(int id) {
    return _contactBox.remove(id);
  }

  void updateContactByPublicId(String publicId, {String? name, String? phone}) {
    final existing = getContactByPublicId(publicId);
    if (existing != null) {
      existing.name = name ?? existing.name;
      existing.phone = phone ?? existing.phone;
      saveContact(existing);
    }
  }

  List<ChatDto> getAllContactsAndGroups() {
    final allChats = _chatBox.getAll();
    final allContacts = _contactBox.getAll();

    final groupDtos = allChats.where((chat) => chat.isGroup).map((chat) {
      return ChatDto(
        id: chat.id.toString(),
        name: chat.name,
        isGroup: true,
        pubChatId: chat.publicChatId,
      );
    }).toList();

    final Map<String, ChatEntity> contactToChatMap = {};
    for (final chat in allChats.where((c) => !c.isGroup)) {
      for (final participant in chat.participants) {
        contactToChatMap[participant.contactPublicId] = chat;
      }
    }

    final contactDtos = allContacts.map((contact) {
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

    return [...groupDtos, ...contactDtos];
  }
}
