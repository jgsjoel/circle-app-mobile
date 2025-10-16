// websocket_provider.dart
import 'dart:async';
import 'dart:convert';

import 'package:chat/database/dao/media_file_dao.dart';
import 'package:chat/database/dao/message_dao.dart';
import 'package:chat/database/modals/MediaFileModal.dart';
import 'package:chat/database/modals/message_modal.dart';
import 'package:chat/dtos/incomming_messages.dart';
import 'package:chat/dtos/message_content.dart';
import 'package:chat/dtos/message_type.dart';
import 'package:chat/dtos/status_update_content.dart';
import 'package:chat/services/service_locator.dart';
import 'package:chat/services/webSock_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class WebSocketNotifier extends StateNotifier<WebSocketService?> {
  final Ref ref;
  WebSocketNotifier(this.ref) : super(null);

  Stream<String>? get messages => state?.messages;

  StreamSubscription<String>? _subscription;
  final MessageDao _messageDao = getIt<MessageDao>();
  final MediaFileDao _mediaDao = getIt<MediaFileDao>();

  Future<void> connect() async {
    final service = WebSocketService();
    await service.connect();
    state = service;

    // Listen to incoming messages here
    _subscription = state!.messages.listen((msg) {
      // print("📩 Incoming message in state: $msg");
      _handleMessage(msg);
    });
  }

  void _handleMessage(String msg) async {
    try {
      final incoming = IncomingMessage.fromRawJson(msg);
      print(incoming);

      for (final content in incoming.content) {
        switch (incoming.type) {
          case MessageType.MESSAGE:
            saveNewMessages(incoming);
            break;

          case MessageType.STATUS_UPDATE:
            updateMessage(incoming);
            break;

          default:
          print(incoming);
            break;
        }
      }
    } catch (e, st) {
      print('❌ Error handling incoming message: $e');
      print(st);
    }
  }

  void send(String message) => state?.send(message);

  void disconnect() {
    state?.close();
    state = null;
  }

  //update all messages
  void updateMessage(IncomingMessage incoming) async {
    if (incoming.type != MessageType.STATUS_UPDATE) return;
    final contents =
        incoming.content
            .whereType<StatusUpdateContent>()
            .toList();

    for (final content in contents) {
      print(
        "Updating message: ${content.messageId} → ${content.messageStatus}",
      );

      await _messageDao.updateMessageAndChat(content);
    }
  }

  void saveNewMessages(IncomingMessage incoming) async {
    print("here---------------------");
    print(incoming.type);
    if (incoming.type != MessageType.MESSAGE) return;
    print("now here");
    print(incoming);

    final contents = incoming.content.whereType<MessageContent>().toList();
    print(contents);

    for (final content in contents) {
      final messageModel = MessageModal(
        msgPubId: content.messagePubId,
        message: content.message,
        fromMe: false,
        chatId: content.pubChatId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final messageId = await _messageDao.insertMessage(messageModel);
      print("message added: $messageId");

      // Save any attached media
      for (final media in content.mediaDtoList) {
        final mediaFile = MediaFile(
          id: const Uuid().v4(),
          url: media.url,
          publicId: media.publicId,
          messageId: messageId,
        );

        final m = await _mediaDao.insertMediaFile(mediaFile);
        print("media file added: $m");
      }
    }
  }
}

final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketService?>(
      (ref) => WebSocketNotifier(ref),
    );
