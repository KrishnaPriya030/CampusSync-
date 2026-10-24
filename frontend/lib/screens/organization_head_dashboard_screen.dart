import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../storage/token_storage.dart';
import 'head_event_management_screen.dart';
import 'head_finance_screen.dart';
import 'login_screen.dart';

class OrganizationHeadDashboardScreen extends StatefulWidget {
  const OrganizationHeadDashboardScreen({super.key});

  @override
  State<OrganizationHeadDashboardScreen> createState() =>
      _OrganizationHeadDashboardScreenState();
}

class _OrganizationHeadDashboardScreenState
    extends State<OrganizationHeadDashboardScreen> {
  static const String _baseUrl = 'http://127.0.0.1:8080';

  final TokenStorage _tokenStorage = TokenStorage();
  final AuthService _authService = AuthService();

  int _currentIndex = 0;

  String _userName = 'Organization Head';
  String _userEmail = '';
  String _userRole = 'ORGANIZATION_HEAD';

  int? _eventCount;
  int? _pendingCount;
  bool _loadingProfile = true;
  bool _loadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadEventStats();
  }

  Future<void> _loadUser() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final user = await _authService.getCurrentUser(token);

      if (!mounted) return;

      setState(() {
        _userName = user.name.trim().isEmpty ? 'Organization Head' : user.name;
        _userEmail = user.email;
        // Organization Head dashboard is already role-specific.
        // Keep the role fixed here so a nullable/missing role field in the
        // current-user JSON can never crash Flutter Web.
        _userRole = 'ORGANIZATION_HEAD';
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingProfile = false;
      });
    }
  }

  Future<void> _loadEventStats() async {
    if (!mounted) return;

    setState(() {
      _loadingStats = true;
      _statsError = null;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      final responses = await Future.wait([
        http.get(
          Uri.parse('$_baseUrl/api/organization-head/events'),
          headers: headers,
        ),
        http.get(
          Uri.parse('$_baseUrl/api/organization-head/events/pending'),
          headers: headers,
        ),
      ]);

      final allResponse = responses[0];
      final pendingResponse = responses[1];

      _checkResponse(allResponse);
      _checkResponse(pendingResponse);

      final allEvents = jsonDecode(allResponse.body);
      final pendingEvents = jsonDecode(pendingResponse.body);

      if (allEvents is! List || pendingEvents is! List) {
        throw Exception('Invalid event data received from server.');
      }

      if (!mounted) return;

      setState(() {
        _eventCount = allEvents.length;
        _pendingCount = pendingEvents.length;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingStats = false;
        _statsError = _cleanError(e);
      });
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Request failed (${response.statusCode}).';

    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final candidate = body['message'] ?? body['error'] ?? body['detail'];
        if (candidate != null && candidate.toString().trim().isNotEmpty) {
          message = candidate.toString();
        }
      }
    } catch (_) {
      // Keep the generic error.
    }

    throw Exception(message);
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _openEvents({bool pending = false}) {
    setState(() {
      _currentIndex = 1;
    });

    // The event screen already provides its own Pending filter.
    // We intentionally keep navigation simple here so the Home action
    // never becomes a dead button.
    if (pending) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Open Pending from the Events filters.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _tokenStorage.clearToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // The actual pages are injected through the indexed stack below using
  // keys + builders so they stay stable while the dashboard state remains
  // responsible for profile, stats and logout.
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHome();
      case 1:
        return const HeadEventManagementScreen(
          role: HeadRole.organizationHead,
        );
      case 2:
        return _buildPayments();
      case 3:
        return _buildProfile();
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEDE7FF),
            Color(0xFFF7F4FF),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF7C3AED),
          onRefresh: () async {
            await Future.wait([
              _loadUser(),
              _loadEventStats(),
            ]);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              desktop ? 42 : 20,
              18,
              desktop ? 42 : 20,
              30,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopAccountBar(),
                      const SizedBox(height: 18),
                      _buildWelcomeBanner(),
                      const SizedBox(height: 24),
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatsGrid(desktop: desktop),
                      const SizedBox(height: 26),
                      const Text(
                        'Quick Access',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickAccessGrid(desktop: desktop),
                      if (_statsError != null) ...[
                        const SizedBox(height: 16),
                        _buildStatsError(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAccountBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Organization Head',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF3B176F),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            setState(() {
              _currentIndex = 3;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(name: _userName),
                const SizedBox(width: 10),
                if (MediaQuery.sizeOf(context).width >= 650)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loadingProfile ? 'Loading...' : _userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _userRole.toString().replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _welcomeMessage() {
    // Defensive handling for an empty or malformed profile name.
    final name = _userName.trim();
    if (name.isEmpty || name == 'Organization Head') {
      return 'Welcome back 👋';
    }

    final parts = name.split(RegExp(r'\s+'));
    final firstName = parts.isEmpty ? '' : parts.first.trim();
    if (firstName.isEmpty) return 'Welcome back 👋';
    return 'Welcome back, $firstName 👋';
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF35106B),
            Color(0xFF6D28D9),
            Color(0xFFA855F7),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.25),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _welcomeMessage(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Manage your organization events and approvals from one place.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({required bool desktop}) {
    final cards = [
      _DashboardStatCard(
        icon: Icons.event_rounded,
        title: 'Events',
        value: _loadingStats ? '—' : '${_eventCount ?? 0}',
      ),
      _DashboardStatCard(
        icon: Icons.pending_actions_rounded,
        title: 'Pending Approval',
        value: _loadingStats ? '—' : '${_pendingCount ?? 0}',
      ),
      const _DashboardStatCard(
        icon: Icons.payments_rounded,
        title: 'Payments',
        value: 'Coming Soon',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 580
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 2.8 : 1.85,
          ),
          itemBuilder: (_, index) => cards[index],
        );
      },
    );
  }

  Widget _buildQuickAccessGrid({required bool desktop}) {
    final cards = [
      _QuickActionCard(
        icon: Icons.pending_actions_rounded,
        title: 'Pending Approval',
        subtitle: 'Review events waiting for approval',
        onTap: () => _openEvents(pending: true),
      ),
      _QuickActionCard(
        icon: Icons.event_rounded,
        title: 'Manage Events',
        subtitle: 'View and manage organization events',
        onTap: () => _openEvents(),
      ),
      _QuickActionCard(
        icon: Icons.payments_rounded,
        title: 'Payments',
        subtitle: 'Payment monitoring will be available later',
        onTap: () {
          setState(() {
            _currentIndex = 2;
          });
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 650
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 4.2 : 2.5,
          ),
          itemBuilder: (_, index) => cards[index],
        );
      },
    );
  }

  Widget _buildStatsError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unable to load event counts right now. Open Events to retry.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadEventStats,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPayments() {
    // Reuse the existing backend-connected finance screen.
    // This passes organizationHead: true so the screen calls:
    // /api/organization-head/finance/payments
    // /api/organization-head/finance/refunds
    return const HeadFinanceScreen(organizationHead: true);
  }

  Widget _buildProfile() {
    return _PageBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SimpleHeader(
              title: 'Profile',
              subtitle: 'Organization Head account',
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _Avatar(
                    name: _userName,
                    radius: 42,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _loadingProfile ? 'Loading...' : _userName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _userEmail.isEmpty ? 'Email unavailable' : _userEmail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ProfileRow(
                    icon: Icons.badge_outlined,
                    title: 'Role',
                    value: _userRole.toString().replaceAll('_', ' '),
                  ),
                  _ProfileRow(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: _userEmail.isEmpty ? 'Unavailable' : _userEmail,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
    );
  }

  Widget _buildBottomNavigationBar() {
    // IMPORTANT:
    // Flutter Web can give bottomNavigationBar a very large height when
    // Center is used directly. That makes the navigation bar appear in the
    // middle of the page and leaves the dashboard body with no visible space.
    // Keep the navigation area at a fixed height, exactly like the working
    // Department Head dashboard.
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 88,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: NavigationBar(
              height: 70,
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0xFFEDE7FF),
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_outlined),
                  selectedIcon: Icon(Icons.event_rounded),
                  label: 'Events',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments_rounded),
                  label: 'Payments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
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

class _PageBackground extends StatelessWidget {
  final Widget child;

  const _PageBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEDE7FF),
            Color(0xFFF7F4FF),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SimpleHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5B21B6),
                Color(0xFFA855F7),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DashboardStatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAF7FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9DFFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEDE4FF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D28D9).withOpacity(0.07),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5B21B6),
                      Color(0xFFA855F7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double radius;

  const _Avatar({
    required this.name,
    this.radius = 18,
  });

  String _initials() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'OH';

    final parts = trimmed.split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'OH';

    final first = parts.first;
    final firstInitial = first.isNotEmpty ? first[0] : 'O';
    if (parts.length == 1) return firstInitial.toUpperCase();

    final last = parts.last;
    final lastInitial = last.isNotEmpty ? last[0] : 'H';
    return '$firstInitial$lastInitial'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF7C3AED),
      child: Text(
        _initials(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.43,
        ),
      ),
    );
  }
}
