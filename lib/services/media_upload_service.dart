import 'dart:io';
import 'package:chat/models/media_selection.dart';
import 'package:chat/services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

class MediaUploadService {
  static final MediaUploadService _instance = MediaUploadService._internal();
  static MediaUploadService get instance => _instance;
  final _dio = Dio();
  final authDio = ApiService.instance.dio;

  MediaUploadService._internal();

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<Map<String, dynamic>> getSignedUrls(
    String chatId,
    List<MediaFile> mediaFiles,
  ) async {
    try {
      print("🔄 Getting signed URLs for chat: $chatId");
      final response = await authDio.post(
        '/messages/signed-url/$chatId',
        data: {
          'files':
              mediaFiles
                  .map(
                    (file) => {
                      'name': path.basename(file.file.path),
                      'type':
                          file.type.toString().split('.').last.toLowerCase(),
                      'size': file.size,
                    },
                  )
                  .toList(),
        },
        options: Options(
          extra: {'requiresAuth': true},
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        print("✅ Got signed URLs response: ${response.data}");
        return response.data;
      }

      throw Exception('Failed to get signed URLs: ${response.statusCode}');
    } catch (e) {
      print("❌ Error getting signed URLs: $e");
      rethrow;
    }
  }

  Future<MediaFile> compressMedia(MediaFile mediaFile) async {
    if (mediaFile.type == MediaType.image) {
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        '${path.basenameWithoutExtension(mediaFile.file.path)}_compressed.jpg',
      );

      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        mediaFile.file.path,
        targetPath,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile != null) {
        final compressedFile = File(compressedXFile.path);
        return mediaFile.copyWith(
          file: compressedFile,
          size: await compressedFile.length(),
        );
      }
      return mediaFile;
    } else if (mediaFile.type == MediaType.video) {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        mediaFile.file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (mediaInfo?.file != null) {
        return mediaFile.copyWith(
          file: mediaInfo!.file!,
          size: await mediaInfo.file!.length(),
        );
      }
    }
    return mediaFile;
  }

  Future<List<MediaFile>> handleMediaUpload(
    List<MediaFile> mediaFiles,
    String chatId,
  ) async {
    if (!await hasInternetConnection()) {
      throw Exception('No internet connection available');
    }

    // Compress files
    final compressedFiles = await Future.wait(
      mediaFiles.map((file) => compressMedia(file)),
    );

    print("🔄 Getting signed URLs for ${compressedFiles.length} files");
    final signedUrlsResponse = await getSignedUrls(chatId, compressedFiles);
    final urls = signedUrlsResponse['urls'] as List;
    print("🔄 Uploading ${urls.length} files to Cloudinary");

    final uploadResults = await Future.wait(
      List.generate(compressedFiles.length, (index) async {
        final file = compressedFiles[index];
        final urlInfo = urls[index] as Map<String, dynamic>;

        try {
          print("🔄 Starting upload for file ${index + 1}");

          final isVideo = file.type == MediaType.video;
          final uploadUrl =
              "https://api.cloudinary.com/v1_1/${urlInfo['cloudName']}/${isVideo ? 'video' : 'image'}/upload";

          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(file.file.path),
            'api_key': urlInfo['apiKey'],
            'timestamp': urlInfo['timestamp'],
            'signature': urlInfo['signature'],
            'folder': urlInfo['folder'],
            'public_id': urlInfo['publicId'],
            // THIS IS KEY FOR VIDEO UPLOADS:
            if (isVideo) 'resource_type': 'video',
          });

          final response = await _dio.post(
            uploadUrl,
            data: formData,
            options: Options(
              contentType: 'multipart/form-data',
              validateStatus: (status) => status! < 500,
            ),
          );

          print("📌 Response status: ${response.statusCode}");
          if (response.statusCode == 200 || response.statusCode == 201) {
            print("✅ Successfully uploaded file ${index + 1}");
            // Capture both secure_url and public_id from Cloudinary response
            final cloudinaryUrl = response.data['secure_url'] as String;
            final publicId = urlInfo['publicId'] as String;
            return file.copyWith(
              file: file.file, 
              id: publicId,
              url: cloudinaryUrl,
              localPath: file.file.path  // Save the local compressed file path
            );
          } else {
            print("⚠️ Upload failed with status ${response.statusCode}");
            print("⚠️ Response data: ${response.data}");
            throw Exception('Upload failed with status ${response.statusCode}');
          }
        } catch (e) {
          print("❌ Failed to upload file ${index + 1}: $e");
          rethrow;
        }
      }),
    );

    return uploadResults;
  }

  // Upload media files to Cloudinary and return URLs
  Future<List<String>> uploadMediaToCloudinary(
    List<MediaFile> mediaFiles,
    List<dynamic> signedUrls,
  ) async {
    final uploadedUrls = <String>[];

    for (int index = 0; index < mediaFiles.length; index++) {
      final file = mediaFiles[index];
      final urlInfo = signedUrls[index] as Map<String, dynamic>;

      final isVideo = file.type == MediaType.video;
      final uploadUrl =
          "https://api.cloudinary.com/v1_1/${urlInfo['cloudName']}/${isVideo ? 'video' : 'image'}/upload";

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.file.path),
        'api_key': urlInfo['apiKey'],
        'timestamp': urlInfo['timestamp'],
        'signature': urlInfo['signature'],
        'folder': urlInfo['folder'],
        'public_id': urlInfo['publicId'],
        if (isVideo) 'resource_type': 'video',
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          validateStatus: (status) => status! < 500,
        ),
        onSendProgress: (sent, total) {
          if (total != -1) {
            final progress = (sent / total * 100).toStringAsFixed(0);
            print("📤 Upload progress for file ${index + 1}: $progress%");
            // You can emit this progress to a stream for UI updates
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final cloudinaryUrl = response.data['secure_url'] as String;
        uploadedUrls.add(cloudinaryUrl);
        print("✅ Successfully uploaded file ${index + 1}: $cloudinaryUrl");
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    }

    return uploadedUrls;
  }
}
