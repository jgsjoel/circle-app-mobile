import 'package:chat/dtos/chat_dto.dart';
import 'package:chat/screens/message_screen.dart';
import 'package:chat/database/dao/contact_dao.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter/material.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactDao contactDao = getIt<ContactDao>();

  List<ChatDto> _contactsAndChats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<ChatDto> contactsAndChats =
          await contactDao.getAllContactsAndGroups();

      setState(() {
        _contactsAndChats = contactsAndChats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Contacts")),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text("Error: $_error"))
              : _contactsAndChats.isEmpty
              ? Center(child: Text("No contacts found"))
              : ListView.builder(
                itemCount: _contactsAndChats.length,
                itemBuilder: (context, index) {
                  final c = _contactsAndChats[index];
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return MessageScreen(chatDto: c);
                          },
                        ),
                      );
                    },
                    leading: Icon(Icons.person),
                    title: Text(c.name),
                    subtitle: Text(c.phone ?? ""),
                  );
                },
              ),
    );
  }
}
