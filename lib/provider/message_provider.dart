import 'package:chat/services/message_serivce.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messageServiceProvider = Provider<MessageService>((ref) => MessageService(ref));