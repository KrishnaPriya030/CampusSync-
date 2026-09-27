import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../storage/token_storage.dart';

import 'login_screen.dart';
import 'student_events_screen.dart';
import 'student_registrations_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile user;

  const HomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  final TokenStorage _tokenStorage =
      TokenStorage();

  @override
  void initState() {
    super.initState();

    _screens = [
      _buildDashboard(),
      const StudentEventsScreen(),
      const StudentRegistrationsScreen(),
      _buildProfile(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B1F),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================================================
  // SECTION TITLE
  // ==========================================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.42),
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  Future<void> _logout() async {
    final bool? confirmed =
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

          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
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
              child: const Text(
                'Cancel',
              ),
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
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
              ),
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _tokenStorage.clearToken();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ==========================================================================
  // DASHBOARD
  // ==========================================================================

  Widget _buildDashboard() {
    return RefreshIndicator(
      color:
          const Color(0xFF8B5CF6),

      onRefresh: () async {
        setState(() {});
      },

      child: LayoutBuilder(
        builder:
            (context, constraints) {
          final width =
              constraints.maxWidth;

          final bool compact =
              width < 600;

          final double horizontalPadding =
              compact ? 18 : 28;

          return SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding:
                EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              30,
            ),

            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 1200,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    _buildWelcomeCard(
                      compact,
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    _buildSectionTitle(
                      'CampusSync',
                      'Explore and manage your college events',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildQuickActions(
                      compact,
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    _buildSectionTitle(
                      'Your Activity',
                      'Keep track of your CampusSync activity',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildActivityCards(
                      compact,
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // WELCOME CARD
  // ==========================================================================

  Widget _buildWelcomeCard(
    bool compact,
  ) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(
        compact ? 20 : 26,
      ),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF3154D8),
            Color(0xFF6D3FE7),
            Color(0xFF8B5CF6),
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),

        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF6D3FE7,
            ).withOpacity(0.22),
            blurRadius: 25,
            offset:
                const Offset(0, 12),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,

        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  _greeting(),
                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.72,
                    ),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  widget.user.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        compact
                            ? 23
                            : 28,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Discover events, register, and stay connected with your campus.',
                  maxLines:
                      compact ? 3 : 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.78,
                    ),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Container(
            width:
                compact ? 58 : 70,
            height:
                compact ? 58 : 70,

            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(
                0.16,
              ),

              shape:
                  BoxShape.circle,

              border: Border.all(
                color: Colors.white
                    .withOpacity(
                  0.20,
                ),
              ),
            ),

            child: Center(
              child: Text(
                _initials(
                  widget.user.name,
                ),
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      compact
                          ? 17
                          : 21,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // QUICK ACTIONS
  // ==========================================================================

  Widget _buildQuickActions(
    bool compact,
  ) {
    final actions = [
      _StudentAction(
        title: 'Browse Events',
        subtitle:
            'Find upcoming events',
        icon:
            Icons.event_available_rounded,
        onTap: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      _StudentAction(
        title: 'My Registrations',
        subtitle:
            'View your registrations',
        icon:
            Icons.confirmation_number_outlined,
        onTap: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
      ),
      _StudentAction(
        title: 'My Profile',
        subtitle:
            'View account details',
        icon:
            Icons.person_outline_rounded,
        onTap: () {
          setState(() {
            _selectedIndex = 3;
          });
        },
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (int i = 0;
              i < actions.length;
              i++) ...[
            _buildActionCard(
              actions[i],
            ),

            if (i !=
                actions.length - 1)
              const SizedBox(
                height: 10,
              ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        for (int i = 0;
            i < actions.length;
            i++) ...[
          Expanded(
            child:
                _buildActionCard(
              actions[i],
            ),
          ),

          if (i !=
              actions.length - 1)
            const SizedBox(
              width: 14,
            ),
        ],
      ],
    );
  }

  Widget _buildActionCard(
    _StudentAction action,
  ) {
    return InkWell(
      onTap: action.onTap,
      borderRadius:
          BorderRadius.circular(
        18,
      ),

      child: Container(
        padding:
            const EdgeInsets.all(17),

        decoration:
            BoxDecoration(
          color: const Color(
            0xFF111827,
          ),

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          border: Border.all(
            color: Colors.white
                .withOpacity(
              0.07,
            ),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,

              decoration:
                  BoxDecoration(
                color: const Color(
                  0xFF8B5CF6,
                ).withOpacity(
                  0.13,
                ),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: Icon(
                action.icon,
                color:
                    const Color(
                  0xFFC4B5FD,
                ),
                size: 23,
              ),
            ),

            const SizedBox(
              width: 13,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    action.subtitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        TextStyle(
                      color: Colors.white
                          .withOpacity(
                        0.42,
                      ),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              color:
                  Colors.white30,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // ACTIVITY CARDS
  // ==========================================================================

  Widget _buildActivityCards(
    bool compact,
  ) {
    final cards = [
      _ActivityCardData(
        title: 'Upcoming Events',
        value: 'Explore',
        subtitle:
            'See events available for registration',
        icon:
            Icons.calendar_month_rounded,
      ),
      _ActivityCardData(
        title: 'Registrations',
        value: 'My Events',
        subtitle:
            'Check your registered events',
        icon:
            Icons.event_note_rounded,
      ),
    ];

    if (compact) {
      return Column(
        children: [
          _buildActivityCard(
            cards[0],
          ),
          const SizedBox(
            height: 10,
          ),
          _buildActivityCard(
            cards[1],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildActivityCard(
            cards[0],
          ),
        ),
        const SizedBox(
          width: 14,
        ),
        Expanded(
          child: _buildActivityCard(
            cards[1],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    _ActivityCardData data,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFF111827),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: Colors.white
              .withOpacity(
            0.07,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,

            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFF8B5CF6),
                ],
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),

            child: Icon(
              data.icon,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  data.title,
                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.50,
                    ),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  data.value,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.38,
                    ),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // INFO CARD
  // ==========================================================================

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFF111827),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color:
              const Color(0xFF6366F1)
                  .withOpacity(
            0.15,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons
                .auto_awesome_outlined,
            color:
                Color(0xFFA78BFA),
            size: 21,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Stay connected with CampusSync',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Discover campus events, register for activities, and keep track of your participation from one place.',
                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.43,
                    ),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PROFILE
  // ==========================================================================

  Widget _buildProfile() {
    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(22),

        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 700,
            ),

            child: Column(
              children: [
                const SizedBox(
                  height: 15,
                ),

                Container(
                  width: 88,
                  height: 88,

                  decoration:
                      const BoxDecoration(
                    gradient:
                        LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    shape:
                        BoxShape.circle,
                  ),

                  child: Center(
                    child: Text(
                      _initials(
                        widget.user.name,
                      ),
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 27,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                Text(
                  widget.user.name,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  widget.user.email,
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.45,
                    ),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                _profileRow(
                  Icons.person_outline_rounded,
                  'Name',
                  widget.user.name,
                ),

                const SizedBox(
                  height: 10,
                ),

                _profileRow(
                  Icons.email_outlined,
                  'Email',
                  widget.user.email,
                ),

                const SizedBox(
                  height: 10,
                ),

                _profileRow(
                  Icons
                      .school_outlined,
                  'Role',
                  'Student',
                ),

                const SizedBox(
                  height: 25,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 50,

                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _logout,
                    icon:
                        const Icon(
                      Icons
                          .logout_rounded,
                    ),
                    label:
                        const Text(
                      'Logout',
                    ),
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          Colors.redAccent,
                      side:
                          BorderSide(
                        color:
                            Colors.redAccent
                                .withOpacity(
                          0.35,
                        ),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
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

  Widget _profileRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(15),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFF111827),

        borderRadius:
            BorderRadius.circular(
          15,
        ),

        border: Border.all(
          color: Colors.white
              .withOpacity(
            0.07,
          ),
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color:
                const Color(0xFFA78BFA),
            size: 20,
          ),

          const SizedBox(
            width: 12,
          ),

          Text(
            label,
            style:
                TextStyle(
              color: Colors.white
                  .withOpacity(
                0.42,
              ),
              fontSize: 11,
            ),
          ),

          const Spacer(),

          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION
  // ==========================================================================

  Widget _buildBottomNavigation() {
    return NavigationBarTheme(
      data:
          NavigationBarThemeData(
        backgroundColor:
            const Color(0xFF080D20),

        height: 70,

        indicatorColor:
            const Color(
          0xFF7C3AED,
        ).withOpacity(0.20),

        labelTextStyle:
            WidgetStateProperty
                .resolveWith<
                    TextStyle?>(
          (states) {
            final selected =
                states.contains(
              WidgetState.selected,
            );

            return TextStyle(
              color: selected
                  ? const Color(
                      0xFFC4B5FD,
                    )
                  : Colors.white
                      .withOpacity(
                    0.42,
                  ),
              fontSize: 10,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
            );
          },
        ),

        iconTheme:
            WidgetStateProperty
                .resolveWith<
                    IconThemeData?>(
          (states) {
            final selected =
                states.contains(
              WidgetState.selected,
            );

            return IconThemeData(
              color: selected
                  ? const Color(
                      0xFFC4B5FD,
                    )
                  : Colors.white
                      .withOpacity(
                    0.42,
                  ),
              size: 22,
            );
          },
        ),
      ),

      child: NavigationBar(
        selectedIndex:
            _selectedIndex,

        onDestinationSelected:
            (index) {
          if (index < 0 ||
              index >=
                  _screens.length) {
            return;
          }

          setState(() {
            _selectedIndex =
                index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons
                  .home_outlined,
            ),
            selectedIcon:
                Icon(
              Icons.home_rounded,
            ),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(
              Icons
                  .event_outlined,
            ),
            selectedIcon:
                Icon(
              Icons.event_rounded,
            ),
            label: 'Events',
          ),

          NavigationDestination(
            icon: Icon(
              Icons
                  .confirmation_number_outlined,
            ),
            selectedIcon:
                Icon(
              Icons
                  .confirmation_number_rounded,
            ),
            label: 'Registrations',
          ),

          NavigationDestination(
            icon: Icon(
              Icons
                  .person_outline_rounded,
            ),
            selectedIcon:
                Icon(
              Icons.person_rounded,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  String _greeting() {
    final hour =
        DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  String _initials(
    String name,
  ) {
    final trimmed =
        name.trim();

    if (trimmed.isEmpty) {
      return 'S';
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

// ==============================================================================
// ACTION MODEL
// ==============================================================================

class _StudentAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _StudentAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

// ==============================================================================
// ACTIVITY MODEL
// ==============================================================================

class _ActivityCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _ActivityCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}