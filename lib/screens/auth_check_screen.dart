import 'package:chat/services/secure_store_service.dart';
import 'package:flutter/material.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Get the token
    final token = await SecureStoreService.getToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Token exists → navigate to home
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      // No token → navigate to landing
      Navigator.pushReplacementNamed(context, "/landing");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

