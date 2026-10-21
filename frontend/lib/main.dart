
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';

void main() {
  runApp(const CampusSyncApp());
}

class CampusSyncApp extends StatelessWidget {
  const CampusSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fragment = Uri.base.fragment;
    final uri = Uri.tryParse(fragment);

    final isResetRoute = uri?.path == '/reset-password';
    final resetToken = uri?.queryParameters['token'] ?? '';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusSync',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
        ),
      ),

      // Use the reset screen directly when a reset link is opened.
      home: isResetRoute
          ? ResetPasswordScreen(token: resetToken)
          : const SplashScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
