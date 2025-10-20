import 'package:chat/database/collections/contact.dart';
import 'package:chat/database/collections/chat.dart';
import 'package:chat/database/collections/media_file.dart';
import 'package:chat/database/collections/message.dart';
import 'package:chat/database/collections/chat_participant.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class IsarSetup {
  Isar? _isar;

  Isar get db {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('Isar database has not been initialized. Call init() first.');
    }
    return _isar!;
  }

  Future<void> init() async {
    if (_isar != null && _isar!.isOpen) return;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        ChatCollectionSchema,
        MessageCollectionSchema,
        ChatParticipantCollectionSchema,
        MediaFileCollectionSchema,
        ContactCollectionSchema,
      ],
      directory: dir.path,
    );
  }
}
