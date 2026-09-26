import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../storage/token_storage.dart';

import 'admin_dashboard_screen.dart';
import 'admin_organizations_screen.dart';
import 'admin_organizers_screen.dart';
import 'admin_students_screen.dart';
import 'admin_platform_administration_screen.dart';
import 'login_screen.dart';

class AdminNavigationScreen extends StatefulWidget {
  final UserProfile user;

  const AdminNavigationScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminNavigationScreen> createState() =>
      _AdminNavigationScreenState();
}

class _AdminNavigationScreenState
    extends State<AdminNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      AdminDashboardScreen(
        user: widget.user,
      ),

      const AdminOrganizationsScreen(),

      const AdminOrganizersScreen(),

      const AdminStudentsScreen(),

      const AdminPlatformAdministrationScreen(),

      _AdminProfileScreen(
        user: widget.user,
        onLogout: _logout,
      ),
    ];
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _changePage(int index) {
    if (index < 0 || index >= _screens.length) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await TokenStorage().clearToken();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // CURRENT TITLE
  // ============================================================

  String get _currentTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Admin Dashboard';

      case 1:
        return 'Organizations';

      case 2:
        return 'Organizers';

      case 3:
        return 'Students';

      case 4:
        return 'Platform Administration';

      case 5:
        return 'Admin Profile';

      default:
        return 'Admin';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060917),

      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigationBar() {
    final width = MediaQuery.sizeOf(context).width;

    final bool isDesktop = width >= 900;
    final bool isTablet = width >= 600 && width < 900;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1024),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop
                  ? 1100
                  : isTablet
                      ? 800
                      : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop
                    ? 28
                    : isTablet
                        ? 18
                        : 4,
                vertical: isDesktop ? 8 : 4,
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,

                selectedIndex: _selectedIndex,

                onDestinationSelected: _changePage,

                height: isDesktop ? 72 : 64,

                indicatorColor:
                    const Color(0xFF8B5CF6)
                        .withOpacity(0.18),

                indicatorShape:
                    RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                labelBehavior: isDesktop
                    ? NavigationDestinationLabelBehavior
                        .alwaysShow
                    : NavigationDestinationLabelBehavior
                        .alwaysShow,

                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.dashboard_outlined,
                      size: isDesktop ? 24 : 22,
                    ),
                    selectedIcon: Icon(
                      Icons.dashboard_rounded,
                      size: isDesktop ? 25 : 23,
                    ),
                    label: 'Home',
                  ),

                  NavigationDestination(
                    icon: Icon(
                      Icons.business_outlined,
                      size: isDesktop ? 24 : 22,
                    ),
                    selectedIcon: Icon(
                      Icons.business_rounded,
                      size: isDesktop ? 25 : 23,
                    ),
                    label: 'Organizations',
                  ),

                  NavigationDestination(
                    icon: Icon(
                      Icons.groups_outlined,
                      size: isDesktop ? 24 : 22,
                    ),
                    selectedIcon: Icon(
                      Icons.groups_rounded,
                      size: isDesktop ? 25 : 23,
                    ),
                    label: 'Organizers',
                  ),

                  NavigationDestination(
                    icon: Icon(
                      Icons.school_outlined,
                      size: isDesktop ? 24 : 22,
                    ),
                    selectedIcon: Icon(
                      Icons.school_rounded,
                      size: isDesktop ? 25 : 23,
                    ),
                    label: 'Students',
                  ),

                  NavigationDestination(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: isDesktop ? 24 : 22,
                    ),
                    selectedIcon: Icon(
                      Icons.more_horiz_rounded,
                      size: isDesktop ? 25 : 23,
                    ),
                    label: 'More',
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
// ADMIN PROFILE
// ================================================================

class _AdminProfileScreen extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onLogout;

  const _AdminProfileScreen({
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 30),

                // ==================================================
                // PROFILE ICON
                // ==================================================

                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          const Color(0xFF8B5CF6)
                              .withOpacity(0.14),
                      border: Border.all(
                        color:
                            const Color(0xFF8B5CF6)
                                .withOpacity(0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFFC4B5FD),
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // NAME
                // ==================================================

                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // EMAIL
                // ==================================================

                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.50),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 14),

                // ==================================================
                // ROLE
                // ==================================================

                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF8B5CF6)
                              .withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFC4B5FD),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ==================================================
                // LOGOUT
                // ==================================================

                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                    ),
                    label: const Text(
                      'Logout',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(
                        color:
                            Colors.redAccent
                                .withOpacity(0.35),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}