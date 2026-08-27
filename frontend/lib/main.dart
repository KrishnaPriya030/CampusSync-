import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';

import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CampusSyncApp());
}

class CampusSyncApp extends StatelessWidget {
  const CampusSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusSync',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6)),
      ),
      
      home: SplashScreen(),
    );
  }
}
