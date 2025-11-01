import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MediaDownloadService {
  static final MediaDownloadService _instance = MediaDownloadService._internal();
  static MediaDownloadService get instance => _instance;
  final _dio = Dio();

  MediaDownloadService._internal();

  Future<String?> downloadAndCacheMedia(String url, String publicId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(publicId);
      final filePath = path.join(tempDir.path, fileName);

      // Check if file already exists in cache
      if (await File(filePath).exists()) {
        return filePath;
      }

      // Download file
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      // Save to cache
      final file = File(filePath);
      await file.writeAsBytes(response.data);
      return filePath;
    } catch (e) {
      print("❌ Failed to download media: $e");
      return null;
    }
  }
}