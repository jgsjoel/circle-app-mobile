import 'dart:io';
import 'package:chat/screens/home_screen.dart';
import 'package:chat/services/profile_update_service.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  bool _isLoading = false;
  File? _image;
  final ProfileUpdateService _profileService = getIt<ProfileUpdateService>();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  void _continue() async {
    setState(() => _isLoading = true);

    if (_image != null) {
      try {
        await _profileService.uploadImageToCloudinary(_image!);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
        print(e);
        setState(() => _isLoading = false); // reset loading
        return;
      }
    }

    // Navigate regardless of upload success or no image
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Homescreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        title: const Text("Add profile Picture"),
        backgroundColor: const Color(0xFF1F2C34),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child:
                      _image == null
                          ? const Icon(
                            Icons.camera_alt,
                            color: Colors.white70,
                            size: 30,
                          )
                          : null,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 4, 117, 209),
                  ),
                  onPressed: _isLoading ? null : _continue,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                          : const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
