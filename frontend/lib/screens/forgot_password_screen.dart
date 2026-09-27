import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController tokenController =
      TextEditingController();

  final TextEditingController newPasswordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final AuthService authService = AuthService();

  bool isLoading = false;
  bool tokenGenerated = false;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    tokenController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> requestResetToken() async {
    if (emailController.text.trim().isEmpty) {
      _showError('Please enter your email.');
      return;
    }

    if (!emailController.text.trim().contains('@')) {
      _showError('Please enter a valid email.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final result =
          await authService.forgotPassword(
        emailController.text.trim(),
      );

      if (!mounted) return;

      final token = result['token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Reset token was not returned by the server.',
        );
      }

      tokenController.text = token;

      setState(() {
        tokenGenerated = true;
      });

      _showSuccess(
        'Reset token generated. It is valid for 30 minutes.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        _cleanErrorMessage(
          e,
          fallback:
              'Unable to generate reset token.',
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

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (tokenController.text.trim().isEmpty) {
      _showError('Please enter the reset token.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      await authService.resetPassword(
        token: tokenController.text.trim(),
        newPassword: newPasswordController.text,
        confirmPassword:
            confirmPasswordController.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor:
                const Color(0xFF11182F),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
            title: const Text(
              'Password Reset Successful',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'Your password has been changed successfully. '
              'You can now sign in with your new password.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Color(0xFFB8A4FF),
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showError(
        _cleanErrorMessage(
          e,
          fallback:
              'Unable to reset password.',
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

  String _cleanErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final message =
        error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    if (message.isEmpty) {
      return fallback;
    }

    return message;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            Colors.redAccent.shade700,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF16A34A),
      ),
    );
  }

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
      fillColor:
          Colors.white.withOpacity(0.07),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide(
          color:
              Colors.white.withOpacity(0.10),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide(
          color:
              Colors.white.withOpacity(0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF9B7BFF),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
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
              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration:
                      BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        const Color(0xFF8B5CF6)
                            .withOpacity(0.15),
                  ),
                ),
              ),

              Positioned(
                bottom: -130,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration:
                      BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        const Color(0xFF3B82F6)
                            .withOpacity(0.10),
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 440,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        28,
                      ),
                      child: BackdropFilter(
                        filter:
                            ImageFilter.blur(
                          sigmaX: 20,
                          sigmaY: 20,
                        ),
                        child: Container(
                          padding:
                              const EdgeInsets.all(
                            28,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.white
                                .withOpacity(
                              0.07,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              28,
                            ),
                            border: Border.all(
                              color: Colors.white
                                  .withOpacity(
                                0.12,
                              ),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .stretch,
                              children: [
                                Align(
                                  alignment:
                                      Alignment
                                          .centerLeft,
                                  child:
                                      IconButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () {
                                                Navigator
                                                    .pop(
                                                  context,
                                                );
                                              },
                                    icon:
                                        const Icon(
                                      Icons
                                          .arrow_back_rounded,
                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Center(
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          const Color(
                                        0xFF8B5CF6,
                                      ).withOpacity(
                                        0.16,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        22,
                                      ),
                                      border:
                                          Border.all(
                                        color: Colors
                                            .white
                                            .withOpacity(
                                          0.12,
                                        ),
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
                                  height: 24,
                                ),

                                Text(
                                  tokenGenerated
                                      ? 'Reset your password'
                                      : 'Forgot password?',
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize: 28,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  tokenGenerated
                                      ? 'Enter the reset token and choose a new password.'
                                      : 'Enter your registered college email to generate a reset token.',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    color: Colors
                                        .white
                                        .withOpacity(
                                      0.55,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(
                                  height: 32,
                                ),

                                Text(
                                  'Email',
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .white
                                        .withOpacity(
                                      0.80,
                                    ),
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                TextFormField(
                                  controller:
                                      emailController,
                                  enabled:
                                      !tokenGenerated &&
                                          !isLoading,
                                  keyboardType:
                                      TextInputType
                                          .emailAddress,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                  ),
                                  decoration:
                                      inputDecoration(
                                    hint:
                                        'Enter your email',
                                    icon: Icons
                                        .email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value ==
                                            null ||
                                        value
                                            .trim()
                                            .isEmpty) {
                                      return 'Please enter your email';
                                    }

                                    if (!value
                                        .contains(
                                      '@',
                                    )) {
                                      return 'Enter a valid email';
                                    }

                                    return null;
                                  },
                                ),

                                if (tokenGenerated) ...[
                                  const SizedBox(
                                    height: 20,
                                  ),

                                  Text(
                                    'Reset Token',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                        0.80,
                                      ),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  TextFormField(
                                    controller:
                                        tokenController,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                    ),
                                    decoration:
                                        inputDecoration(
                                      hint:
                                          'Enter reset token',
                                      icon: Icons
                                          .vpn_key_outlined,
                                    ),
                                    validator:
                                        (value) {
                                      if (value ==
                                              null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Reset token is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  Text(
                                    'New Password',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                        0.80,
                                      ),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

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
                                        inputDecoration(
                                      hint:
                                          'Enter new password',
                                      icon: Icons
                                          .lock_outline_rounded,
                                      suffixIcon:
                                          IconButton(
                                        onPressed:
                                            () {
                                          setState(() {
                                            obscureNewPassword =
                                                !obscureNewPassword;
                                          });
                                        },
                                        icon: Icon(
                                          obscureNewPassword
                                              ? Icons
                                                  .visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined,
                                          color: Colors
                                              .white
                                              .withOpacity(
                                            0.55,
                                          ),
                                        ),
                                      ),
                                    ),
                                    validator:
                                        (value) {
                                      if (value ==
                                              null ||
                                          value
                                              .isEmpty) {
                                        return 'New password is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  Text(
                                    'Confirm Password',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                        0.80,
                                      ),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

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
                                        inputDecoration(
                                      hint:
                                          'Confirm new password',
                                      icon: Icons
                                          .lock_outline_rounded,
                                      suffixIcon:
                                          IconButton(
                                        onPressed:
                                            () {
                                          setState(() {
                                            obscureConfirmPassword =
                                                !obscureConfirmPassword;
                                          });
                                        },
                                        icon: Icon(
                                          obscureConfirmPassword
                                              ? Icons
                                                  .visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined,
                                          color: Colors
                                              .white
                                              .withOpacity(
                                            0.55,
                                          ),
                                        ),
                                      ),
                                    ),
                                    validator:
                                        (value) {
                                      if (value ==
                                              null ||
                                          value
                                              .isEmpty) {
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
                                ],

                                const SizedBox(
                                  height: 28,
                                ),

                                SizedBox(
                                  height: 56,
                                  child:
                                      ElevatedButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : tokenGenerated
                                                ? resetPassword
                                                : requestResetToken,
                                    style:
                                        ElevatedButton
                                            .styleFrom(
                                      backgroundColor:
                                          const Color(
                                        0xFF8B5CF6,
                                      ),
                                      foregroundColor:
                                          Colors.white,
                                      disabledBackgroundColor:
                                          const Color(
                                        0xFF8B5CF6,
                                      ).withOpacity(
                                        0.45,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          16,
                                        ),
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
                                        : Text(
                                            tokenGenerated
                                                ? 'Reset Password'
                                                : 'Generate Reset Token',
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  15,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 18,
                                ),

                                if (tokenGenerated)
                                  TextButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () {
                                                setState(() {
                                                  tokenGenerated =
                                                      false;
                                                  tokenController
                                                      .clear();
                                                  newPasswordController
                                                      .clear();
                                                  confirmPasswordController
                                                      .clear();
                                                });
                                              },
                                    child:
                                        const Text(
                                      'Use a different email',
                                      style:
                                          TextStyle(
                                        color: Color(
                                          0xFFB8A4FF,
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
            ],
          ),
        ),
      ),
    );
  }
}