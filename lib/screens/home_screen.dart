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
  final ContactService _profileService = getIt<ContactService>();

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this, initialIndex: 0);
    _profileService.syncContacts();

    // ✅ Connect websocket after frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wsNotifier = ref.read(webSocketProvider.notifier);
      await wsNotifier.connect();
      print("✅ WebSocket connected from HomeScreen");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Circle"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          PopupMenuButton(
            itemBuilder: (context) => const [
              PopupMenuItem(value: "New Group", child: Text("New Group")),
              PopupMenuItem(value: "Settings", child: Text("Settings")),
            ],
          ),
        ],
        bottom: TabBar(
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          controller: controller,
          tabs: const [
            Tab(text: "Chats"),
            Tab(text: "Calls"),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: const [
          Chatstab(),
          Text("Calls"),
        ],
      ),
    );
  }
}
