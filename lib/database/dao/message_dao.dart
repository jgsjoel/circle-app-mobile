import 'package:chat/database/database_helper.dart';
import 'package:chat/database/modals/message_modal.dart';
import 'package:sqflite/sqflite.dart';

class MessageDao {
  final table = 'message';

  Future<int> insertMessage(MessageModal msg) async {
    final db = await DatabaseHelper().database;
    return await db.insert(
      table,
      msg.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MessageModal>> getMessagesByChat(String chatId) async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      table,
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return result.map((row) => MessageModal.fromMap(row)).toList();
  }

  Future<int> deleteMessageById(int id) async {
    final db = await DatabaseHelper().database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateMessageStatus(String msgPubId, String status) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      table,
      {'status': status},
      where: 'msg_pub_id = ?',
      whereArgs: [msgPubId],
    );
  }
}
