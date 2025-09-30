import 'dart:io';
import 'package:chat/services/api_service.dart';
import 'package:dio/dio.dart';

class ProfileUpdateService {
  final _dio = Dio();
  final authDio = ApiService.instance.dio;

  Future<void> uploadImageToCloudinary(File file) async {
    try {
      // Step 1: Get signature from your backend
      final sigRes = await authDio.get(
        "/users/signed-url",
        options: Options(extra: {'requiresAuth': true}),
      );

      final data = sigRes.data;
      final timestamp = data['timestamp'];
      final apiKey = data['apiKey'];
      final signature = data['signature'];
      final folder = data['folder'];
      final cloudName = data['cloudName'];
      final imageId = data['image_id']; // <- comes from backend

      // Step 2: Prepare form data
      final multipartFile = await MultipartFile.fromFile(file.path);

      final formData = FormData.fromMap({
        "file": multipartFile,
        "api_key": apiKey,
        "timestamp": timestamp.toString(),
        "signature": signature,
        "folder": folder,
        "public_id":
            "$folder/$imageId", // <- full path like "user_images/abc123"
      });

      // Step 3: Upload to Cloudinary
      final uploadUrl =
          "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      final responseData = response.data;
      final imageUrl = responseData['secure_url'];
      final returnedPublicId = responseData['public_id'];

      await saveImageMetadata(url: imageUrl, publicId: returnedPublicId);

      print("✅ Upload success: ${response.data}");
    } on DioException catch (e) {
      print("❌ Upload failed: ${e.response?.data ?? e.message}");
    }
  }

  Future<void> saveImageMetadata({
    required String url,
    required String publicId,
  }) async {
    try {
      final response = await authDio.post(
        "/users/image-save-update",
        data: {"url": url, "publicId": publicId},
        options: Options(extra: {'requiresAuth': true}),
      );

      print("✅ Metadata saved: ${response.data}");
    } on DioException catch (e) {
      print("❌ Failed to save metadata: ${e.response?.data ?? e.message}");
    }
  }
}
