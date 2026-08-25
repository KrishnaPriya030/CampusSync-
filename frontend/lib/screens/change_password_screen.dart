import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../storage/token_storage.dart';
import 'home_screen.dart';

class ChangePasswordScreen
    extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final TextEditingController
      currentPasswordController =
      TextEditingController();

  final TextEditingController
      newPasswordController =
      TextEditingController();

  final TextEditingController
      confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final AuthService authService =
      AuthService();

  final TokenStorage tokenStorage =
      TokenStorage();

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final String currentPassword =
        currentPasswordController.text;

    final String newPassword =
        newPasswordController.text;

    final String confirmPassword =
        confirmPasswordController.text;

    try {
      final String? token =
          await tokenStorage.getToken();

      if (token == null) {
        throw Exception(
          'Authentication token not found',
        );
      }

      await authService.changePassword(
        currentPassword,
        newPassword,
        confirmPassword,
        token,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const HomeScreen(),
        ),
      );
    } catch (e) {
      debugPrint(
        'Password change failed: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password change failed',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              TextFormField(
                controller:
                    currentPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Current Password',
                  border:
                      OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Current password is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller:
                    newPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'New Password',
                  border:
                      OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'New password is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller:
                    confirmPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Confirm New Password',
                  border:
                      OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Please confirm your password';
                  }

                  if (value !=
                      newPasswordController
                          .text) {
                    return 'Passwords do not match';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      changePassword,
                  child: const Text(
                    'Change Password',
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