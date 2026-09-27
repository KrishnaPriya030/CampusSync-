import 'dart:ui';

import 'package:flutter/material.dart';
import 'admin_department_heads_screen.dart';
import 'admin_organization_heads_screen.dart';

import '../models/organization.dart';
import '../models/organizer.dart';
import '../models/user_profile.dart';

import '../services/admin_organization_service.dart';
import '../services/admin_organizer_service.dart';

import '../storage/token_storage.dart';

import 'admin_organizations_screen.dart';
import 'admin_organizers_screen.dart';
import 'admin_students_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserProfile user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  final TokenStorage _tokenStorage = TokenStorage();

  final AdminOrganizationService _organizationService =
      AdminOrganizationService();

  final AdminOrganizerService _organizerService =
      AdminOrganizerService();

  bool _loadingStats = true;

  String? _statsError;

  int _organizationCount = 0;
  int _organizerCount = 0;
  int _activeOrganizerCount = 0;
  int _pendingOrganizerCount = 0;

  @override
  void initState() {
    super.initState();

    _loadDashboardStats();
  }

  // ============================================================
  // LOAD DASHBOARD STATISTICS
  // ============================================================

  Future<void> _loadDashboardStats() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingStats = true;
      _statsError = null;
    });

    try {
      final String? token =
          await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final results = await Future.wait([
        _organizationService.getAllOrganizations(token),
        _organizerService.getAllOrganizers(token),
      ]);

      final List<Organization> organizations =
          results[0] as List<Organization>;

      final List<Organizer> organizers =
          results[1] as List<Organizer>;

      final Iterable<Organizer> activeOrganizers =
          organizers.where(
        (organizer) =>
            organizer.accountStatus.toUpperCase() ==
                'ACTIVE' &&
            !organizer.firstLogin,
      );

      final Iterable<Organizer> pendingOrganizers =
          organizers.where(
        (organizer) =>
            organizer.accountStatus.toUpperCase() ==
                'ACTIVE' &&
            organizer.firstLogin,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _organizationCount =
            organizations.length;

        _organizerCount =
            organizers.length;

        _activeOrganizerCount =
            activeOrganizers.length;

        _pendingOrganizerCount =
            pendingOrganizers.length;

        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingStats = false;
        _statsError = e.toString();
      });
    }
  }

  // ============================================================
  // OPEN ORGANIZATIONS
  // ============================================================

  Future<void> _openOrganizations() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminOrganizationsScreen(),
      ),
    );

    if (mounted) {
      _loadDashboardStats();
    }
  }

  // ============================================================
  // OPEN ORGANIZERS
  // ============================================================

  Future<void> _openOrganizers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminOrganizersScreen(),
      ),
    );

    if (mounted) {
      _loadDashboardStats();
    }
  }

  // ============================================================
  // OPEN STUDENTS
  // ============================================================

  Future<void> _openStudents() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminStudentsScreen(),
      ),
    );

    if (mounted) {
      _loadDashboardStats();
    }
  }
Future<void> _openDepartmentHeads() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const AdminDepartmentHeadsScreen(),
    ),
  );

  if (mounted) {
    _loadDashboardStats();
  }
}
Future<void> _openOrganizationHeads() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const AdminOrganizationHeadsScreen(),
    ),
  );

  if (mounted) {
    _loadDashboardStats();
  }
}
  // ============================================================
  // COMING SOON / BACKEND NOT CONNECTED
  // ============================================================

  void _showPendingModule(
    String title,
    String description,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.construction_rounded,
                color: Color(0xFFC4B5FD),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            description,
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.60),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double width =
        MediaQuery.sizeOf(context).width;

    final bool compact = width < 380;
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
        child: Stack(
          children: [
            // ==================================================
            // BACKGROUND GLOW
            // ==================================================

            Positioned(
              top: -120,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6)
                      .withOpacity(0.10),
                ),
              ),
            ),

            Positioned(
              bottom: -150,
              left: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6)
                      .withOpacity(0.07),
                ),
              ),
            ),

            // ==================================================
            // MAIN CONTENT
            // ==================================================

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                desktop
                    ? 40
                    : compact
                        ? 14
                        : 20,
                desktop
                    ? 30
                    : compact
                        ? 16
                        : 20,
                desktop
                    ? 40
                    : compact
                        ? 14
                        : 20,
                30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ========================================
                      // HEADER
                      // ========================================

                      _buildHeader(
                        compact: compact,
                        desktop: desktop,
                      ),

                      SizedBox(
                        height:
                            desktop ? 34 : 26,
                      ),

                      // ========================================
                      // PAGE TITLE
                      // ========================================

                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: desktop
                              ? 32
                              : compact
                                  ? 24
                                  : 28,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Manage your CampusSync platform',
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.50),
                          fontSize: 14,
                        ),
                      ),

                      SizedBox(
                        height:
                            desktop ? 30 : 24,
                      ),

                      // ========================================
                      // QUICK OVERVIEW
                      // ========================================

                      _buildOverviewSection(
                        compact: compact,
                        desktop: desktop,
                      ),

                      const SizedBox(height: 28),

                      // ========================================
                      // MANAGEMENT
                      // ========================================

                      const Text(
                        'Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Manage CampusSync users, organizations and platform entities.',
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.42),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 15),

                      _buildManagementGrid(
                        compact: compact,
                        desktop: desktop,
                      ),

                      const SizedBox(height: 20),

                      // ========================================
                      // ADMIN ACCESS INFORMATION
                      // ========================================

                      _buildAccessInformation(),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required bool compact,
    required bool desktop,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 46 : 54,
          height: compact ? 46 : 54,
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
              _initials(widget.user.name),
              style: TextStyle(
                color: Colors.white,
                fontSize:
                    compact ? 16 : 18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ),

        SizedBox(
          width: compact ? 10 : 14,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.white
                      .withOpacity(0.50),
                  fontSize:
                      compact ? 12 : 13,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                widget.user.name,
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
                widget.user.email,
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
      ],
    );
  }

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget _buildOverviewSection({
    required bool compact,
    required bool desktop,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final bool twoColumns =
                constraints.maxWidth >= 650;

            final cards = [
              _OverviewCard(
                icon: Icons.business_rounded,
                title: 'Organizations',
                value: _loadingStats
                    ? '...'
                    : '$_organizationCount',
              ),

              _OverviewCard(
                icon: Icons.groups_rounded,
                title: 'Organizers',
                value: _loadingStats
                    ? '...'
                    : '$_organizerCount',
              ),

              _OverviewCard(
                icon:
                    Icons.verified_user_rounded,
                title: 'Active Organizers',
                value: _loadingStats
                    ? '...'
                    : '$_activeOrganizerCount',
              ),

              _OverviewCard(
                icon:
                    Icons.pending_actions_rounded,
                title: 'First Login Pending',
                value: _loadingStats
                    ? '...'
                    : '$_pendingOrganizerCount',
              ),
            ];

            if (!twoColumns) {
              return Column(
                children: [
                  for (int i = 0;
                      i < cards.length;
                      i++) ...[
                    cards[i],
                    if (i !=
                        cards.length - 1)
                      const SizedBox(
                        height: 10,
                      ),
                  ],
                ],
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.8,
              ),
              itemBuilder:
                  (context, index) {
                return cards[index];
              },
            );
          },
        ),

        if (_statsError != null) ...[
          const SizedBox(height: 10),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.redAccent
                  .withOpacity(0.07),
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent
                    .withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Unable to load dashboard statistics.',
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ),

                TextButton(
                  onPressed:
                      _loadDashboardStats,
                  child:
                      const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // MANAGEMENT GRID
  // ============================================================

  Widget _buildManagementGrid({
    required bool compact,
    required bool desktop,
  }) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final bool twoColumns =
            constraints.maxWidth >= 650;

        final cards = [
          // ====================================================
          // ORGANIZATIONS
          // ====================================================

          _ManagementCard(
            icon: Icons.business_rounded,
            title: 'Organizations',
            subtitle:
                'Create and manage organizations',
            onTap: _openOrganizations,
          ),

          // ====================================================
          // ORGANIZERS
          // ====================================================

          _ManagementCard(
            icon:
                Icons.manage_accounts_rounded,
            title: 'Organizers',
            subtitle:
                'Import and manage organizer accounts',
            onTap: _openOrganizers,
          ),

          // ====================================================
          // STUDENTS
          // ====================================================

          _ManagementCard(
            icon: Icons.school_rounded,
            title: 'Students',
            subtitle:
                'Import and manage student accounts',
            onTap: _openStudents,
          ),

          // ====================================================
          // DEPARTMENT HEADS
          // ====================================================

          _ManagementCard(
            icon: Icons.account_balance_rounded,
            title: 'Department Heads',
            subtitle: 'Manage department head accounts',
            onTap: _openDepartmentHeads,
          ),

          // ====================================================
          // ORGANIZATION HEADS
          // ====================================================

          _ManagementCard(
            icon: Icons.supervisor_account_rounded,
            title: 'Organization Heads',
            subtitle: 'Manage organization head accounts',
            onTap: _openOrganizationHeads,
          ),

          // ====================================================
          // EVENTS
          // ====================================================

          _ManagementCard(
            icon: Icons.event_rounded,
            title: 'Events',
            subtitle:
                'View organizer-posted events',
            pending: true,
            onTap: () {
              _showPendingModule(
                'Events',
                'Admin event viewing is waiting for the Admin Events backend endpoint. The frontend will be connected only after that backend feature is added.',
              );
            },
          ),
        ];

        if (!twoColumns) {
          return Column(
            children: [
              for (int i = 0;
                  i < cards.length;
                  i++) ...[
                cards[i],
                if (i !=
                    cards.length - 1)
                  const SizedBox(
                    height: 12,
                  ),
              ],
            ],
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.7,
          ),
          itemBuilder: (
            context,
            index,
          ) {
            return cards[index];
          },
        );
      },
    );
  }

  // ============================================================
  // ADMIN ACCESS INFORMATION
  // ============================================================

  Widget _buildAccessInformation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6)
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: Color(0xFFC4B5FD),
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrator Access',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Administrative permissions are enforced by the CampusSync backend. The dashboard only exposes features available to the ADMIN role.',
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.40),
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

  // ============================================================
  // INITIALS
  // ============================================================

  String _initials(String name) {
    final String trimmed =
        name.trim();

    if (trimmed.isEmpty) {
      return 'A';
    }

    final List<String> parts =
        trimmed.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first[0]
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

// ================================================================
// OVERVIEW CARD
// ================================================================

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final double width =
        MediaQuery.sizeOf(context).width;

    final bool desktop =
        width >= 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal:
            desktop ? 16 : 14,
        vertical:
            desktop ? 13 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: desktop ? 42 : 40,
            height: desktop ? 42 : 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6)
                  .withOpacity(0.11),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFFC4B5FD),
              size: desktop ? 21 : 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.48),
                    fontSize:
                        desktop ? 11 : 10,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        desktop ? 20 : 18,
                    fontWeight:
                        FontWeight.w700,
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

// ================================================================
// MANAGEMENT CARD
// ================================================================

class _ManagementCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool pending;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    final double width =
        MediaQuery.sizeOf(context).width;

    final bool desktop =
        width >= 900;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
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
                  EdgeInsets.symmetric(
                horizontal:
                    desktop ? 18 : 14,
                vertical:
                    desktop ? 14 : 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.06),
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white
                      .withOpacity(0.10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width:
                        desktop ? 46 : 44,
                    height:
                        desktop ? 46 : 44,
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
                      size:
                          desktop ? 23 : 21,
                    ),
                  ),

                  SizedBox(
                    width:
                        desktop ? 15 : 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize:
                                      desktop
                                          ? 16
                                          : 15,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ),

                            if (pending)
                              Container(
                                margin:
                                    const EdgeInsets
                                        .only(
                                  left: 6,
                                ),
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .orange
                                      .withOpacity(
                                    0.10,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    7,
                                  ),
                                ),
                                child:
                                    const Text(
                                  'Pending',
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .orangeAccent,
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: TextStyle(
                            color: Colors.white
                                .withOpacity(
                              0.45,
                            ),
                            fontSize:
                                desktop
                                    ? 12
                                    : 11,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color: Colors.white
                        .withOpacity(0.30),
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