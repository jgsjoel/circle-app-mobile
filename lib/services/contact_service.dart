import 'dart:convert';

import 'package:chat/database/modals/contact_modal.dart';
import 'package:chat/services/api_service.dart';
import 'package:chat/database/dao/contact_dao.dart';
import 'package:chat/services/service_locator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {
  final ContactDao _contactDao = getIt<ContactDao>();
  final _dio = ApiService.instance.dio;

  Future<void> syncContacts() async {
    if (!await FlutterContacts.requestPermission()) return;

    // get all phone book contacts
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    List<ContactModal> contactList = _sanitizeContacts(contacts);

    //get all local db contacts
    List<ContactModal> localContacts = await _contactDao.getAllContacts();

    //if not available then send to server and save the returned ones
    if (localContacts.isEmpty) {
      await _syncWithRemoteDb(contactList);
      return;
    }

    //check for name changes for each number and update local db
    await _syncWithLocalContacts(contactList, localContacts);

    //sends unsaved contacts to db and saves the result
    await _syncUnSavedContacts(contactList, localContacts);
  }

  //works
  List<ContactModal> _sanitizeContacts(List<Contact> contacts) {
    final List<ContactModal> contactList = [];

    for (final contact in contacts) {
      final name = contact.displayName;
      for (final phone in contact.phones) {
        String rawNumber = phone.normalizedNumber;
        if (rawNumber.startsWith('+94')) {
          String number = rawNumber.replaceAll(RegExp(r'\D'), '');
          number = number.substring(2);
          if (number.isNotEmpty) {
            contactList.add(ContactModal(name: name, phone: number));
          }
        }
      }
    }

    return contactList;
  }

  //works
  Future<void> _syncWithLocalContacts(
    List<ContactModal> phoneBook,
    List<ContactModal> local,
  ) async {
    print("------------------called--------------------");

    final localMap = {for (var c in local) c.phone: c};

    for (var contact in phoneBook) {
      final localEntry = localMap[contact.phone];
      if (localEntry != null && localEntry.name != contact.name) {
        // Preserve existing public_id
        final updatedContact = ContactModal(
          name: contact.name,
          phone: contact.phone,
          pubContactId: localEntry.pubContactId,
        );

        await _contactDao.updateContact(updatedContact);
      }
    }
  }

  // --------------------------
  // Insert new contacts locally and send them to server
  // --------------------------
  Future<void> _syncUnSavedContacts(
    List<ContactModal> phoneBook,
    List<ContactModal> local,
  ) async {
    final localPhones = local.map((c) => c.phone).toSet();

    final unsyncedContacts =
        phoneBook.where((c) => !localPhones.contains(c.phone)).toList();

    if (unsyncedContacts.isEmpty) return;

    await _syncWithRemoteDb(unsyncedContacts);
  }

  // this works
  Future<void> _syncWithRemoteDb(List<ContactModal> contactList) async {
    try {
      final contactsJson = jsonEncode(
        contactList.map((c) => c.toMap()).toList(),
      );
      final Uint8List binaryData = utf8.encode(contactsJson);

      final response = await _dio.post(
        "/users/sync-contacts",
        data: Stream.fromIterable([binaryData]),
        options: Options(
          headers: {"Content-Type": "application/octet-stream"},
          extra: {'requiresAuth': true},
        ),
      );

      // Decode server response (assumes JSON string)
      final Map<String, dynamic> responseMap =
          response.data is String ? jsonDecode(response.data) : response.data;

      // Extract the list of contacts
      final List<dynamic> responseList =
          responseMap['contacts'] as List<dynamic>;

      // Convert response to ContactModal objects
      final List<ContactModal> returnedContacts =
          responseList
              .map((c) => ContactModal.fromMap(c as Map<String, dynamic>))
              .toList();

      // Save to local database
      for (var contact in returnedContacts) {
        await _contactDao.insertContact(contact);
      }
    } on DioException catch (e) {
      print("----------Here---------");
      print(e.message);
      print("Failed to sync contacts: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }
}
