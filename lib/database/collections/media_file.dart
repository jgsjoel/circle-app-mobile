import 'package:chat/database/collections/message.dart';
import 'package:chat/database/db_modals/MediaFileModal.dart';
import 'package:isar/isar.dart';

part 'media_file.g.dart';

@Collection()
class MediaFileCollection {
  Id? isarId;
  
  late String id;

  late String url;
  late String publicId;
  final message = IsarLink<MessageCollection>();

  MediaFileCollection();

  MediaFileCollection copyWith({
    Id? isarId,
    String? id,
    String? url,
    String? publicId,
  }) {
    return MediaFileCollection()
      ..isarId = isarId ?? this.isarId
      ..id = id ?? this.id
      ..url = url ?? this.url
      ..publicId = publicId ?? this.publicId;
  }

  MediaFile toModel() {
    // The messageId for the old model is an int, which we get from the linked MessageCollection.
    final messageValue = message.value;
    return MediaFile(
      id: id,
      url: url,
      publicId: publicId,
      messageId: messageValue?.id ?? 0,
    );
  }

  factory MediaFileCollection.fromModel(MediaFile model) {
    return MediaFileCollection()
      ..id = model.id
      ..url = model.url
      ..publicId = model.publicId;
    // The `message` IsarLink must be associated separately after creation.
  }
}