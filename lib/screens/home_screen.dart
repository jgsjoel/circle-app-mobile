import 'package:chat/services/contact_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:chat/tabs/ChatsTab.dart';
import 'package:flutter/material.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  final ContactService _profileService = getIt<ContactService>();

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this, initialIndex: 0);
    _profileService.syncContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("EchoChat"),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(child: Text("New Group"), value: "New Group"),
              PopupMenuItem(child: Text("Settings"), value: "Settings"),
            ],
          ),
        ],
        bottom: TabBar(
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          controller: controller,
          tabs: [Tab(text: "Chats"), Tab(text: "Calls")],
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: [Chatstab(), Text("Calls")],
      ),
    );
  }
}
