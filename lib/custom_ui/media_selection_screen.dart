import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/media_selection.dart';
import '../services/media_picker_service.dart';

class MediaSelectionScreen extends StatefulWidget {
  final MediaType mediaType;
  final Function(List<MediaFile>) onMediaSelected;

  const MediaSelectionScreen({
    super.key,
    required this.mediaType,
    required this.onMediaSelected,
  });

  @override
  State<MediaSelectionScreen> createState() => _MediaSelectionScreenState();
}

class _MediaSelectionScreenState extends State<MediaSelectionScreen> {
  final _uuid = const Uuid();
  bool isLoading = false;

  List<MediaFile> selectedMedia = [];
  String? globalCaption;

  // Keep persistent controllers for captions
  final Map<int, TextEditingController> _captionControllers = {};
  final TextEditingController _globalCaptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pickMedia();
  }

  @override
  void dispose() {
    for (final controller in _captionControllers.values) {
      controller.dispose();
    }
    _globalCaptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    setState(() => isLoading = true);

    try {
      switch (widget.mediaType) {
        case MediaType.image:
          final images = await MediaPickerService.pickImages();
          if (images.isNotEmpty) {
            setState(() {
              selectedMedia = images;
              _initControllers();
            });
          } else {
            _showSizeLimitMessage();
          }
          break;

        case MediaType.video:
          final video = await MediaPickerService.pickVideo();
          if (video != null) {
            setState(() {
              selectedMedia = [video];
              _initControllers();
            });
          } else {
            _showSizeLimitMessage();
          }
          break;

        case MediaType.audio:
          final audio = await MediaPickerService.pickAudio();
          if (audio != null) {
            setState(() {
              selectedMedia = [audio];
              _initControllers();
            });
          } else {
            _showSizeLimitMessage();
          }
          break;
      }
    } catch (e) {
      _showErrorMessage('Failed to pick media: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _initControllers() {
    _captionControllers.clear();
    for (int i = 0; i < selectedMedia.length; i++) {
      _captionControllers[i] = TextEditingController(text: selectedMedia[i].caption ?? '');
    }
  }

  void _showSizeLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File size should be no more than 16 MB'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _removeMedia(int index) {
    setState(() {
      selectedMedia.removeAt(index);
      _captionControllers.remove(index);
    });
  }

  void _sendMedia() {
    if (selectedMedia.isEmpty) return;

    List<MediaFile> mediaWithCaptions = selectedMedia;

    if (globalCaption != null && globalCaption!.isNotEmpty) {
      mediaWithCaptions = selectedMedia
          .map((m) => m.copyWith(caption: globalCaption))
          .toList();
    } else {
      mediaWithCaptions = selectedMedia.mapIndexed((i, m) {
        final c = _captionControllers[i]?.text ?? '';
        return m.copyWith(caption: c);
      }).toList();
    }

    widget.onMediaSelected(mediaWithCaptions);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202C33),
        title: Text(
          _getTitle(),
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (selectedMedia.isNotEmpty)
            TextButton(
              onPressed: _sendMedia,
              child: const Text(
                'Send',
                style: TextStyle(
                  color: Color(0xFF25D366),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF25D366),
              ),
            )
          : selectedMedia.isEmpty
              ? const Center(
                  child: Text(
                    'No media selected',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : _buildMediaList(),
    );
  }

  String _getTitle() {
    switch (widget.mediaType) {
      case MediaType.image:
        return 'Selected Images (${selectedMedia.length})';
      case MediaType.video:
        return 'Selected Video';
      case MediaType.audio:
        return 'Selected Audio';
    }
  }

  Widget _buildMediaList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: selectedMedia.length + (selectedMedia.length > 1 ? 1 : 0),
      itemBuilder: (context, index) {
        if (selectedMedia.length > 1 && index == selectedMedia.length) {
          return _buildGlobalCaptionInput();
        }
        return _buildMediaItem(selectedMedia[index], index);
      },
    );
  }

  Widget _buildMediaItem(MediaFile media, int index) {
    return Card(
      color: const Color(0xFF202C33),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaPreview(media),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        media.sizeFormatted,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeMedia(index),
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedMedia.length == 1)
              TextField(
                controller: _captionControllers[index],
                onChanged: (value) =>
                    selectedMedia[index] = selectedMedia[index].copyWith(caption: value),
                decoration: const InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF25D366)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(MediaFile media) {
    switch (media.type) {
      case MediaType.image:
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(media.file),
              fit: BoxFit.cover,
            ),
          ),
        );
      case MediaType.video:
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[800],
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_outline,
                      color: Colors.white, size: 50),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case MediaType.audio:
        return Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF25D366),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.audiotrack, color: Colors.white, size: 40),
              SizedBox(width: 12),
              Text(
                'AUDIO FILE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildGlobalCaptionInput() {
    return Card(
      color: const Color(0xFF202C33),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a caption for all images:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _globalCaptionController,
              onChanged: (value) {
                setState(() {
                  globalCaption = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Add a caption for all images...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF25D366)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// Small helper since mapIndexed isn't built-in
extension _IterableExt<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
}
