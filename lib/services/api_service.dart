import 'package:dio/dio.dart';
import 'package:chat/services/secure_store_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  late final Dio dio;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        // baseUrl: 'http://10.0.2.2:8085', //emulator
        // baseUrl: 'http://192.168.1.5:8001', //physical device
        baseUrl: "http://173.212.207.30:8001",
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 5),
      ),
    )..interceptors.add(
        QueuedInterceptorsWrapper(
          onRequest: (options, handler) async {
            final requiresAuth = options.extra['requiresAuth'] == true;

            if (requiresAuth) {
              final token = await SecureStoreService.getToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }

            return handler.next(options);
          },
          onError: (error, handler) {
            return handler.next(error);
          },
        ),
      );
  }

  static ApiService get instance => _instance;
}
