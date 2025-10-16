import 'package:chat/database/database_helper.dart';
import 'package:chat/database/modals/MediaFileModal.dart';
import 'package:sqflite/sqflite.dart';

class MediaFileDao {
  Future<int> insertMediaFile(MediaFile media) async {
    final db = await DatabaseHelper().database;
    return await db.insert(
      'media_files',
      media.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MediaFile>> getMediaForMessage(int messageId) async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      'media_files',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
    return result.map((e) => MediaFile.fromMap(e)).toList();
  }
}
