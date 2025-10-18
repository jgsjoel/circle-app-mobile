import 'package:chat/database/db_modals/contact_modal.dart';
import 'package:chat/database/database_helper.dart';
import 'package:chat/dtos/chat_dto.dart';
import 'package:sqflite/sqflite.dart';

class ContactDao {
  final table = 'contact_list';

  Future<int> insertContact(ContactModal contact) async {
    final db = await DatabaseHelper().database;
    return await db.insert(
      table,
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ContactModal>> getAllContacts() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(table);
    return result.map((row) => ContactModal.fromMap(row)).toList();
  }

  Future<List<ChatDto>> getAllContactsAndGroups() async {
    final db = await DatabaseHelper().database;

    // 1. Fetch all groups from chat_table
    final groupRows = await db.query(
      'chat_table',
      where: 'is_group = ?',
      whereArgs: [1],
    );

    List<ChatDto> groups = [];
    if (groupRows.isNotEmpty) {
      groups =
          groupRows.map((row) {
            return ChatDto(
              id: row['id'] as String?,
              name: row['name'] as String,
              isGroup: true,
              pubChatId: row['public_chat_id'] as String?,
            );
          }).toList();
    }

    // 2. Fetch all contacts
    final contactRows = await db.query('contact_list');

    final List<ChatDto> contacts = [];

    for (var row in contactRows) {
      final contact = ContactModal.fromMap(row);
      print(row);

      // check if chat_table has an existing chat for this contact
      final chatRows = await db.rawQuery(
        '''
        SELECT c.* FROM chat_table c
        INNER JOIN chat_participants p ON c.id = p.chat_id
        WHERE p.contact_public_id = ? AND c.is_group = 0
      ''',
        [contact.pubContactId],
      );

      if (chatRows.isNotEmpty) {
        print("-------Has a chat--------");
        final chat = chatRows.first;
        contacts.add(
          ChatDto(
            id: chat['id'] as String?,
            name: contact.name,
            isGroup: false,
            phone: "+94 ${contact.phone}",
            pubChatId: chat['public_chat_id'] as String?,
            publicUserId: contact.pubContactId,
          ),
        );
      } else {
        contacts.add(
          ChatDto(
            name: contact.name,
            isGroup: false,
            publicUserId: contact.pubContactId,
            phone: "+94 ${contact.phone}"
          ),
        );
      }
    }

    // 3. Return merged list
    return [...groups, ...contacts];
  }

  Future<ContactModal?> getContactById(String id) async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      table,
      where: 'public_id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? ContactModal.fromMap(result.first) : null;
  }

  Future<int> updateContact(ContactModal contact) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      table,
      contact.toMap(),
      where: 'public_id = ?',
      whereArgs: [contact.pubContactId],
    );
  }

  Future<int> deleteContact(String id) async {
    final db = await DatabaseHelper().database;
    return await db.delete(table, where: 'public_id = ?', whereArgs: [id]);
  }
}
