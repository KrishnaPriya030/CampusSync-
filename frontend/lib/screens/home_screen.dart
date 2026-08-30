import 'package:flutter/material.dart';
import 'package:frontend/models/user_profile.dart';

import '../storage/token_storage.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required UserProfile user});

  @override
  Widget build(BuildContext context) {
    final TokenStorage tokenStorage =
        TokenStorage();

    Future<void> logout() async {
      // Remove the saved JWT.
      await tokenStorage.clearToken();

      if (!context.mounted) return;

      // Remove all previous authenticated screens
      // and return to Login.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFF080B1F),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF080B1F),
        foregroundColor:
            Colors.white,

        title: const Text(
          'CampusSync Home',
        ),

        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
        ],
      ),

      body: const Center(
        child: Text(
          'CampusSync Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}