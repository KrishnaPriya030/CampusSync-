import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../storage/token_storage.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TokenStorage tokenStorage =
      TokenStorage();

  final AuthService authService =
      AuthService();

  @override
  void initState() {
    super.initState();

    checkSession();
  }

  Future<void> checkSession() async {
    debugPrint(
      'SPLASH: checkSession started',
    );

    try {
      final token =
          await tokenStorage.getToken();

      debugPrint(
        'SPLASH: token exists = ${token != null}',
      );

      if (!mounted) return;

      // No saved token → Login
      if (token == null) {
        debugPrint(
          'SPLASH: no token → Login',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(),
          ),
        );

        return;
      }

      // Token exists → verify it with backend
      debugPrint(
        'SPLASH: token found → calling /api/users/me',
      );

      final user =
          await authService.getCurrentUser(
        token,
      );

      debugPrint(
        'SPLASH: /api/users/me successful',
      );

      debugPrint(
        'SPLASH: user = ${user.email}',
      );

      if (!mounted) return;

      // Valid token → Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const HomeScreen(),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        'SPLASH ERROR: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      // Invalid/expired token or request failure
      await tokenStorage.clearToken();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF060917),
              Color(0xFF0B1430),
              Color(0xFF171033),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top-right soft glow
              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF8B5CF6,
                    ).withOpacity(0.16),
                  ),
                ),
              ),

              // Bottom-left soft glow
              Positioned(
                bottom: -120,
                left: -100,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF3B82F6,
                    ).withOpacity(0.10),
                  ),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    // Glass logo
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 18,
                          sigmaY: 18,
                        ),
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration:
                              BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                            border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(
                                  0xFF8B5CF6,
                                ).withOpacity(0.20),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    const Text(
                      'CampusSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Smart Event Coordination',
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.60),
                        fontSize: 14,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(
                      height: 42,
                    ),

                    const SizedBox(
                      width: 26,
                      height: 26,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color:
                            Color(0xFFB8A4FF),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Text(
                      'Preparing your campus experience...',
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.42),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Text(
                  'CampusSync',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.25),
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}