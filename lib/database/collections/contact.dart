import 'package:chat/database/collections/chat_participant.dart';
import 'package:chat/database/db_modals/contact_modal.dart';
import 'package:isar/isar.dart';

part 'contact.g.dart';

@Collection()
class ContactCollection {
  Id id = Isar.autoIncrement;
  late String name;
  late String phone;
  late String publicId;

  final chatParticipants = IsarLinks<ChatParticipantCollection>();

  ContactCollection();

  ContactCollection copyWith({
    Id? id,
    String? name,
    String? phone,
    String? publicId,
  }) {
    return ContactCollection()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..phone = phone ?? this.phone
      ..publicId = publicId ?? this.publicId;
  }

  ContactModal toModel() {
    return ContactModal(
      name: name,
      phone: phone,
      pubContactId: publicId,
    );
  }

  factory ContactCollection.fromModel(ContactModal model) {
    return ContactCollection()
      ..name = model.name
      ..phone = model.phone
      // Note: The model uses pubContactId, the collection uses publicId.
      ..publicId = model.pubContactId ?? '';
  }
}