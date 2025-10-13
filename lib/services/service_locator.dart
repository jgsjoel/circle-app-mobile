import 'package:chat/database/dao/chat_dao.dart';
import 'package:chat/database/dao/chat_participant_dao.dart';
import 'package:chat/database/dao/contact_dao.dart';
import 'package:chat/database/dao/message_dao.dart';
import 'package:chat/services/auth_service.dart';
import 'package:chat/services/chat_service.dart';
import 'package:chat/services/contact_service.dart';
import 'package:chat/database/database_helper.dart';
import 'package:chat/services/message_serivce.dart';
import 'package:chat/services/profile_update_service.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/webSock_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<ProfileUpdateService>(
    () => ProfileUpdateService(),
  );
  getIt.registerLazySingleton<ContactService>(() => ContactService());
  getIt.registerLazySingleton<SecureStoreService>(() => SecureStoreService());
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  getIt.registerLazySingleton<MessageService>(()=> MessageService());
  getIt.registerLazySingleton<ChatService>(()=> ChatService());

  getIt.registerLazySingleton<ContactDao>(() => ContactDao());
  getIt.registerLazySingleton<MessageDao>(() => MessageDao());
  getIt.registerLazySingleton<ChatDao>(() => ChatDao());
  getIt.registerLazySingleton<ChatParticipantsDao>(() => ChatParticipantsDao());

  getIt.registerLazySingleton<WebSocketService>(()=>WebSocketService());
}
