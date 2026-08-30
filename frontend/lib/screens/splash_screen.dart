import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../storage/token_storage.dart';

import 'admin_dashboard_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'organizer_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TokenStorage tokenStorage = TokenStorage();
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    checkSession();
  }

  // ==========================================================
  // CHECK EXISTING LOGIN SESSION
  // ==========================================================

  Future<void> checkSession() async {
    debugPrint('SPLASH: checkSession started');

    try {
      // ------------------------------------------------------
      // 1. GET SAVED TOKEN
      // ------------------------------------------------------

      final String? token = await tokenStorage.getToken();

      debugPrint(
        'SPLASH: token exists = ${token != null && token.isNotEmpty}',
      );

      // Keep splash screen visible for 3 seconds.
      await Future.delayed(
        const Duration(seconds: 3),
      );

      if (!mounted) return;

      // ------------------------------------------------------
      // 2. NO TOKEN → LOGIN
      // ------------------------------------------------------

      if (token == null || token.isEmpty) {
        debugPrint(
          'SPLASH: no token → LoginScreen',
        );

        _goToLogin();
        return;
      }

      // ------------------------------------------------------
      // 3. VERIFY TOKEN WITH BACKEND
      // ------------------------------------------------------

      debugPrint(
        'SPLASH: token found → verifying /api/users/me',
      );

      final user =
          await authService.getCurrentUser(token);

      debugPrint(
        'SPLASH: token valid',
      );

      debugPrint(
        'SPLASH: user id = ${user.id}',
      );

      debugPrint(
        'SPLASH: user name = ${user.name}',
      );

      debugPrint(
        'SPLASH: user email = ${user.email}',
      );

      debugPrint(
        'SPLASH: user role = ${user.role}',
      );

      if (!mounted) return;

      // ------------------------------------------------------
      // 4. ROLE-BASED NAVIGATION
      // ------------------------------------------------------

      final String role =
          user.role.trim().toUpperCase();

      switch (role) {
        // ====================================================
        // ADMIN
        // ====================================================

        case 'ADMIN':
          debugPrint(
            'SPLASH: ADMIN → AdminDashboardScreen',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdminDashboardScreen(
                user: user,
              ),
            ),
          );

          break;

        // ====================================================
        // ORGANIZER
        // ====================================================

        case 'ORGANIZER':
          debugPrint(
            'SPLASH: ORGANIZER → OrganizerDashboardScreen',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrganizerDashboardScreen(
                user: user,
              ),
            ),
          );

          break;

        // ====================================================
        // STUDENT
        // ====================================================

        case 'STUDENT':
          debugPrint(
            'SPLASH: STUDENT → HomeScreen',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(
                user: user,
              ),
            ),
          );

          break;

        // ====================================================
        // UNKNOWN ROLE
        // ====================================================

        default:
          debugPrint(
            'SPLASH: unknown role = $role',
          );

          await tokenStorage.clearToken();

          if (!mounted) return;

          _showErrorAndGoToLogin(
            'Unknown user role. Please login again.',
          );
      }
    } catch (e, stackTrace) {
      debugPrint(
        'SPLASH ERROR: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      // ------------------------------------------------------
      // INVALID / EXPIRED / REVOKED TOKEN
      // ------------------------------------------------------

      await tokenStorage.clearToken();

      if (!mounted) return;

      _goToLogin();
    }
  }

  // ==========================================================
  // GO TO LOGIN
  // ==========================================================

  void _goToLogin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(),
      ),
    );
  }

  // ==========================================================
  // ERROR + LOGIN
  // ==========================================================

  void _showErrorAndGoToLogin(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;
        _goToLogin();
      },
    );
  }

  // ==========================================================
  // UI
  // ==========================================================

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
              // ==================================================
              // TOP RIGHT PURPLE GLOW
              // ==================================================

              Positioned(
                top: -110,
                right: -90,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF8B5CF6,
                    ).withOpacity(0.16),
                  ),
                ),
              ),

              // ==================================================
              // BOTTOM LEFT BLUE GLOW
              // ==================================================

              Positioned(
                bottom: -130,
                left: -110,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF3B82F6,
                    ).withOpacity(0.10),
                  ),
                ),
              ),

              // ==================================================
              // MAIN CONTENT
              // ==================================================

              Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      // ==========================================
                      // GLASS LOGO
                      // ==========================================

                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 18,
                            sigmaY: 18,
                          ),
                          child: Container(
                            width: 112,
                            height: 112,
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
                                  blurRadius: 32,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 58,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==========================================
                      // APP NAME
                      // ==========================================

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

                      const SizedBox(height: 8),

                      // ==========================================
                      // SUBTITLE
                      // ==========================================

                      Text(
                        'Smart Event Coordination',
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.60),
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                      ),

                      const SizedBox(height: 42),

                      // ==========================================
                      // LOADING
                      // ==========================================

                      const SizedBox(
                        width: 28,
                        height: 28,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(
                            0xFFB8A4FF,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==========================================
                      // LOADING TEXT
                      // ==========================================

                      Text(
                        'Preparing your campus experience...',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.42),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // BOTTOM BRANDING
              // ==================================================

              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Text(
                  'CAMPUSSYNC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.25),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w500,
                    letterSpacing: 1.5,
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