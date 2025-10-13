// websocket_provider.dart
import 'dart:async';

import 'package:chat/services/webSock_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WebSocketNotifier extends StateNotifier<WebSocketService?> {
  final Ref ref;
  WebSocketNotifier(this.ref) : super(null);

  Stream<String>? get messages => state?.messages;

  StreamSubscription<String>? _subscription;

  Future<void> connect() async {
    final service = WebSocketService();
    await service.connect();
    state = service;

    // Listen to incoming messages here
    _subscription = state!.messages.listen((msg) {
      print("📩 Incoming message in state: $msg");

      // Parse and perform actions
      _handleMessage(msg);
    });
  }

  void _handleMessage(String msg) {
    // Example: parse JSON and route based on type
    // final decoded = json.decode(msg);
    // if (decoded['type'] == 'NEW_MESSAGE') { ... }

    // Or trigger Riverpod providers, update UI state, etc.
  }

  void send(String message) => state?.send(message);

  void disconnect() {
    state?.close();
    state = null;
  }
}

final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketService?>(
  (ref) => WebSocketNotifier(ref),
);

