import 'package:chat/database/entities/chat.dart';
import 'package:chat/database/entities/contact.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class ChatParticipantEntity {
  int id;

  String contactPublicId;

  final chat = ToOne<ChatEntity>();
  final contact = ToOne<ContactEntity>();

  ChatParticipantEntity({
    this.id = 0,
    required this.contactPublicId,
  });
}