import 'package:chat/database/collections/media_file.dart';
import 'package:chat/database/collections/message.dart';
import 'package:chat/services/service_locator.dart';
import 'package:isar/isar.dart';

class MediaFileIsarDao {
  final Isar _isar = getIt<Isar>();

  Future<void> saveMediaFile(MediaFileCollection mediaFile, MessageCollection message) async {
    await _isar.writeTxn(() async {
      await _isar.mediaFileCollections.put(mediaFile);
      mediaFile.message.value = message;
      await mediaFile.message.save();
    });
  }

  Future<List<MediaFileCollection>> getMediaFilesForMessage(int messageId) async {
    return await _isar.mediaFileCollections
        .filter()
        .message((q) => q.idEqualTo(messageId))
        .findAll();
  }
}