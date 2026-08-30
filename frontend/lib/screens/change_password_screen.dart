import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

import 'admin_dashboard_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'organizer_dashboard_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController currentPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final AuthService authService = AuthService();

  final TokenStorage tokenStorage = TokenStorage();

  bool isLoading = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // --------------------------------------------------
  // CHANGE PASSWORD
  // --------------------------------------------------

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // --------------------------------------------------
      // GET TOKEN
      // --------------------------------------------------

      final String? token = await tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // --------------------------------------------------
      // CHANGE PASSWORD
      // --------------------------------------------------

      await authService.changePassword(
        currentPasswordController.text,
        newPasswordController.text,
        confirmPasswordController.text,
        token,
      );

      debugPrint('PASSWORD: password changed successfully');

      // --------------------------------------------------
      // GET CURRENT USER
      // --------------------------------------------------

      final UserProfile user = await authService.getCurrentUser(token);

      debugPrint('PASSWORD: user = ${user.email}');

      debugPrint('PASSWORD: role = ${user.role}');

      if (!mounted) return;

      // --------------------------------------------------
      // SUCCESS MESSAGE
      // --------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Small delay so user can see success message.
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // --------------------------------------------------
      // ROLE BASED NAVIGATION
      // --------------------------------------------------

      switch (user.role.toUpperCase()) {
        case 'ADMIN':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(user: user),
            ),
            (route) => false,
          );
          break;

        case 'ORGANIZER':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => OrganizerDashboardScreen(user: user),
            ),
            (route) => false,
          );
          break;

        case 'STUDENT':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
            (route) => false,
          );
          break;

        default:
          await tokenStorage.clearToken();

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
      }
    } catch (e) {
      debugPrint('PASSWORD: change failed: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password change failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // PASSWORD FIELD
  // --------------------------------------------------

  InputDecoration passwordDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      prefixIcon: const Icon(Icons.lock_outline_rounded),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),

      // --------------------------------------------------
      // BODY
      // --------------------------------------------------
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --------------------------------------------------
                    // ICON
                    // --------------------------------------------------
                    const Icon(Icons.lock_reset_rounded, size: 70),

                    const SizedBox(height: 20),

                    // --------------------------------------------------
                    // TITLE
                    // --------------------------------------------------
                    const Text(
                      'Change your password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Enter your current password and choose a new one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 32),

                    // --------------------------------------------------
                    // CURRENT PASSWORD
                    // --------------------------------------------------
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: passwordDecoration('Current Password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current password is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // --------------------------------------------------
                    // NEW PASSWORD
                    // --------------------------------------------------
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: passwordDecoration('New Password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required';
                        }

                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // --------------------------------------------------
                    // CONFIRM PASSWORD
                    // --------------------------------------------------
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: passwordDecoration('Confirm New Password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }

                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // --------------------------------------------------
                    // BUTTON
                    // --------------------------------------------------
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : changePassword,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Change Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
