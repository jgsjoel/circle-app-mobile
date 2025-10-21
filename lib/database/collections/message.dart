import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/media_file.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:isar/isar.dart';

part 'message.g.dart';

@Collection()
class MessageCollection {
  Id id = Isar.autoIncrement;

  String? messageId;
  String? msgPubId;
  late String message;
  late bool fromMe;
  late int timestamp;
  String? status;

  MessageCollection();

  final chat = IsarLink<ChatCollection>();
  final mediaFiles = IsarLinks<MediaFileCollection>();

  MessageCollection copyWith({
    Id? id,
    String? messageId,
    String? msgPubId,
    String? message,
    bool? fromMe,
    int? timestamp,
    String? status,
  }) {
    return MessageCollection()
      ..id = id ?? this.id
      ..messageId = messageId ?? this.messageId
      ..msgPubId = msgPubId ?? this.msgPubId
      ..message = message ?? this.message
      ..fromMe = fromMe ?? this.fromMe
      ..timestamp = timestamp ?? this.timestamp
      ..status = status ?? this.status;
  }

  MessageModal toModel() {
    final chatValue = chat.value;

    // Get media files linked to this message
    final media = mediaFiles.map((m) => m.toModel()).toList();

    return MessageModal(
      id: id,
      messageId: messageId,
      msgPubId: msgPubId,
      message: message,
      fromMe: fromMe,
      chatId: chatValue?.id ?? '',
      status: status,
      timestamp: timestamp,
      mediaFiles: media,
    );
  }

  factory MessageCollection.fromModel(MessageModal model) {
    return MessageCollection()
      ..id = model.id ?? Isar.autoIncrement
      ..messageId = model.messageId
      ..msgPubId = model.msgPubId
      ..message = model.message
      ..fromMe = model.fromMe
      ..timestamp = model.timestamp
      ..status = model.status;
    // The `chat` IsarLink must be associated separately after creation.
  }
}
