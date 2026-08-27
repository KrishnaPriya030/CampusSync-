import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../storage/token_storage.dart';
import 'change_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers allow us to read the text entered
  // inside the email and password fields.
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  // Used to validate the login form.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Service responsible for communicating
  // with the Spring Boot backend.
  final AuthService authService = AuthService();

  // Used to store and retrieve the JWT token.
  final TokenStorage tokenStorage = TokenStorage();

  // Controls password visibility.
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    // Validate the form first.
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Read the values entered by the user.
    final String email = emailController.text.trim();

    final String password = passwordController.text;

    try {
      // Send login request to Spring Boot.
      final result = await authService.login(email, password);

      // Save the JWT token locally.
      await tokenStorage.saveToken(result.token);

      // Debug information for testing.
      debugPrint('Login successful');
      debugPrint('Name: ${result.name}');
      debugPrint('Email: ${result.email}');
      debugPrint('Role: ${result.role}');
      debugPrint('First Login: ${result.firstLogin}');
      debugPrint('Token received');

      // Make sure this screen is still active
      // before using its BuildContext.
      if (!mounted) return;

      // If this is the user's first login,
      // they must change the temporary password.
      if (result.firstLogin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
        );
      } else {
        // Normal users go to Home.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Login failed: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check your email and password.'),
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
            colors: [Color(0xFF070A1A), Color(0xFF0E1735), Color(0xFF1B1038)],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),

                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),

                  child: Container(
                    padding: const EdgeInsets.all(28),

                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),

                      borderRadius: BorderRadius.circular(26),

                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                        width: 1,
                      ),
                    ),

                    child: Form(
                      key: formKey,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [
                          // Logo
                          Container(
                            height: 72,
                            width: 72,

                            decoration: BoxDecoration(
                              shape: BoxShape.circle,

                              color: const Color(0xFF8B5CF6).withOpacity(0.16),

                              border: Border.all(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withOpacity(0.35),
                              ),
                            ),

                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // App name
                          const Text(
                            'CampusSync',
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'Sign in to your campus account',
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Email field
                          TextFormField(
                            controller: emailController,

                            keyboardType: TextInputType.emailAddress,

                            style: const TextStyle(color: Colors.white),

                            decoration: _inputDecoration(
                              label: 'College Email',
                              icon: Icons.email_outlined,
                            ),

                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }

                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // Password field
                          TextFormField(
                            controller: passwordController,

                            obscureText: obscurePassword,

                            style: const TextStyle(color: Colors.white),

                            decoration:
                                _inputDecoration(
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },

                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,

                            child: TextButton(
                              onPressed: () {
                                // Forgot password
                                // will be implemented later.
                              },

                              child: const Text(
                                'Forgot password?',

                                style: TextStyle(
                                  color: Color(0xFFB8A4FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Login button
                          SizedBox(
                            height: 52,

                            child: ElevatedButton(
                              onPressed: login,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),

                                foregroundColor: Colors.white,

                                elevation: 0,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),

                              child: const Text(
                                'LOGIN',

                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          Text(
                            'CampusSync • Smart Event Coordination',
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: Colors.white.withOpacity(0.40),
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
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,

      labelStyle: TextStyle(color: Colors.white.withOpacity(0.65)),

      prefixIcon: Icon(icon, color: Colors.white70),

      filled: true,

      fillColor: Colors.white.withOpacity(0.06),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),

        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),

        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),

        borderSide: const BorderSide(color: Color(0xFF9B7BFF), width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),

        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),

        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),

      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }
}
