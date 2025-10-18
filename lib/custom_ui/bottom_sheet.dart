import 'package:flutter/material.dart';
import '../models/media_selection.dart';
import 'media_selection_screen.dart';

class CustomBottomSheet {
  static void show(BuildContext context, Function(List<MediaFile>) onMediaSelected) {
    buildInlineSheet(context, onMediaSelected);
  }

  static Widget buildInlineSheet(BuildContext context, Function(List<MediaFile>) onMediaSelected) {
    return Material(
      color: const Color(0xFF202C33),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20),bottom: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Wrap(
          alignment: WrapAlignment.spaceAround,
          spacing: 24,
          runSpacing: 16,
          children: [
            _buildAttachmentOption(context, Icons.insert_drive_file, "Document", () {
              print("Document pressed");
            }),
            _buildAttachmentOption(context, Icons.photo, "Gallery", () {
              _navigateToMediaSelection(context, MediaType.image, onMediaSelected);
            }),
            _buildAttachmentOption(context, Icons.videocam, "Video", () {
              _navigateToMediaSelection(context, MediaType.video, onMediaSelected);
            }),
            _buildAttachmentOption(context, Icons.headset, "Audio", () {
              _navigateToMediaSelection(context, MediaType.audio, onMediaSelected);
            }),
          ],
        ),
      ),
    );
  }

  static void _navigateToMediaSelection(
    BuildContext context,
    MediaType mediaType,
    Function(List<MediaFile>) onMediaSelected,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaSelectionScreen(
          mediaType: mediaType,
          onMediaSelected: onMediaSelected,
        ),
      ),
    );
  }

  static Widget _buildAttachmentOption(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF25D366),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
