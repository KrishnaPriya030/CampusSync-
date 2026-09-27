import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../storage/token_storage.dart';
import 'login_screen.dart';

class AuthenticatedScaffold extends StatefulWidget {
  final UserProfile user;
  final Widget child;

  /// Optional title shown in the app bar.
  final String? title;

  /// Bottom navigation items.
  final List<NavigationDestination> destinations;

  /// Index of the currently selected navigation item.
  final int currentIndex;

  /// Called when the user selects another bottom navigation item.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Whether to show the app bar.
  final bool showAppBar;

  /// Optional custom leading widget.
  final Widget? leading;

  const AuthenticatedScaffold({
    super.key,
    required this.user,
    required this.child,
    required this.destinations,
    required this.currentIndex,
    this.onDestinationSelected,
    this.title,
    this.floatingActionButton,
    this.showAppBar = true,
    this.leading,
  });

  @override
  State<AuthenticatedScaffold> createState() =>
      _AuthenticatedScaffoldState();
}

class _AuthenticatedScaffoldState
    extends State<AuthenticatedScaffold> {
  final TokenStorage _tokenStorage =
      TokenStorage();

  bool _loggingOut = false;

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      await _tokenStorage.clearToken();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loggingOut = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Logout failed: ${_cleanError(e)}',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ==========================================================================
  // ERROR CLEANUP
  // ==========================================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(11);
    }

    return message;
  }

  // ==========================================================================
  // ROLE
  // ==========================================================================

  String get _role {
    return widget.user.role
        .trim()
        .toUpperCase();
  }

  String get _roleLabel {
    switch (_role) {
      case 'ADMIN':
        return 'Administrator';

      case 'ORGANIZER':
        return 'Organizer';

      case 'DEPARTMENT_HEAD':
        return 'Department Head';

      case 'ORGANIZATION_HEAD':
        return 'Organization Head';

      case 'STUDENT':
        return 'Student';

      default:
        return widget.user.role;
    }
  }

  // ==========================================================================
  // INITIALS
  // ==========================================================================

  String _initials(String name) {
    final trimmed =
        name.trim();

    if (trimmed.isEmpty) {
      return 'U';
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

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF060917),

      appBar: widget.showAppBar
          ? _buildAppBar()
          : null,

      body: Container(
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(0xFF060917),
              Color(0xFF0B1430),
              Color(0xFF171033),
            ],
          ),
        ),

        child: SafeArea(
          top: !widget.showAppBar,
          child: widget.child,
        ),
      ),

      floatingActionButton:
          widget.floatingActionButton,

      // IMPORTANT:
      // The same bottom navigation is used on
      // mobile, tablet AND desktop/web.
      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  // ==========================================================================
  // APP BAR
  // ==========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor:
          const Color(0xFF060917),

      elevation: 0,

      surfaceTintColor:
          Colors.transparent,

      leading:
          widget.leading,

      titleSpacing:
          widget.leading == null
              ? 20
              : 0,

      title: widget.title != null
          ? Text(
              widget.title!,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
              ),
            )
          : _buildCompactIdentity(),

      actions: [
        _buildNotificationPlaceholder(),

        const SizedBox(
          width: 4,
        ),

        _buildProfileMenu(),

        const SizedBox(
          width: 8,
        ),
      ],
    );
  }

  // ==========================================================================
  // COMPACT IDENTITY
  // ==========================================================================

  Widget _buildCompactIdentity() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,

          decoration:
              BoxDecoration(
            gradient:
                const LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),

            borderRadius:
                BorderRadius.circular(
              11,
            ),
          ),

          child: Center(
            child: Text(
              _initials(
                widget.user.name,
              ),
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                widget.user.name,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                _roleLabel,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white
                      .withOpacity(0.45),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // NOTIFICATION BUTTON
  // ==========================================================================

  Widget _buildNotificationPlaceholder() {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () {
        _showComingSoon(
          'Notifications',
        );
      },
      icon: Stack(
        clipBehavior:
            Clip.none,
        children: [
          const Icon(
            Icons
                .notifications_none_rounded,
            color: Colors.white70,
          ),

          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 7,
              height: 7,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFA78BFA),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PROFILE MENU
  // ==========================================================================

  Widget _buildProfileMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Account',

      color:
          const Color(0xFF111827),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      offset:
          const Offset(0, 48),

      onSelected: (value) {
        switch (value) {
          case 'profile':
            _showProfile();
            break;

          case 'logout':
            _showLogoutConfirmation();
            break;
        }
      },

      itemBuilder:
          (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(
                Icons
                    .person_outline_rounded,
                color:
                    Color(0xFFC4B5FD),
                size: 20,
              ),

              const SizedBox(
                width: 10,
              ),

              const Text(
                'Profile',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                ),
              ),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons
                    .logout_rounded,
                color:
                    Colors.redAccent,
                size: 20,
              ),

              const SizedBox(
                width: 10,
              ),

              const Text(
                'Logout',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],

      child: Container(
        width: 36,
        height: 36,

        decoration:
            BoxDecoration(
          color:
              Colors.white.withOpacity(
            0.07,
          ),

          borderRadius:
              BorderRadius.circular(
            11,
          ),

          border: Border.all(
            color:
                Colors.white.withOpacity(
              0.08,
            ),
          ),
        ),

        child: Center(
          child: Text(
            _initials(
              widget.user.name,
            ),
            style:
                const TextStyle(
              color:
                  Color(0xFFC4B5FD),
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION
  // ==========================================================================

  Widget _buildBottomNavigation() {
    if (widget.destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    return NavigationBarTheme(
      data:
          NavigationBarThemeData(
        backgroundColor:
            const Color(0xFF080D20),

        indicatorColor:
            const Color(
          0xFF7C3AED,
        ).withOpacity(0.20),

        height: 70,

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
            widget.currentIndex,

        destinations:
            widget.destinations,

        onDestinationSelected:
            widget
                .onDestinationSelected,

        labelBehavior:
            NavigationDestinationLabelBehavior
                .alwaysShow,
      ),
    );
  }

  // ==========================================================================
  // PROFILE
  // ==========================================================================

  void _showProfile() {
    showModalBottomSheet<void>(
      context: context,

      backgroundColor:
          Colors.transparent,

      isScrollControlled: true,

      builder: (context) {
        return Container(
          decoration:
              const BoxDecoration(
            color:
                Color(0xFF111827),

            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(26),
            ),
          ),

          padding:
              const EdgeInsets.fromLTRB(
            22,
            20,
            22,
            28,
          ),

          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(
                      0.18,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                Container(
                  width: 72,
                  height: 72,
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
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
                        fontSize: 24,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Text(
                  widget.user.name,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  widget.user.email,
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.50,
                    ),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF8B5CF6,
                    ).withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Text(
                    _roleLabel,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFFC4B5FD),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                _profileInfoRow(
                  Icons
                      .person_outline_rounded,
                  'Name',
                  widget.user.name,
                ),

                const SizedBox(
                  height: 10,
                ),

                _profileInfoRow(
                  Icons
                      .email_outlined,
                  'Email',
                  widget.user.email,
                ),

                const SizedBox(
                  height: 10,
                ),

                _profileInfoRow(
                  Icons
                      .admin_panel_settings_outlined,
                  'Role',
                  _roleLabel,
                ),

                const SizedBox(
                  height: 22,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 48,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _loggingOut
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                );

                                _showLogoutConfirmation();
                              },
                    icon: _loggingOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.redAccent,
                            ),
                          )
                        : const Icon(
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
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(13),

      decoration:
          BoxDecoration(
        color: Colors.white
            .withOpacity(0.04),

        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color:
                const Color(0xFFA78BFA),
            size: 19,
          ),

          const SizedBox(
            width: 11,
          ),

          Text(
            label,
            style: TextStyle(
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
                color: Colors.white,
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
  // LOGOUT CONFIRMATION
  // ==========================================================================

  Future<void>
      _showLogoutConfirmation() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF111827),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color:
                    Colors.redAccent,
              ),

              SizedBox(width: 10),

              Text(
                'Logout',
                style:
                    TextStyle(
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
              fontSize: 13,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),

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

              child:
                  const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  // ==========================================================================
  // COMING SOON
  // ==========================================================================

  void _showComingSoon(
    String feature,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$feature will be connected to the backend module.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }
}