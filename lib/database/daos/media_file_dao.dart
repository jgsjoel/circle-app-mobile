import 'package:chat/database/entities/media_file.dart';
import 'package:chat/database/entities/message.dart';
import 'package:chat/models/media_selection.dart';
import 'package:chat/services/service_locator.dart';
import 'package:objectbox/objectbox.dart';
import 'package:chat/objectbox.g.dart'; // Importing generated query properties

class MediaFileObjectBoxDao {
  final Store _store = getIt<Store>();

  Box<MediaFileEntity> get _mediaFileBox => _store.box<MediaFileEntity>();
  Box<MessageEntity> get _messageBox => _store.box<MessageEntity>();

  void saveMediaFile(MediaFileEntity mediaFile, MessageEntity message) {
    mediaFile.message.target = message;
    _mediaFileBox.put(mediaFile);
  }

  List<MediaFileEntity> getMediaFilesForMessage(int messageId) {
    return _mediaFileBox.query(MediaFileEntity_.message.equals(messageId)).build().find();
  }

  void saveMediaFiles(List<MediaFile> mediaFiles, MessageEntity message) {
    final mediaEntities = mediaFiles.map((file) {
      return MediaFileEntity(
        url: file.file.path, // local path
        publicId: '',
      )..message.target = message;
    }).toList();

    _mediaFileBox.putMany(mediaEntities);
    message.mediaFiles.addAll(mediaEntities);
    _messageBox.put(message);
  }
}