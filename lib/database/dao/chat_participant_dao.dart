import 'package:chat/database/database_helper.dart';
import 'package:chat/database/modals/chat_participant_modal.dart';
import 'package:sqflite/sqflite.dart';

class ChatParticipantsDao {
  final table = 'chat_participants';

  Future<int> insertParticipant(ChatParticipantModal participant) async {
    final db = await DatabaseHelper().database;
    return await db.insert(table, participant.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatParticipantModal>> getParticipantsByChat(int chatId) async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      table,
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
    return result.map((row) => ChatParticipantModal.fromMap(row)).toList();
  }

  Future<int> deleteParticipant(int id) async {
    final db = await DatabaseHelper().database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
