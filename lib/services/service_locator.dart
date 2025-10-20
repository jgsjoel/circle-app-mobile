import 'package:chat/database/database_helper.dart';
import 'package:chat/database/isar_dao/chat_isar_dao.dart';
import 'package:chat/database/isar_dao/chat_participant_isar_dao.dart';
import 'package:chat/database/isar_dao/contact_isar_dao.dart';
import 'package:chat/database/isar_dao/media_file_isar_dao.dart';
import 'package:chat/database/isar_dao/message_isar_dao.dart';
import 'package:chat/database/isar_setup.dart';
import 'package:chat/services/auth_service.dart';
import 'package:chat/services/chat_service.dart';
import 'package:chat/services/contact_service.dart';
import 'package:chat/services/message_serivce.dart';
import 'package:chat/services/profile_update_service.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/webSock_service.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Initialize Isar
  final isarSetup = IsarSetup();
  await isarSetup.init();

  // Register Isar instance
  getIt.registerSingleton<Isar>(isarSetup.db);

  // Register services
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<ProfileUpdateService>(() => ProfileUpdateService());
  getIt.registerLazySingleton<ContactService>(() => ContactService());
  getIt.registerLazySingleton<SecureStoreService>(() => SecureStoreService());
  getIt.registerLazySingleton<MessageService>(() => MessageService());
  getIt.registerLazySingleton<ChatService>(() => ChatService());
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());

  // Register DAOs
  getIt.registerLazySingleton<ContactIsarDao>(() => ContactIsarDao());
  getIt.registerLazySingleton<MediaFileIsarDao>(() => MediaFileIsarDao());
  getIt.registerLazySingleton<MessageIsarDao>(() => MessageIsarDao());
  getIt.registerLazySingleton<ChatIsarDao>(() => ChatIsarDao());
  getIt.registerLazySingleton<ChatParticipantIsarDao>(() => ChatParticipantIsarDao());

  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

}
