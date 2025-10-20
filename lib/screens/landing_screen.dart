import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // for Platform
import 'package:device_info_plus/device_info_plus.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _checkPermissionsAndProceed(BuildContext context) async {
    PermissionStatus contactsStatus = await Permission.contacts.request();

    PermissionStatus mediaStatus;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+ → request Photos, Videos, Audio
        final statusImages = await Permission.photos.request();
        final statusVideos = await Permission.videos.request();
        final statusAudio = await Permission.audio.request();

        mediaStatus =
            (statusImages.isGranted &&
                    statusVideos.isGranted &&
                    statusAudio.isGranted)
                ? PermissionStatus.granted
                : PermissionStatus.denied;
      } else {
        // Android < 13 → request Storage
        mediaStatus = await Permission.storage.request();
      }
    } else {
      // iOS → request Photos, Videos
      final statusImages = await Permission.photos.request();
      final statusVideos = await Permission.videos.request();

      mediaStatus =
          (statusImages.isGranted && statusVideos.isGranted)
              ? PermissionStatus.granted
              : PermissionStatus.denied;
    }

    if (contactsStatus.isGranted && mediaStatus.isGranted) {
      Navigator.pushNamed(context, "/phone_verification");
    } else if (contactsStatus.isPermanentlyDenied ||
        mediaStatus.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Permissions Required"),
              content: const Text(
                "You've permanently denied required permissions.\nPlease enable them from app settings.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await openAppSettings();
                  },
                  child: const Text("Open Settings"),
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please grant all permissions to continue'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 70),
                  const Text(
                    "Welcome To Circle",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height / 8),
                  Image.asset("assets/images/bg.png"),
                ],
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 4, 117, 209),
                  ),
                  onPressed: () => _checkPermissionsAndProceed(context),
                  child: const Text("Let's Get Started"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
