import 'package:chat/database/entities/chat_participant.dart';
import 'package:objectbox/objectbox.dart';
import 'package:chat/database/db_modals/contact_modal.dart';

@Entity()
class ContactEntity {
  int id;

  String name;
  String phone;
  String publicId;

  @Backlink('contact')
  final chatParticipants = ToMany<ChatParticipantEntity>();

  ContactEntity({
    this.id = 0,
    required this.name,
    required this.phone,
    required this.publicId,
  });

  factory ContactEntity.fromModel(ContactModal modal) {
    return ContactEntity(
      name: modal.name,
      phone: modal.phone,
      publicId: modal.pubContactId ?? '',
    );
  }
}