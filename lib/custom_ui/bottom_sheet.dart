import 'package:flutter/material.dart';

class CustomBottomSheet {
  static void show(BuildContext context) {
    buildInlineSheet(context);
  }

  static Widget buildInlineSheet(BuildContext context) {
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
            print("Gallery pressed");
          }),
          _buildAttachmentOption(context, Icons.headset, "Audio", () {
            print("Audio pressed");
          }),
          _buildAttachmentOption(context, Icons.person, "Contact", () {
            print("Contact pressed");
          }),
        ],
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
