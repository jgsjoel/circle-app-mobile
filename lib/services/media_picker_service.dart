import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/media_selection.dart';

class MediaPickerService {
  static final ImagePicker _imagePicker = ImagePicker();
  static final _uuid = const Uuid();

  /// Pick multiple images
  static Future<List<MediaFile>> pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      final List<MediaFile> mediaFiles = [];

      for (final XFile image in images) {
        final file = File(image.path);
        final stat = await file.stat();
        
        final mediaFile = MediaFile(
          id: _uuid.v4(),
          file: file,
          type: MediaType.image,
          name: image.name,
          size: stat.size,
        );

        if (mediaFile.isValidSize) {
          mediaFiles.add(mediaFile);
        }
      }

      return mediaFiles;
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  /// Pick single video
  static Future<MediaFile?> pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // 10 minute limit
      );

      if (video != null) {
        final file = File(video.path);
        final stat = await file.stat();
        
        final mediaFile = MediaFile(
          id: _uuid.v4(),
          file: file,
          type: MediaType.video,
          name: video.name,
          size: stat.size,
        );

        return mediaFile.isValidSize ? mediaFile : null;
      }

      return null;
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Pick single audio file
  static Future<MediaFile?> pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final stat = await file.stat();
        
        final mediaFile = MediaFile(
          id: _uuid.v4(),
          file: file,
          type: MediaType.audio,
          name: result.files.first.name,
          size: stat.size,
        );

        return mediaFile.isValidSize ? mediaFile : null;
      }

      return null;
    } catch (e) {
      debugPrint('Error picking audio: $e');
      return null;
    }
  }

  /// Generate thumbnail for video
  static Future<String?> generateVideoThumbnail(String videoPath) async {
    // This would typically use a video thumbnail generation library
    // For now, we'll return null and handle it in the UI
    return null;
  }
}

