import 'package:chat/database/entities/media_file.dart';
import 'package:chat/database/entities/message.dart';
import 'package:chat/database/db_modals/MediaFileModal.dart'; // Changed import
import 'package:chat/services/service_locator.dart';
import 'package:chat/objectbox.g.dart';

class MediaFileObjectBoxDao {
  final Store _store = getIt<Store>();
  Box<MediaFileEntity> get _mediaFileBox => _store.box<MediaFileEntity>();

  void saveMediaFile(MediaFileEntity mediaFile, MessageEntity message) {
    mediaFile.message.target = message;
    _mediaFileBox.put(mediaFile);
  }

  List<MediaFileEntity> getMediaFilesForMessage(int messageId) {
    return _mediaFileBox
        .query(MediaFileEntity_.message.equals(messageId))
        .build()
        .find();
  }

  void saveMediaFiles(List<MediaFile> mediaFiles, MessageEntity message) {
    for (final mediaFile in mediaFiles) {
      final entity = MediaFileEntity(
        source: mediaFile.source,
        publicId: mediaFile.publicId,
      )..message.target = message;

      _mediaFileBox.put(entity);
    }
  }
}