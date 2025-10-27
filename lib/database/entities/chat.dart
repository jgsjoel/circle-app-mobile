import 'package:chat/database/entities/chat_participant.dart';
import 'package:chat/database/entities/message.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class ChatEntity {
  int id;

  String name;
  String? publicChatId;
  bool isGroup;

  @Property(type: PropertyType.date)
  DateTime lastUpdated;

  @Backlink('chat')
  final messages = ToMany<MessageEntity>();

  @Backlink('chat')
  final participants = ToMany<ChatParticipantEntity>();

  ChatEntity({
    this.id = 0,
    required this.name,
    this.publicChatId,
    required this.isGroup,
    required this.lastUpdated,
  });
}
