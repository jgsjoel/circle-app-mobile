import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStoreService {
  static const _storage = FlutterSecureStorage();

  static const _jwtKey = 'jwt_token';
  static const _keyUsername = 'cached_username';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _jwtKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _jwtKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _jwtKey);
  }

  // Delete all tokens
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<String> getPublicUserId() async {
    String? token = await getToken();

    // Split the token
    final parts = token!.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    // Decode the payload
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final Map<String, dynamic> payloadMap = json.decode(payload);

    // Get the subject
    return payloadMap['sub'];
    
  }

  static Future<void> saveUsername(String username) async {
    await _storage.write(key: _keyUsername, value: username);
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: _keyUsername);
  }

  static Future<void> deleteUsername() async {
    await _storage.delete(key: _keyUsername);
  }
}
