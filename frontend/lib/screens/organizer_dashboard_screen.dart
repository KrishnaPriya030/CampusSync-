import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  final UserProfile user;

  const OrganizerDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState
    extends State<OrganizerDashboardScreen> {
  int selectedIndex = 0;

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
              // ==================================================
              // BACKGROUND GLOW - TOP RIGHT
              // ==================================================

              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        const Color(0xFF8B5CF6)
                            .withOpacity(0.16),
                  ),
                ),
              ),

              // ==================================================
              // BACKGROUND GLOW - BOTTOM LEFT
              // ==================================================

              Positioned(
                bottom: -120,
                left: -100,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        const Color(0xFF3B82F6)
                            .withOpacity(0.10),
                  ),
                ),
              ),

              // ==================================================
              // MAIN CONTENT
              // ==================================================

              Column(
                children: [
                  Expanded(
                    child: _buildCurrentPage(),
                  ),

                  _buildBottomNavigation(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // CURRENT PAGE
  // ==============================================================

  Widget _buildCurrentPage() {
    switch (selectedIndex) {
      case 0:
        return _buildDashboard();

      case 1:
        return _buildEventsPage();

      case 2:
        return _buildParticipantsPage();

      case 3:
        return _buildAnalyticsPage();

      default:
        return _buildDashboard();
    }
  }

  // ==============================================================
  // DASHBOARD
  // ==============================================================

  Widget _buildDashboard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ========================================================
          // HEADER
          // ========================================================

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning 👋',
                      style: TextStyle(
                        color:
                            Colors.white
                                .withOpacity(0.60),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Organizer Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              _glassIconButton(
                icon:
                    Icons.notifications_none_rounded,
                onTap: () {
                  _showMessage(
                    'No new notifications',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 25),

          // ========================================================
          // PROFILE CARD
          // ========================================================

          _glassCard(
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF3B82F6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(
                              0xFF8B5CF6,
                            ).withOpacity(0.30),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        widget.user.email,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.50),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'ORGANIZER',
                        style: TextStyle(
                          color:
                              const Color(
                                0xFFB8A4FF,
                              ),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ========================================================
          // OVERVIEW
          // ========================================================

          const Text(
            'Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          // ========================================================
          // STAT CARDS
          // ========================================================

          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.event_rounded,
                  title: 'Events',
                  value: '0',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _statCard(
                  icon:
                      Icons.people_alt_rounded,
                  title: 'Participants',
                  value: '0',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon:
                      Icons.pending_actions_rounded,
                  title: 'Pending',
                  value: '0',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _statCard(
                  icon:
                      Icons.check_circle_outline_rounded,
                  title: 'Completed',
                  value: '0',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ========================================================
          // QUICK ACTIONS
          // ========================================================

          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          _actionCard(
            icon:
                Icons.add_circle_outline_rounded,
            title: 'Create Event',
            subtitle:
                'Create a new campus event',
            onTap: () {
              _showMessage(
                'Create Event coming next',
              );
            },
          ),

          const SizedBox(height: 12),

          _actionCard(
            icon: Icons.event_note_rounded,
            title: 'My Events',
            subtitle:
                'View and manage your events',
            onTap: () {
              setState(() {
                selectedIndex = 1;
              });
            },
          ),

          const SizedBox(height: 12),

          _actionCard(
            icon: Icons.people_outline_rounded,
            title: 'Participants',
            subtitle:
                'View registered participants',
            onTap: () {
              setState(() {
                selectedIndex = 2;
              });
            },
          ),

          const SizedBox(height: 12),

          _actionCard(
            icon: Icons.analytics_outlined,
            title: 'Event Analytics',
            subtitle:
                'View event performance',
            onTap: () {
              setState(() {
                selectedIndex = 3;
              });
            },
          ),

          const SizedBox(height: 28),

          // ========================================================
          // UPCOMING EVENTS
          // ========================================================

          const Text(
            'Upcoming Events',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          _glassCard(
            child: Column(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 45,
                  color:
                      Colors.white
                          .withOpacity(0.30),
                ),

                const SizedBox(height: 12),

                const Text(
                  'No upcoming events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Create your first event to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.white
                            .withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==============================================================
  // EVENTS PAGE
  // ==============================================================

  Widget _buildEventsPage() {
    return _simplePage(
      icon: Icons.event_note_rounded,
      title: 'My Events',
      subtitle:
          'Create and manage your campus events.',
      buttonText: 'Create Event',
      onPressed: () {
        _showMessage(
          'Create Event coming next',
        );
      },
    );
  }

  // ==============================================================
  // PARTICIPANTS PAGE
  // ==============================================================

  Widget _buildParticipantsPage() {
    return _simplePage(
      icon: Icons.people_outline_rounded,
      title: 'Participants',
      subtitle:
          'View students registered for your events.',
      buttonText: 'View Participants',
      onPressed: () {
        _showMessage(
          'Participant management coming next',
        );
      },
    );
  }

  // ==============================================================
  // ANALYTICS PAGE
  // ==============================================================

  Widget _buildAnalyticsPage() {
    return _simplePage(
      icon: Icons.analytics_outlined,
      title: 'Event Analytics',
      subtitle:
          'Track event performance and participation.',
      buttonText: 'View Analytics',
      onPressed: () {
        _showMessage(
          'Analytics coming next',
        );
      },
    );
  }

  // ==============================================================
  // SIMPLE PAGE
  // ==============================================================

  Widget _simplePage({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            subtitle,
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.50),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 30),

          _glassCard(
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 65,
                  color:
                      const Color(0xFFB8A4FF),
                ),

                const SizedBox(height: 18),

                Text(
                  'Nothing here yet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.45),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(
                      Icons.add_rounded,
                    ),
                    label: Text(
                      buttonText,
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                            0xFF8B5CF6,
                          ),
                      foregroundColor:
                          Colors.white,
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
    );
  }

  // ==============================================================
  // BOTTOM NAVIGATION
  // ==============================================================

  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        12,
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.08),
              borderRadius:
                  BorderRadius.circular(24),
              border: Border.all(
                color:
                    Colors.white.withOpacity(
                  0.12,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                ),
                _navItem(
                  index: 1,
                  icon: Icons.event_rounded,
                  label: 'Events',
                ),
                _navItem(
                  index: 2,
                  icon: Icons.people_alt_rounded,
                  label: 'People',
                ),
                _navItem(
                  index: 3,
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // NAV ITEM
  // ==============================================================

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected =
        selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding:
              const EdgeInsets.symmetric(
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF8B5CF6)
                    .withOpacity(0.18)
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSlide(
                duration: const Duration(
                  milliseconds: 250,
                ),
                curve: Curves.easeOutCubic,
                offset: selected
                    ? const Offset(0, -0.05)
                    : Offset.zero,
                child: Icon(
                  icon,
                  color: selected
                      ? const Color(
                          0xFFB8A4FF,
                        )
                      : Colors.white54,
                  size: 23,
                ),
              ),

              const SizedBox(height: 4),

              AnimatedDefaultTextStyle(
                duration: const Duration(
                  milliseconds: 200,
                ),
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white54,
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

  // ==============================================================
  // GLASS CARD
  // ==============================================================

  Widget _glassCard({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.07),
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ==============================================================
  // STAT CARD
  // ==============================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return _glassCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                const Color(0xFFB8A4FF),
            size: 26,
          ),

          const SizedBox(height: 16),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: TextStyle(
              color:
                  Colors.white.withOpacity(0.48),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // ACTION CARD
  // ==============================================================

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Material(
          color:
              Colors.white.withOpacity(0.06),
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(18),
            child: Container(
              padding:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(
                    0.10,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          const Color(
                            0xFF8B5CF6,
                          ).withOpacity(0.14),
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color:
                          const Color(
                            0xFFB8A4FF,
                          ),
                      size: 24,
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
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white
                                .withOpacity(0.42),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color: Colors.white38,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // GLASS ICON BUTTON
  // ==============================================================

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Material(
          color:
              Colors.white.withOpacity(0.07),
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(16),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(
                    0.12,
                  ),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // MESSAGE
  // ==============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF171033),
      ),
    );
  }
}