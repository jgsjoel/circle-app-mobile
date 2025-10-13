import 'package:chat/provider/ws_provider.dart';
import 'package:chat/services/contact_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:chat/tabs/ChatsTab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Homescreen extends ConsumerStatefulWidget {
  const Homescreen({super.key});

  @override
  ConsumerState<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends ConsumerState<Homescreen>
  with SingleTickerProviderStateMixin {
  late TabController controller;

  ContactService _profileService = getIt<ContactService>();

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this, initialIndex: 0);
    _profileService.syncContacts();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(webSocketProvider.notifier).connect();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        // backgroundColor: Color(0xFF121B22),
        title: Text("EchoChat"),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(child: Text("New Group"), value: "New Group"),
                PopupMenuItem(child: Text("Settings"), value: "Settings"),
              ];
            },
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
