import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chat/database/db_modals/MediaFileModal.dart';
import 'package:video_player/video_player.dart';

class MediaViewerScreen extends StatefulWidget {
  final MediaFile media;
  const MediaViewerScreen({super.key, required this.media});

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    final type = _getMediaType(widget.media.url);
    if (type == "video") {
      _videoController = VideoPlayerController.file(File(widget.media.url))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    }
  }

  String _getMediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return "image";
    if (['mp4', 'mov', 'avi'].contains(ext)) return "video";
    if (['mp3', 'wav', 'm4a'].contains(ext)) return "audio";
    return "unknown";
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = _getMediaType(widget.media.url);

    Widget body;

    switch (type) {
      case "image":
        body = Center(child: Image.file(File(widget.media.url)));
        break;

      case "video":
        if (_videoController == null || !_videoController!.value.isInitialized) {
          body = const Center(child: CircularProgressIndicator());
        } else {
          body = Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          );
        }
        break;

      case "audio":
        body = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.audiotrack, size: 80),
              const SizedBox(height: 16),
              Text(widget.media.id),
              // Optional: integrate just_audio player
            ],
          ),
        );
        break;

      default:
        body = const Center(child: Text("Cannot preview this file"));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.media.id)),
      body: body,
    );
  }
}
