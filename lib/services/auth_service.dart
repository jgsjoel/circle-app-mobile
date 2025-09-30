import 'package:chat/services/api_service.dart';
import 'package:chat/services/secure_store_service.dart';
import 'package:dio/dio.dart';

class AuthService {
  final _dio = ApiService.instance.dio;

  Future<void> requestOtp(String name, String mobile) async {
    try {
      await SecureStoreService.saveUsername(name);

      final response = await _dio.post(
        "/auth/request-otp",
        data: {"mobile": mobile},
        options: Options(
          extra: {
            'requiresAuth': false, // OTP request shouldn't require a token
          },
        ),
      );

      print("OTP sent successfully: ${response.data}");
    } on DioException catch (e) {
      print("Failed to request OTP: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }

  Future<String?> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final cachedUsername = await SecureStoreService.getUsername();
      final response = await _dio.post(
        "/auth/verify-otp",
        data: {"mobile": mobile, "otp": otp, "name": cachedUsername},
        options: Options(
          extra: {
            'requiresAuth': false, // No token needed yet
          },
        ),
      );

      // Expecting { "token": "..." }
      final token = response.data['token'] as String?;

      if (token != null) {
        await SecureStoreService.saveToken(token); // Save it if needed
        print("Token received: $token");
        return token;
      }

      print("No token received.");
      return null;
    } on DioException catch (e) {
      print("OTP verification failed: ${e.response?.data ?? e.message}");
      rethrow;
    }
  }
}
