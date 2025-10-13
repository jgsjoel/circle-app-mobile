import 'dart:async';
import 'dart:io';
import 'package:chat/services/secure_store_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:connectivity_plus/connectivity_plus.dart';

class WebSocketService {
  IOWebSocketChannel? _channel;
  StreamSubscription? _connectivitySub;
  bool _isManuallyClosed = false;
  bool _isConnected = false;

  final _controller = StreamController<String>.broadcast();
  Stream<String> get messages => _controller.stream;

  WebSocketService();

  Future<void> connect() async {
    if (_isConnected) return;

    final token = await SecureStoreService.getToken();

    try {
      print("🔌 Connecting to WebSocket: ");
      final url = "ws://192.168.1.5:8001/ws/chat?token=$token";
      final socket = await WebSocket.connect(url);
      _channel = IOWebSocketChannel(socket);
      _isConnected = true;
      _isManuallyClosed = false;

      _channel!.stream.listen(
        (data) {
          // print("📩 Message received: $data");
          _controller.add(data);
        },
        onDone: () {
          print("⚠️ Connection closed. Trying to reconnect...");
          _isConnected = false;
          if (!_isManuallyClosed) _reconnect();
        },
        onError: (error) {
          print("❌ WebSocket error: $error");
          _isConnected = false;
          if (!_isManuallyClosed) _reconnect();
        },
      );
    } catch (e) {
      print("❌ Connection failed: $e");
      _isConnected = false;
      _reconnect();
    }

    // Optional: Watch for network changes
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Check if any of the results indicate a connection
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && !_isConnected) {
        print("🌐 Network restored, reconnecting...");
        _reconnect();
      }
    });
  }

  void send(String message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(message);
    } else {
      print("⚠️ Can't send — WebSocket not connected");
    }
  }

  void _reconnect([int attempt = 1]) {
    final delay = Duration(seconds: (attempt * 2).clamp(2, 30));
    print("⏳ Reconnecting in ${delay.inSeconds}s (attempt $attempt)...");
    Future.delayed(delay, () async {
      if (!_isManuallyClosed) {
        await connect();
      }
    });
  }

  Future<void> close() async {
    _isManuallyClosed = true;
    _isConnected = false;
    await _connectivitySub?.cancel();
    await _channel?.sink.close(status.normalClosure);
    await _controller.close();
    print("🔌 WebSocket connection closed manually.");
  }
}
