import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'admin_student_form_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final UserProfile user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060917),
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
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        const Color(0xFF8B5CF6).withOpacity(0.14),
                  ),
                ),
              ),

              Positioned(
                bottom: -120,
                left: -100,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        const Color(0xFF3B82F6).withOpacity(0.08),
                  ),
                ),
              ),

              SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TOP PROFILE HEADER
                    // ==================================================

                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                                const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF6366F1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF8B5CF6)
                                        .withOpacity(0.30),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _initials(user.name),
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.55),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user.name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.45),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(0xFF8B5CF6)
                                    .withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  const Color(0xFF8B5CF6)
                                      .withOpacity(0.25),
                            ),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color:
                                  Color(0xFFC4B5FD),
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Manage your CampusSync platform',
                      style: TextStyle(
                        color:
                            Colors.white.withOpacity(0.50),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // STATISTICS
                    // ==================================================

                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.45,
                      children: const [
                        _StatCard(
                          title: 'Organizations',
                          value: '0',
                          icon:
                              Icons.business_rounded,
                        ),
                        _StatCard(
                          title: 'Organizers',
                          value: '0',
                          icon: Icons.groups_rounded,
                        ),
                        _StatCard(
                          title: 'Active',
                          value: '0',
                          icon:
                              Icons.check_circle_rounded,
                        ),
                        _StatCard(
                          title: 'Pending',
                          value: '0',
                          icon:
                              Icons.pending_actions_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // MANAGEMENT
                    // ==================================================

                    const Text(
                      'Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _ManagementCard(
                      icon: Icons.business_rounded,
                      title: 'Organizations',
                      subtitle:
                          'Create and manage organizations',
                      onTap: () {
                        // Existing organization navigation.
                      },
                    ),

                    const SizedBox(height: 12),

                    _ManagementCard(
                      icon:
                          Icons.manage_accounts_rounded,
                      title: 'Organizers',
                      subtitle:
                          'Manage organizer accounts and access',
                      onTap: () {
                        // Existing organizer navigation.
                      },
                    ),

                    const SizedBox(height: 12),

                    _ManagementCard(
                      icon:
                          Icons.person_add_alt_1_rounded,
                      title: 'Organizer Activation',
                      subtitle:
                          'Review and activate organizer accounts',
                      onTap: () {
                        // Existing activation navigation.
                      },
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // STUDENT MANAGEMENT
                    // ==================================================

                    _ManagementCard(
                      icon:
                          Icons.school_rounded,
                      title: 'Students',
                      subtitle:
                          'Create, edit and manage student accounts',
                      onTap: () async {
                        final result =
                            await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminStudentFormScreen(),
                          ),
                        );

                        if (result == true) {
                          // Student was successfully created.
                          // The student list can be refreshed
                          // when the student management screen
                          // is connected.
                        }
                      },
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // PLATFORM CARD
                    // ==================================================

                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 16,
                          sigmaY: 16,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.06),
                            borderRadius:
                                BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.10),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFF8B5CF6,
                                  ).withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),
                                ),
                                child: const Icon(
                                  Icons
                                      .admin_panel_settings_rounded,
                                  color:
                                      Color(0xFFC4B5FD),
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Text(
                                      'Platform Administration',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: 4),
                                    Text(
                                      'You have full administrative access.',
                                      style:
                                          TextStyle(
                                        color: Colors
                                            .white
                                            .withOpacity(
                                          0.45,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty ||
        parts.first.isEmpty) {
      return 'A';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

// ================================================================
// STAT CARD
// ================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.06),
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF8B5CF6)
                          .withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFFC4B5FD),
                  size: 21,
                ),
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MANAGEMENT CARD
// ================================================================

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: onTap,
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 14,
              sigmaY: 14,
            ),
            child: Container(
              padding:
                  const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(0.06),
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(0xFF8B5CF6)
                              .withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color:
                          const Color(0xFFC4B5FD),
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                            height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white
                                .withOpacity(
                              0.45,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color: Colors.white
                        .withOpacity(0.35),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}