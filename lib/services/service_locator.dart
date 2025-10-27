import 'package:chat/database/daos/contact_dao.dart';
import 'package:chat/database/daos/media_file_dao.dart';
import 'package:chat/database/daos/message_dao.dart';
import 'package:chat/database/daos/chat_dao.dart';
import 'package:chat/database/daos/chat_participan_dao.dart';
import 'package:chat/services/auth_service.dart';
import 'package:chat/services/chat_service.dart';
import 'package:chat/services/contact_service.dart';
import 'package:chat/services/message_serivce.dart';
import 'package:chat/services/profile_update_service.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:chat/services/webSock_service.dart';
import 'package:get_it/get_it.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../objectbox.g.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Initialize ObjectBox
  final docsDir = await getApplicationDocumentsDirectory();
  final store = await openStore(directory: p.join(docsDir.path, "objectbox"));
  
  // Register Store singleton first
  getIt.registerSingleton<Store>(store);

  // Register DAOs first since services depend on them
  getIt.registerLazySingleton<ContactObjectBoxDao>(() => ContactObjectBoxDao());
  getIt.registerLazySingleton<MediaFileObjectBoxDao>(() => MediaFileObjectBoxDao());
  getIt.registerLazySingleton<MessageDao>(() => MessageDao());
  getIt.registerLazySingleton<ChatObjectBoxDao>(() => ChatObjectBoxDao());
  getIt.registerLazySingleton<ChatParticipantObjectBoxDao>(() => ChatParticipantObjectBoxDao());

  // Wait a moment to ensure DAOs are properly initialized
  await Future.delayed(const Duration(milliseconds: 100));

  // Register standalone services that don't depend on DAOs
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<SecureStoreService>(() => SecureStoreService());
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());

  // Register services that depend on DAOs
  getIt.registerLazySingleton<ContactService>(() => ContactService());
  getIt.registerLazySingleton<MessageService>(() => MessageService());
  getIt.registerLazySingleton<ChatService>(() => ChatService());
  getIt.registerLazySingleton<ProfileUpdateService>(() => ProfileUpdateService());
}
