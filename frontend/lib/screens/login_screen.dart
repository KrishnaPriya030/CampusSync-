import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/login_response.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

import 'admin_dashboard_screen.dart';
import 'home_screen.dart';
import 'organizer_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final AuthService authService = AuthService();
  final TokenStorage tokenStorage = TokenStorage();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final String email = emailController.text.trim();
      final String password = passwordController.text;

      debugPrint('LOGIN: attempting login for $email');

      // ------------------------------------------------------
      // 1. LOGIN
      // ------------------------------------------------------

      final LoginResponse loginResponse =
          await authService.login(
        email,
        password,
      );

      debugPrint('LOGIN: login successful');
      debugPrint('LOGIN: role = ${loginResponse.role}');
      debugPrint('LOGIN: userId = ${loginResponse.userId}');

      // ------------------------------------------------------
      // 2. SAVE JWT
      // ------------------------------------------------------

      await tokenStorage.saveToken(
        loginResponse.token,
      );

      debugPrint('LOGIN: token saved');

      if (!mounted) return;

      // ------------------------------------------------------
      // 3. GET CURRENT USER
      // ------------------------------------------------------

      final user = await authService.getCurrentUser(
        loginResponse.token,
      );

      debugPrint('LOGIN: profile loaded');
      debugPrint('LOGIN: id = ${user.id}');
      debugPrint('LOGIN: name = ${user.name}');
      debugPrint('LOGIN: email = ${user.email}');
      debugPrint('LOGIN: role = ${user.role}');

      if (!mounted) return;

      // ------------------------------------------------------
      // 4. ROLE-BASED NAVIGATION
      // ------------------------------------------------------

      switch (user.role.toUpperCase()) {
        // ====================================================
        // ADMIN
        // ====================================================

        case 'ADMIN':
          debugPrint(
            'LOGIN: ADMIN → AdminDashboardScreen',
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
            'LOGIN: ORGANIZER → OrganizerDashboardScreen',
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
            'LOGIN: STUDENT → HomeScreen',
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
            'LOGIN: Unknown role = ${user.role}',
          );

          await tokenStorage.clearToken();

          if (!mounted) return;

          _showError(
            'Unknown user role: ${user.role}',
          );
      }
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrint('$stackTrace');

      // Remove invalid token.
      await tokenStorage.clearToken();

      if (!mounted) return;

      _showError(
        'Login failed. Please check your email and password.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.38),
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.white.withOpacity(0.60),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.07),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF9B7BFF),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              // ------------------------------------------------
              // TOP GLOW
              // ------------------------------------------------

              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5CF6)
                        .withOpacity(0.15),
                  ),
                ),
              ),

              // ------------------------------------------------
              // BOTTOM GLOW
              // ------------------------------------------------

              Positioned(
                bottom: -130,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B82F6)
                        .withOpacity(0.10),
                  ),
                ),
              ),

              // ------------------------------------------------
              // LOGIN CARD
              // ------------------------------------------------

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 440,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 20,
                          sigmaY: 20,
                        ),
                        child: Container(
                          padding:
                              const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.07),
                            borderRadius:
                                BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.12),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .stretch,
                              children: [
                                // ------------------------------------------------
                                // LOGO
                                // ------------------------------------------------

                                Center(
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          const Color(
                                        0xFF8B5CF6,
                                      ).withOpacity(0.16),
                                      borderRadius:
                                          BorderRadius
                                              .circular(22),
                                      border: Border.all(
                                        color: Colors
                                            .white
                                            .withOpacity(
                                          0.12,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons
                                          .school_rounded,
                                      color:
                                          Colors.white,
                                      size: 38,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ------------------------------------------------
                                // TITLE
                                // ------------------------------------------------

                                const Text(
                                  'Welcome back',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  'Sign in to your CampusSync account',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.55),
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // ------------------------------------------------
                                // EMAIL LABEL
                                // ------------------------------------------------

                                Text(
                                  'Email',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.80),
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // ------------------------------------------------
                                // EMAIL
                                // ------------------------------------------------

                                TextFormField(
                                  controller:
                                      emailController,
                                  keyboardType:
                                      TextInputType
                                          .emailAddress,
                                  textInputAction:
                                      TextInputAction.next,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  decoration:
                                      inputDecoration(
                                    hint:
                                        'Enter your email',
                                    icon: Icons
                                        .email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value
                                            .trim()
                                            .isEmpty) {
                                      return 'Please enter your email';
                                    }

                                    if (!value.contains('@')) {
                                      return 'Enter a valid email';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // ------------------------------------------------
                                // PASSWORD LABEL
                                // ------------------------------------------------

                                Text(
                                  'Password',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.80),
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // ------------------------------------------------
                                // PASSWORD
                                // ------------------------------------------------

                                TextFormField(
                                  controller:
                                      passwordController,
                                  obscureText:
                                      obscurePassword,
                                  textInputAction:
                                      TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!isLoading) {
                                      login();
                                    }
                                  },
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  decoration:
                                      inputDecoration(
                                    hint:
                                        'Enter your password',
                                    icon: Icons
                                        .lock_outline_rounded,
                                    suffixIcon:
                                        IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword =
                                              !obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons
                                                .visibility_outlined
                                            : Icons
                                                .visibility_off_outlined,
                                        color: Colors.white
                                            .withOpacity(
                                          0.55,
                                        ),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty) {
                                      return 'Please enter your password';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 28),

                                // ------------------------------------------------
                                // LOGIN BUTTON
                                // ------------------------------------------------

                                SizedBox(
                                  height: 56,
                                  child:
                                      ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : login,
                                    style:
                                        ElevatedButton
                                            .styleFrom(
                                      backgroundColor:
                                          const Color(
                                        0xFF8B5CF6,
                                      ),
                                      disabledBackgroundColor:
                                          const Color(
                                        0xFF8B5CF6,
                                      ).withOpacity(0.45),
                                      foregroundColor:
                                          Colors.white,
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2.5,
                                              color:
                                                  Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style:
                                                TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ------------------------------------------------
                                // FOOTER
                                // ------------------------------------------------

                                Text(
                                  'CampusSync • Smart Event Coordination',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.30),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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