import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../storage/token_storage.dart';
import 'admin_organizations_screen.dart';
import 'admin_organizers_screen.dart';
import 'admin_students_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final UserProfile user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    final tokenStorage = TokenStorage();

    await tokenStorage.clearToken();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // PLATFORM ADMINISTRATION
  // ============================================================

  void _showPlatformAdministration(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFFC4B5FD),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Platform Administration',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _AdminInfoRow(
                label: 'Administrator',
                value: user.name,
              ),
              const SizedBox(height: 12),
              _AdminInfoRow(
                label: 'Email',
                value: user.email,
              ),
              const SizedBox(height: 12),
              _AdminInfoRow(
                label: 'Role',
                value: user.role,
              ),
              const SizedBox(height: 18),
              Text(
                'You have full administrative access to the CampusSync platform.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ORGANIZER ACTIVATION
  // ============================================================

  void _openOrganizerActivation(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminOrganizersScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool compact = width < 380;

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
              // ==================================================
              // BACKGROUND DECORATION
              // ==================================================

              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5CF6)
                        .withOpacity(0.14),
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
                    color: const Color(0xFF3B82F6)
                        .withOpacity(0.08),
                  ),
                ),
              ),

              // ==================================================
              // CONTENT
              // ==================================================

              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 20,
                  16,
                  compact ? 14 : 20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: compact ? 46 : 52,
                          height: compact ? 46 : 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF6366F1),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _initials(user.name),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    compact ? 16 : 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: compact ? 10 : 14,
                        ),

                        Expanded(
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.55),
                                  fontSize:
                                      compact ? 12 : 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user.name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      compact ? 18 : 21,
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
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // LOGOUT BUTTON
                        IconButton(
                          tooltip: 'Logout',
                          onPressed: () {
                            _showLogoutConfirmation(
                              context,
                            );
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            compact ? 24 : 28,
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

                    const SizedBox(height: 22),

                    // ==================================================
                    // STATISTICS
                    //
                    // IMPORTANT:
                    // No vertical Spacer / oversized Column here.
                    // This prevents the previous 7.1px overflow.
                    // ==================================================

                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      childAspectRatio:
                          compact ? 1.75 : 1.65,
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
                          icon:
                              Icons.groups_rounded,
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

                    const SizedBox(height: 26),

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

                    // ORGANIZATIONS
                    _ManagementCard(
                      icon:
                          Icons.business_rounded,
                      title: 'Organizations',
                      subtitle:
                          'Create and manage organizations',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminOrganizationsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // ORGANIZERS
                    _ManagementCard(
                      icon:
                          Icons.manage_accounts_rounded,
                      title: 'Organizers',
                      subtitle:
                          'Manage organizer accounts and access',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminOrganizersScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // ORGANIZER ACTIVATION
                    _ManagementCard(
                      icon:
                          Icons.person_add_alt_1_rounded,
                      title: 'Organizer Activation',
                      subtitle:
                          'Review and activate organizer accounts',
                      onTap: () {
                        _openOrganizerActivation(
                          context,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // STUDENTS
                    _ManagementCard(
                      icon:
                          Icons.school_rounded,
                      title: 'Students',
                      subtitle:
                          'Create, edit and import student accounts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminStudentsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // PLATFORM ADMINISTRATION
                    _ManagementCard(
                      icon:
                          Icons.admin_panel_settings_rounded,
                      title:
                          'Platform Administration',
                      subtitle:
                          'View administrator access and platform settings',
                      onTap: () {
                        _showPlatformAdministration(
                          context,
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // LOGOUT BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showLogoutConfirmation(
                            context,
                          );
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                        ),
                        label: const Text(
                          'Logout',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              Colors.redAccent,
                          side: BorderSide(
                            color: Colors.redAccent
                                .withOpacity(0.35),
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
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

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  Future<void> _showLogoutConfirmation(
    BuildContext context,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF111827),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout?',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.65),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true &&
        context.mounted) {
      await _logout(context);
    }
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String _initials(String name) {
    final trimmed =
        name.trim();

    if (trimmed.isEmpty) {
      return 'A';
    }

    final parts =
        trimmed.split(
      RegExp(r'\s+'),
    );

    if (parts.length == 1) {
      return parts.first[0]
          .toUpperCase();
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
    final width =
        MediaQuery.sizeOf(context).width;

    final bool compact =
        width < 380;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal:
                compact ? 10 : 12,
            vertical:
                compact ? 8 : 10,
          ),
          decoration:
              BoxDecoration(
            color: Colors.white
                .withOpacity(0.06),
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: Colors.white
                  .withOpacity(0.10),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Container(
                width:
                    compact ? 29 : 33,
                height:
                    compact ? 29 : 33,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF8B5CF6,
                  ).withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(
                    0xFFC4B5FD,
                  ),
                  size:
                      compact ? 16 : 18,
                ),
              ),

              SizedBox(
                width:
                    compact ? 7 : 9,
              ),

              Expanded(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            compact ? 19 : 21,
                        fontWeight:
                            FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(
                          0.45,
                        ),
                        fontSize:
                            compact ? 9 : 10,
                        height: 1.0,
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
}

// ================================================================
// MANAGEMENT CARD
// ================================================================

class _ManagementCard
    extends StatelessWidget {
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
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(0.06),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: Colors.white
                      .withOpacity(0.10),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF8B5CF6,
                      ).withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color:
                          const Color(
                        0xFFC4B5FD,
                      ),
                      size: 21,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
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
                          height: 4,
                        ),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors
                                .white
                                .withOpacity(
                              0.45,
                            ),
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color: Colors.white
                        .withOpacity(0.35),
                    size: 14,
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

// ================================================================
// ADMIN INFO ROW
// ================================================================

class _AdminInfoRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _AdminInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.45),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}