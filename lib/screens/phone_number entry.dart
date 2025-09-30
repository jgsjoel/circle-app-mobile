import 'package:chat/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'otp_verification_screen.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _controller = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? validateSriLankanMobile(String value) {
    final regex = RegExp(r'^7[0-8][0-9]{7}$');
    if (!regex.hasMatch(value)) {
      return 'Enter a valid Sri Lankan mobile number';
    }
    return null;
  }

  String? validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final mobile = _controller.text.trim();

      final authService = GetIt.I<AuthService>();

      try {
        await authService.requestOtp(name, mobile);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(phoneNumber: mobile),
          ),
        );
      } catch (e) {
        // Show error dialog/snackbar
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to send OTP")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF111B21),
        appBar: AppBar(
          title: const Text('Enter your phone number'),
          backgroundColor: const Color(0xFF1F2C34),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  maxLength: 20,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter user Name',
                    hintStyle: TextStyle(color: Colors.white54),
                    counterText: '',
                  ),
                  validator:
                      (value) => value != null ? validateName(value) : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 9, // only 9 digits after +94
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter mobile number',
                    prefixText: '+94 ',
                    hintStyle: TextStyle(color: Colors.white54),
                    counterText: '',
                  ),
                  validator:
                      (value) =>
                          value != null ? validateSriLankanMobile(value) : null,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 4, 117, 209),
                    ),
                    onPressed: _submit,
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
