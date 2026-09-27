import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class AdminPlatformAdministrationScreen extends StatelessWidget {
  final UserProfile user;

  const AdminPlatformAdministrationScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool desktop = width >= 1100;
    final bool tablet = width >= 700 && width < 1100;

    final double horizontalPadding = desktop
        ? 40
        : tablet
            ? 28
            : 18;

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
            horizontalPadding,
            desktop ? 32 : 22,
            horizontalPadding,
            30,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1050,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =====================================================
                    // HEADER
                    // =====================================================

                    Text(
                      'Platform Administration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: desktop
                            ? 30
                            : tablet
                                ? 28
                                : 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'CampusSync platform access and administration',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // =====================================================
                    // ADMIN HEADER
                    // =====================================================

                    _AdminHeaderCard(
                      user: user,
                      desktop: desktop,
                    ),

                    const SizedBox(height: 24),

                    // =====================================================
                    // ADMINISTRATOR ACCESS
                    // =====================================================

                    const _SectionTitle(
                      title: 'Administrator Access',
                    ),

                    const SizedBox(height: 12),

                    if (desktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _AdministrationCard(
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'Administrator',
                              value: user.name,
                              subtitle:
                                  'Current CampusSync administrator',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AdministrationCard(
                              icon: Icons.email_outlined,
                              title: 'Administrator Email',
                              value: user.email,
                              subtitle:
                                  'Authenticated administrator account',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AdministrationCard(
                              icon: Icons.security_rounded,
                              title: 'Access Level',
                              value: 'Full Administrative Access',
                              subtitle:
                                  'Controlled by the backend ADMIN role',
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _AdministrationCard(
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Administrator',
                        value: user.name,
                        subtitle:
                            'Current CampusSync administrator',
                      ),
                      const SizedBox(height: 10),
                      _AdministrationCard(
                        icon: Icons.email_outlined,
                        title: 'Administrator Email',
                        value: user.email,
                        subtitle:
                            'Authenticated administrator account',
                      ),
                      const SizedBox(height: 10),
                      _AdministrationCard(
                        icon: Icons.security_rounded,
                        title: 'Access Level',
                        value: 'Full Administrative Access',
                        subtitle:
                            'Controlled by the backend ADMIN role',
                      ),
                    ],

                    const SizedBox(height: 26),

                    // =====================================================
                    // ADMINISTRATIVE SCOPE
                    // =====================================================

                    const _SectionTitle(
                      title: 'Administrative Scope',
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Manage the major entities and account workflows '
                      'available to the CampusSync administrator.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Desktop / tablet grid
                    if (desktop || tablet)
                      GridView.count(
                        crossAxisCount: desktop ? 2 : 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: desktop ? 3.8 : 3.2,
                        children: const [
                          _ScopeCard(
                            icon: Icons.business_rounded,
                            title: 'Organizations',
                            description:
                                'Create and manage CampusSync organizations.',
                          ),
                          _ScopeCard(
                            icon: Icons.manage_accounts_rounded,
                            title: 'Organizer Accounts',
                            description:
                                'Import and manage organizer accounts.',
                          ),
                          _ScopeCard(
                            icon: Icons.school_rounded,
                            title: 'Student Accounts',
                            description:
                                'Import and manage student accounts.',
                          ),
                          _ScopeCard(
                            icon: Icons.account_balance_rounded,
                            title: 'Department Heads',
                            description:
                                'Import and manage department head accounts.',
                          ),
                          _ScopeCard(
                            icon:
                                Icons.supervisor_account_rounded,
                            title: 'Organization Heads',
                            description:
                                'Import and manage organization head accounts.',
                          ),
                          _ScopeCard(
                            icon: Icons.event_rounded,
                            title: 'Events',
                            description:
                                'Read-only event administration will be '
                                'connected after the Admin Events backend '
                                'endpoint is available.',
                            pending: true,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: const [
                          _ScopeCard(
                            icon: Icons.business_rounded,
                            title: 'Organizations',
                            description:
                                'Create and manage CampusSync organizations.',
                          ),
                          SizedBox(height: 10),
                          _ScopeCard(
                            icon: Icons.manage_accounts_rounded,
                            title: 'Organizer Accounts',
                            description:
                                'Import and manage organizer accounts.',
                          ),
                          SizedBox(height: 10),
                          _ScopeCard(
                            icon: Icons.school_rounded,
                            title: 'Student Accounts',
                            description:
                                'Import and manage student accounts.',
                          ),
                          SizedBox(height: 10),
                          _ScopeCard(
                            icon: Icons.account_balance_rounded,
                            title: 'Department Heads',
                            description:
                                'Import and manage department head accounts.',
                          ),
                          SizedBox(height: 10),
                          _ScopeCard(
                            icon:
                                Icons.supervisor_account_rounded,
                            title: 'Organization Heads',
                            description:
                                'Import and manage organization head accounts.',
                          ),
                          SizedBox(height: 10),
                          _ScopeCard(
                            icon: Icons.event_rounded,
                            title: 'Events',
                            description:
                                'Read-only event administration will be '
                                'connected after the Admin Events backend '
                                'endpoint is available.',
                            pending: true,
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // =====================================================
                    // ACCOUNT WORKFLOW INFORMATION
                    // =====================================================

                  
                    const SizedBox(height: 18),

                    // =====================================================
                    // BACKEND SECURITY INFORMATION
                    // =====================================================

                    

                    const SizedBox(height: 8),
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

// ============================================================================
// ADMIN HEADER CARD
// ============================================================================

class _AdminHeaderCard extends StatelessWidget {
  final UserProfile user;
  final bool desktop;

  const _AdminHeaderCard({
    required this.user,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(desktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF312E81),
            Color(0xFF4C1D95),
            Color(0xFF5B21B6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1D95).withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: desktop ? 62 : 54,
            height: desktop ? 62 : 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.11),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: desktop ? 31 : 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CampusSync Administrator',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: desktop ? 20 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (desktop) ...[
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFFC4B5FD),
                    size: 16,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ============================================================================
// ADMINISTRATION CARD
// ============================================================================

class _AdministrationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _AdministrationCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFC4B5FD),
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
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

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 11,
                    height: 1.3,
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

// ============================================================================
// SCOPE CARD
// ============================================================================

class _ScopeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool pending;

  const _ScopeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.10),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    if (pending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.10),
                          ),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.43),
                    fontSize: 11,
                    height: 1.4,
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

// ============================================================================
// ACCOUNT WORKFLOW INFORMATION
// ============================================================================
