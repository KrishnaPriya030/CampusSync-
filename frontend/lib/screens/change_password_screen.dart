import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

import 'admin_navigation_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'organizer_dashboard_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final TextEditingController currentPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final AuthService authService =
      AuthService();

  final TokenStorage tokenStorage =
      TokenStorage();

  bool isLoading = false;

  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // CHANGE PASSWORD
  // ==========================================================================

  Future<void> changePassword() async {
    if (isLoading) {
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      // ----------------------------------------------------------------------
      // GET TOKEN
      // ----------------------------------------------------------------------

      final String? token =
          await tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      // ----------------------------------------------------------------------
      // CHANGE PASSWORD
      // ----------------------------------------------------------------------

      await authService.changePassword(
        currentPasswordController.text,
        newPasswordController.text,
        confirmPasswordController.text,
        token,
      );

      debugPrint(
        'PASSWORD: password changed successfully',
      );

      // ----------------------------------------------------------------------
      // GET UPDATED USER
      // ----------------------------------------------------------------------

      final UserProfile user =
          await authService.getCurrentUser(
        token,
      );

      debugPrint(
        'PASSWORD: user = ${user.email}',
      );

      debugPrint(
        'PASSWORD: role = ${user.role}',
      );

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------------------
      // SUCCESS MESSAGE
      // ----------------------------------------------------------------------

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Password changed successfully',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------------------
      // ROLE-BASED NAVIGATION
      // ----------------------------------------------------------------------

      final String role =
          user.role.trim().toUpperCase();

      switch (role) {
        // ====================================================================
        // ADMIN
        // ====================================================================

        case 'ADMIN':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AdminNavigationScreen(
                user: user,
              ),
            ),
            (route) => false,
          );
          break;

        // ====================================================================
        // ORGANIZER
        // ====================================================================

        case 'ORGANIZER':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrganizerDashboardScreen(
                user: user,
              ),
            ),
            (route) => false,
          );
          break;

        // ====================================================================
        // STUDENT
        // ====================================================================

        case 'STUDENT':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  HomeScreen(
                user: user,
              ),
            ),
            (route) => false,
          );
          break;

        // ====================================================================
        // DEPARTMENT HEAD
        // ====================================================================

        case 'DEPARTMENT_HEAD':
          _showMessage(
            'Department Head dashboard is not connected yet.',
          );
          break;

        // ====================================================================
        // ORGANIZATION HEAD
        // ====================================================================

        case 'ORGANIZATION_HEAD':
          _showMessage(
            'Organization Head dashboard is not connected yet.',
          );
          break;

        // ====================================================================
        // UNKNOWN ROLE
        // ====================================================================

        default:
          debugPrint(
            'PASSWORD: unknown role = $role',
          );

          await tokenStorage.clearToken();

          if (!mounted) {
            return;
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const LoginScreen(),
            ),
            (route) => false,
          );
      }
    } catch (e) {
      debugPrint(
        'PASSWORD: change failed: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Password change failed: ${_cleanError(e)}',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================================================
  // ERROR CLEANUP
  // ==========================================================================

  String _cleanError(Object error) {
    final String message =
        error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(11);
    }

    return message;
  }

  // ==========================================================================
  // MESSAGE
  // ==========================================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================================
  // PASSWORD FIELD DECORATION
  // ==========================================================================

  InputDecoration passwordDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,

      prefixIcon: const Icon(
        Icons.lock_outline_rounded,
      ),

      suffixIcon: IconButton(
        tooltip: obscure
            ? 'Show password'
            : 'Hide password',
        onPressed: onToggle,
        icon: Icon(
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),

      filled: true,
      fillColor:
          Colors.white.withOpacity(0.05),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide(
          color:
              Colors.white.withOpacity(
            0.10,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color:
              Color(0xFF9B7BFF),
          width: 1.4,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
          width: 1.4,
        ),
      ),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true,

      body: Container(
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(0xFF060917),
              Color(0xFF0B1430),
              Color(0xFF171033),
            ],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24),

              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 520,
                ),

                child: Container(
                  padding:
                      const EdgeInsets.all(28),

                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.055),

                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),

                    border: Border.all(
                      color: Colors.white
                          .withOpacity(
                        0.08,
                      ),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(
                          0.25,
                        ),
                        blurRadius: 30,
                        offset:
                            const Offset(
                          0,
                          14,
                        ),
                      ),
                    ],
                  ),

                  child: Form(
                    key: formKey,

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,

                      children: [
                        // ======================================================
                        // ICON
                        // ======================================================

                        Center(
                          child: Container(
                            width: 76,
                            height: 76,

                            decoration:
                                BoxDecoration(
                              gradient:
                                  const LinearGradient(
                                begin:
                                    Alignment.topLeft,
                                end:
                                    Alignment.bottomRight,
                                colors: [
                                  Color(
                                    0xFF6366F1,
                                  ),
                                  Color(
                                    0xFF8B5CF6,
                                  ),
                                ],
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                22,
                              ),
                            ),

                            child:
                                const Icon(
                              Icons
                                  .lock_reset_rounded,
                              color:
                                  Colors.white,
                              size: 38,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // ======================================================
                        // TITLE
                        // ======================================================

                        const Text(
                          'Change your password',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 26,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          'Your account was created with your initial credentials. Set a new password to continue.',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            color: Colors.white
                                .withOpacity(
                              0.52,
                            ),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        // ======================================================
                        // CURRENT PASSWORD
                        // ======================================================

                        TextFormField(
                          controller:
                              currentPasswordController,
                          obscureText:
                              obscureCurrentPassword,

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),

                          decoration:
                              passwordDecoration(
                            label:
                                'Current Password',
                            obscure:
                                obscureCurrentPassword,
                            onToggle: () {
                              setState(() {
                                obscureCurrentPassword =
                                    !obscureCurrentPassword;
                              });
                            },
                          ),

                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Current password is required';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // ======================================================
                        // NEW PASSWORD
                        // ======================================================

                        TextFormField(
                          controller:
                              newPasswordController,
                          obscureText:
                              obscureNewPassword,

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),

                          decoration:
                              passwordDecoration(
                            label:
                                'New Password',
                            obscure:
                                obscureNewPassword,
                            onToggle: () {
                              setState(() {
                                obscureNewPassword =
                                    !obscureNewPassword;
                              });
                            },
                          ),

                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                value.isEmpty) {
                              return 'New password is required';
                            }

                            if (value.length <
                                8) {
                              return 'Password must be at least 8 characters';
                            }

                            if (value ==
                                currentPasswordController
                                    .text) {
                              return 'New password must be different';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // ======================================================
                        // CONFIRM PASSWORD
                        // ======================================================

                        TextFormField(
                          controller:
                              confirmPasswordController,
                          obscureText:
                              obscureConfirmPassword,

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),

                          decoration:
                              passwordDecoration(
                            label:
                                'Confirm New Password',
                            obscure:
                                obscureConfirmPassword,
                            onToggle: () {
                              setState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                          ),

                          validator:
                              (value) {
                            if (value ==
                                    null ||
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

                        const SizedBox(
                          height: 24,
                        ),

                        // ======================================================
                        // PASSWORD REQUIREMENT
                        // ======================================================

                        Container(
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF6366F1,
                            ).withOpacity(
                              0.08,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),

                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFF6366F1,
                              ).withOpacity(
                                0.16,
                              ),
                            ),
                          ),

                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Icon(
                                Icons
                                    .info_outline_rounded,
                                color:
                                    Color(
                                  0xFFA78BFA,
                                ),
                                size: 19,
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child: Text(
                                  'Use at least 8 characters for your new password.',
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .white
                                        .withOpacity(
                                      0.60,
                                    ),
                                    fontSize:
                                        12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ======================================================
                        // BUTTON
                        // ======================================================

                        SizedBox(
                          height: 54,

                          child:
                              ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : changePassword,

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF7C3AED,
                              ),

                              foregroundColor:
                                  Colors.white,

                              disabledBackgroundColor:
                                  const Color(
                                0xFF7C3AED,
                              ).withOpacity(
                                0.35,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                              ),
                            ),

                            child: isLoading
                                ? const SizedBox(
                                    width:
                                        23,
                                    height:
                                        23,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Change Password',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          15,
                                      fontWeight:
                                          FontWeight
                                              .w700,
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
        ),
      ),
    );
  }
}