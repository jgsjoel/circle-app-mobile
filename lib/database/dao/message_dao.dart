import 'package:chat/database/dao/chat_dao.dart';
import 'package:chat/database/database_helper.dart';
import 'package:chat/database/db_modals/chat_modal.dart';
import 'package:chat/database/db_modals/message_modal.dart';
import 'package:chat/dtos/status_update_content.dart';
import 'package:chat/services/service_locator.dart';
import 'package:sqflite/sqflite.dart';

class MessageDao {
  final table = 'message';
  final ChatDao _chatDao = getIt<ChatDao>();

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

  Future<int> updateMessageAndChat(StatusUpdateContent content) async {
    final db = await DatabaseHelper().database;

    //update the chat table
    _chatDao.updateChat(ChatModal(id: content.chatId, isGroup: false,publicChatId: content.pubChatId));

    //update the message tabe
    return await db.update(
      table,
      {'status': "SENT",'msg_pub_id':content.pubMsgId},
      where: 'id = ?',
      whereArgs: [content.messageId],
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
