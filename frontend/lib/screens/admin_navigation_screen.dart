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

  void _changePage(int index) {
    if (index < 0 || index >= _screens.length) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    Navigator.of(context).maybePop();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060917),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1024),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _currentTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      drawer: _buildDrawer(),

      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0B1024),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),

            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                children: [
                  _drawerItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                  ),

                  _drawerItem(
                    index: 1,
                    icon: Icons.business_rounded,
                    title: 'Organizations',
                  ),

                  _drawerItem(
                    index: 2,
                    icon: Icons.groups_rounded,
                    title: 'Organizers',
                  ),

                  _drawerItem(
                    index: 3,
                    icon: Icons.school_rounded,
                    title: 'Students',
                  ),

                  _drawerItem(
                    index: 4,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Platform Administration',
                  ),

                  const SizedBox(height: 12),

                  Divider(
                    color: Colors.white.withOpacity(0.10),
                  ),

                  const SizedBox(height: 12),

                  _drawerItem(
                    index: 5,
                    icon: Icons.person_rounded,
                    title: 'Profile',
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(
                    Icons.logout_rounded,
                  ),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                      color: Colors.redAccent.withOpacity(0.35),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.20),
            const Color(0xFF3B82F6).withOpacity(0.10),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B5CF6)
                  .withOpacity(0.16),
              border: Border.all(
                color: const Color(0xFF8B5CF6)
                    .withOpacity(0.25),
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFFC4B5FD),
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.50),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.user.role.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: () => _changePage(index),
        selected: selected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        selectedTileColor:
            const Color(0xFF8B5CF6).withOpacity(0.14),
        leading: Icon(
          icon,
          color: selected
              ? const Color(0xFFC4B5FD)
              : Colors.white.withOpacity(0.50),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.white.withOpacity(0.70),
            fontSize: 14,
            fontWeight: selected
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 30),

            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6)
                      .withOpacity(0.14),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6)
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

            Text(
              user.email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.50),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 14),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
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
                    color: Colors.redAccent.withOpacity(0.35),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}