import 'package:chat/database/database_helper.dart';
import 'package:chat/database/modals/chat_modal.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:sqflite/sqflite.dart';

class ChatDao {
  final table = 'chat_table';

  Future<int> insertChat(ChatModal chat) async {
    final db = await DatabaseHelper().database;
    return await db.insert(
      table,
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatDto>> getAllChats() async {
    final db = await DatabaseHelper().database;
    final myPublicId = await SecureStoreService.getPublicUserId();

    final res1 = await db.rawQuery('SELECT COUNT(*) AS count FROM chat_table');
    print("----------count: ${Sqflite.firstIntValue(res1) ?? 0}");

    final result = await db.rawQuery(
      '''
      SELECT 
        c.id,
        c.public_chat_id,
        c.is_group,
        CASE 
            WHEN c.is_group = 1 THEN c.name
            ELSE cl.name
        END AS display_name,
        cl.public_id AS public_user_id,
        CASE
            WHEN c.is_group = 1 THEN NULL
            ELSE cl.phone
        END AS phone,
        m.message AS last_message,
        m.timestamp AS last_message_time,
        (
            SELECT COUNT(*) 
            FROM message 
            WHERE chat_id = c.id AND status = 'received'
        ) AS unread_count
      FROM chat_table c
      LEFT JOIN chat_participants cp 
          ON cp.chat_id = c.id
      LEFT JOIN contact_list cl 
          ON cl.public_id = cp.contact_public_id
      LEFT JOIN message m 
          ON m.id = (
              SELECT id 
              FROM message 
              WHERE chat_id = c.id
              ORDER BY timestamp DESC 
              LIMIT 1
          )
      WHERE c.is_group = 1 OR cl.public_id != ?
      GROUP BY c.id
      ORDER BY last_message_time DESC;;
  ''',
      [myPublicId],
    );

    print(result);

    return result.map((row) {
      print(
        "${row['id']} ${row['display_name']} ${row['is_group']} ${row['public_chat_id']} ${row['phone']} ${row['public_user_id']} ${row['last_message']} ${row['unread_count']}",
      );
      return ChatDto(
        id: row['id'] as String?,
        name: row['display_name'] as String,
        isGroup: (row['is_group'] as int) == 1,
        pubChatId: row['public_chat_id'] as String?,
        publicUserId: row['public_user_id'] as String,
        phone: row['phone'] as String?,
        lastMessage: row['last_message'] as String?,
        time: row['last_message_time']?.toString(),
        messageCount: row['unread_count'] as int?, // <-- NEW
      );
    }).toList();

  }

  Future<ChatModal?> getChatById(String id) async {
    final db = await DatabaseHelper().database;
    final result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? ChatModal.fromMap(result.first) : null;
  }

  Future<int> updateChat(ChatModal chat) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      table,
      chat.toMap(),
      where: 'id = ?',
      whereArgs: [chat.id],
    );
  }

  Future<int> deleteChat(String id) async {
    final db = await DatabaseHelper().database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Find existing chat between two participants (for 1-on-1 chats)
  Future<ChatModal?> findChatBetweenParticipants(String participant1Id, String participant2Id) async {
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery('''
      SELECT c.* FROM chat_table c
      INNER JOIN chat_participants p1 ON c.id = p1.chat_id
      INNER JOIN chat_participants p2 ON c.id = p2.chat_id
      WHERE p1.contact_public_id = ? 
        AND p2.contact_public_id = ? 
        AND c.is_group = 0
      LIMIT 1
    ''', [participant1Id, participant2Id]);
    
    return result.isNotEmpty ? ChatModal.fromMap(result.first) : null;
  }
}
