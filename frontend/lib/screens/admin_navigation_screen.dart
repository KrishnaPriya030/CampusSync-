import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'admin_dashboard_screen.dart';
import 'admin_organizations_screen.dart';
import 'admin_organizers_screen.dart';

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
  int _previousIndex = 0;

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

      _AdminProfileScreen(
        user: widget.user,
      ),
    ];
  }

  void _changePage(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool movingForward =
        _selectedIndex > _previousIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF060917),

      body: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 350,
        ),
        reverseDuration: const Duration(
          milliseconds: 250,
        ),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,

        transitionBuilder: (
          Widget child,
          Animation<double> animation,
        ) {
          final Offset beginOffset = movingForward
              ? const Offset(1.0, 0.0)
              : const Offset(-1.0, 0.0);

          return ClipRect(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: beginOffset,
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
          );
        },

        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),

      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
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
            offset: const Offset(0, -5),
          ),
        ],
      ),

      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                selected: _selectedIndex == 0,
                onTap: () => _changePage(0),
              ),

              _NavItem(
                icon: Icons.business_rounded,
                label: 'Organizations',
                selected: _selectedIndex == 1,
                onTap: () => _changePage(1),
              ),

              _NavItem(
                icon: Icons.groups_rounded,
                label: 'Organizers',
                selected: _selectedIndex == 2,
                onTap: () => _changePage(2),
              ),

              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: _selectedIndex == 3,
                onTap: () => _changePage(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// NAVIGATION ITEM
// ================================================================

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 250,
          ),
          curve: Curves.easeOutCubic,

          margin: const EdgeInsets.symmetric(
            horizontal: 4,
          ),

          padding: const EdgeInsets.symmetric(
            vertical: 7,
          ),

          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF8B5CF6)
                    .withOpacity(0.13)
                : Colors.transparent,

            borderRadius:
                BorderRadius.circular(16),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1.0,

                duration: const Duration(
                  milliseconds: 250,
                ),

                child: Icon(
                  icon,
                  size: 23,

                  color: selected
                      ? const Color(0xFFC4B5FD)
                      : Colors.white.withOpacity(0.40),
                ),
              ),

              const SizedBox(height: 4),

              AnimatedDefaultTextStyle(
                duration: const Duration(
                  milliseconds: 200,
                ),

                style: TextStyle(
                  color: selected
                      ? const Color(0xFFC4B5FD)
                      : Colors.white.withOpacity(0.40),

                  fontSize: 10,

                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),

                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ADMIN PROFILE
// ================================================================

class _AdminProfileScreen
    extends StatelessWidget {
  final UserProfile user;

  const _AdminProfileScreen({
    required this.user,
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
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                Container(
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

                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6)
                            .withOpacity(0.18),

                        blurRadius: 25,
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFC4B5FD),
                    size: 48,
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

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}