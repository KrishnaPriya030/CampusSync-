import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../storage/token_storage.dart';
import '../screens/login_screen.dart';

class AuthenticatedScaffold extends StatelessWidget {
  final UserProfile user;
  final Widget body;
  final String title;

  const AuthenticatedScaffold({
    super.key,
    required this.user,
    required this.body,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060917),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF8B5CF6),
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
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
        child: SafeArea(child: body),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isAdmin = user.role.toUpperCase() == 'ADMIN';
    final isOrganizer = user.role.toUpperCase() == 'ORGANIZER';

    return Drawer(
      backgroundColor: const Color(0xFF0B1024),
      child: SafeArea(
        child: Column(
          children: [
            // PROFILE HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.30),
                    const Color(0xFF3B82F6).withOpacity(0.10),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF8B5CF6),
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role,
                      style: const TextStyle(
                        color: Color(0xFFB8A4FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(
                    context,
                    Icons.dashboard_rounded,
                    'Dashboard',
                    () {
                      Navigator.pop(context);
                    },
                  ),

                  if (isAdmin) ...[
                    _drawerItem(
                      context,
                      Icons.business_rounded,
                      'Organizations',
                      () {},
                    ),
                    _drawerItem(
                      context,
                      Icons.manage_accounts_rounded,
                      'Organizers',
                      () {},
                    ),
                    _drawerItem(
                      context,
                      Icons.people_alt_rounded,
                      'Users',
                      () {},
                    ),
                    _drawerItem(
                      context,
                      Icons.event_rounded,
                      'Events',
                      () {},
                    ),
                  ],

                  if (isOrganizer) ...[
                    _drawerItem(
                      context,
                      Icons.event_note_rounded,
                      'My Events',
                      () {},
                    ),
                    _drawerItem(
                      context,
                      Icons.add_circle_outline_rounded,
                      'Create Event',
                      () {},
                    ),
                    _drawerItem(
                      context,
                      Icons.people_outline_rounded,
                      'Participants',
                      () {},
                    ),
                  ],

                  if (!isAdmin && !isOrganizer) ...[
                    _drawerItem(
                      context,
                      Icons.search_rounded,
                      'Browse Events',
                      () {},
                    ),
                    _drawerItem(
                      context,
                      Icons.bookmark_outline_rounded,
                      'My Registrations',
                      () {},
                    ),
                  ],

                  const Divider(
                    color: Colors.white12,
                    indent: 16,
                    endIndent: 16,
                  ),

                  _drawerItem(
                    context,
                    Icons.person_outline_rounded,
                    'Profile',
                    () {},
                  ),

                  _drawerItem(
                    context,
                    Icons.lock_outline_rounded,
                    'Change Password',
                    () {},
                  ),
                ],
              ),
            ),

            // LOGOUT
            _drawerItem(
              context,
              Icons.logout_rounded,
              'Logout',
              () async {
                await TokenStorage().clearToken();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              danger: true,
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 2,
      ),
      leading: Icon(
        icon,
        color: danger
            ? Colors.redAccent
            : const Color(0xFFB8A4FF),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? Colors.redAccent : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}