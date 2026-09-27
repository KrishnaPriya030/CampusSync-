import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../storage/token_storage.dart';

import 'admin_dashboard_screen.dart';
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
      _buildHomeNavigator(),

      _AdminProfileScreen(
        user: widget.user,
        onLogout: _logout,
      ),

      AdminPlatformAdministrationScreen(
        user: widget.user,
      ),
    ];
  }

  // ============================================================
  // HOME NAVIGATOR
  // ============================================================

  Widget _buildHomeNavigator() {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(
            user: widget.user,
          ),
          settings: settings,
        );
      },
    );
  }

  // ============================================================
  // PAGE CHANGE
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
            'Logout?',
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

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060917),

      body: Column(
        children: [
          // ------------------------------------------------------
          // MAIN CONTENT
          // ------------------------------------------------------

          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),

          // ------------------------------------------------------
          // BOTTOM NAVIGATION
          // ------------------------------------------------------

          _buildBottomNavigation(),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    final width = MediaQuery.sizeOf(context).width;

    final bool desktop = width >= 900;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          desktop ? 24 : 10,
          8,
          desktop ? 24 : 10,
          10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1024),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: Container(
              height: desktop ? 66 : 62,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _NavigationItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: _selectedIndex == 0,
                    onTap: () => _changePage(0),
                  ),

                  _NavigationItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: _selectedIndex == 1,
                    onTap: () => _changePage(1),
                  ),

                  _NavigationItem(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
                    selected: _selectedIndex == 2,
                    onTap: () => _changePage(2),
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
// NAVIGATION ITEM
// ================================================================

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 6,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  width: 42,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF8B5CF6)
                            .withOpacity(0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? const Color(0xFFC4B5FD)
                        : Colors.white.withOpacity(0.45),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                    fontSize: 10,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
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

  String _initials(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'A';
    }

    final parts = trimmed.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bool desktop = width >= 900;

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
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            desktop ? 40 : 18,
            desktop ? 34 : 22,
            desktop ? 40 : 18,
            30,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 650,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    Container(
                      width: desktop ? 110 : 96,
                      height: desktop ? 110 : 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFF6366F1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6)
                                .withOpacity(0.22),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _initials(user.name),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: desktop ? 34 : 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: desktop ? 28 : 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6)
                            .withOpacity(0.13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6)
                              .withOpacity(0.20),
                        ),
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

                    const SizedBox(height: 32),

                    _ProfileCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Name',
                      value: user.name,
                    ),

                    const SizedBox(height: 12),

                    _ProfileCard(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: user.email,
                    ),

                    const SizedBox(height: 12),

                    _ProfileCard(
                      icon:
                          Icons.admin_panel_settings_outlined,
                      title: 'Role',
                      value: user.role.toUpperCase(),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
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
                            color: Colors.redAccent
                                .withOpacity(0.35),
                          ),
                          shape: RoundedRectangleBorder(
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
          ],
        ),
      ),
    );
  }
}

// ================================================================
// PROFILE CARD
// ================================================================

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFC4B5FD),
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        Colors.white.withOpacity(0.42),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}