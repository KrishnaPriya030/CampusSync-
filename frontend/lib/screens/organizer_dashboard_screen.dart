
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/event.dart';
import 'create_event_screen.dart';
import 'organizer_operations_screen.dart';
import '../models/user_profile.dart';
import '../services/organizer_event_service.dart';

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
  static const Color _background = Color(0xFF060917);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _lavender = Color(0xFFB8A4FF);
  static const Color _card = Color(0xFF11152D);

  final OrganizerEventService _eventService = OrganizerEventService();

  int selectedIndex = 0;
  List<Event> _events = [];
  bool _isLoadingEvents = true;
  String? _eventError;
  final Set<int> _processingEventIds = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoadingEvents = true;
      _eventError = null;
    });

    try {
      final events = await _eventService.getMyEvents();

      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoadingEvents = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _eventError = _cleanError(error);
        _isLoadingEvents = false;
      });
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  int get _pendingCount => _events.where((event) {
        final status = event.status.toUpperCase();
        return status == 'PENDING' ||
            status == 'PENDING_APPROVAL' ||
            status == 'SUBMITTED' ||
            status == 'PENDING_APPROVALS';
      }).length;

  int get _publishedCount => _events
      .where((event) => event.status.toUpperCase() == 'PUBLISHED')
      .length;

  int get _completedCount => _events
      .where((event) => event.endDateTime.isBefore(DateTime.now()))
      .length;

  List<Event> get _upcomingEvents {
    final result = _events
        .where((event) => event.endDateTime.isAfter(DateTime.now()))
        .toList();

    result.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
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
              Positioned(
                top: -100,
                right: -80,
                child: _glow(
                  size: 260,
                  color: _purple.withOpacity(0.16),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -100,
                child: _glow(
                  size: 280,
                  color: const Color(0xFF3B82F6).withOpacity(0.10),
                ),
              ),
              Column(
                children: [
                  Expanded(child: _buildCurrentPage()),
                  _buildBottomNavigation(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glow({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

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
      case 4:
        return const OrganizerOperationsScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      color: _purple,
      backgroundColor: _card,
      onRefresh: _loadEvents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Organizer Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _iconButton(
                Icons.notifications_none_rounded,
                onTap: () => _showMessage(
                  'Notification screen will be connected separately.',
                ),
              ),
              const SizedBox(width: 8),
              _iconButton(
                Icons.refresh_rounded,
                onTap: _loadEvents,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _profileCard(),
          const SizedBox(height: 26),
          _sectionTitle('Overview'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.event_rounded,
                  title: 'Events',
                  value: _isLoadingEvents ? '—' : '${_events.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.pending_actions_rounded,
                  title: 'Pending',
                  value: _isLoadingEvents ? '—' : '$_pendingCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.public_rounded,
                  title: 'Published',
                  value: _isLoadingEvents ? '—' : '$_publishedCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.event_available_rounded,
                  title: 'Completed',
                  value: _isLoadingEvents ? '—' : '$_completedCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _sectionTitle('Quick Actions'),
          const SizedBox(height: 14),
          
_actionCard(
            icon: Icons.add_circle_outline_rounded,
            title: 'Create Event',
            subtitle: 'Create a new campus event',
            onTap: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateEventScreen(),
                ),
              );

              if (created == true && mounted) {
                await _loadEvents();
              }
            },
          ),

          const SizedBox(height: 12),
          _actionCard(
            icon: Icons.event_note_rounded,
            title: 'My Events',
            subtitle: 'View and manage your events',
            onTap: () => _selectTab(1),
          ),
          const SizedBox(height: 12),
          _actionCard(
            icon: Icons.people_outline_rounded,
            title: 'Participants',
            subtitle: 'View registered participants',
            onTap: () => _selectTab(2),
          ),
          const SizedBox(height: 12),
          _actionCard(
            icon: Icons.analytics_outlined,
            title: 'Event Analytics',
            subtitle: 'View event performance',
            onTap: () => _selectTab(3),
          ),
          const SizedBox(height: 28),
          _sectionTitle('Upcoming Events'),
          const SizedBox(height: 14),
          _buildUpcomingEvents(),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  Widget _profileCard() {
    return _glassCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_purple, Color(0xFF3B82F6)],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ORGANIZER',
                  style: TextStyle(
                    color: _lavender,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    if (_isLoadingEvents) {
      return _glassCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: CircularProgressIndicator(color: _lavender),
          ),
        ),
      );
    }

    if (_eventError != null) {
      return _errorCard(_eventError!, _loadEvents);
    }

    if (_upcomingEvents.isEmpty) {
      return _emptyState(
        icon: Icons.event_available_rounded,
        title: 'No upcoming events',
        subtitle: 'Your upcoming events will appear here.',
      );
    }

    return Column(
      children: _upcomingEvents.take(4).map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _eventCard(event),
        );
      }).toList(),
    );
  }

  Widget _buildEventsPage() {
    return RefreshIndicator(
      color: _purple,
      backgroundColor: _card,
      onRefresh: _loadEvents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          _pageHeader(
            'My Events',
            'View event details, approval status, and available actions.',
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              
onPressed: () async {
  final created = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => const CreateEventScreen(),
    ),
  );

  if (created == true && mounted) {
    await _loadEvents();
  }
},

              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Event'),
              style: _primaryButtonStyle(),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoadingEvents)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(color: _lavender),
              ),
            )
          else if (_eventError != null)
            _errorCard(_eventError!, _loadEvents)
          else if (_events.isEmpty)
            _emptyState(
              icon: Icons.event_note_rounded,
              title: 'No events found',
              subtitle: 'Your events will appear here after you create them.',
            )
          else
            ..._events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _eventCard(event, showDescription: true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantsPage() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _pageHeader(
          'Participants',
          'Select an event to continue to participant management.',
        ),
        const SizedBox(height: 20),
        if (_isLoadingEvents)
          const Center(
            child: CircularProgressIndicator(color: _lavender),
          )
        else if (_eventError != null)
          _errorCard(_eventError!, _loadEvents)
        else if (_events.isEmpty)
          _emptyState(
            icon: Icons.people_outline_rounded,
            title: 'No events available',
            subtitle: 'Create an event before managing its participants.',
          )
        else
          ..._events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _actionCard(
                icon: Icons.groups_rounded,
                title: event.title,
                subtitle: 'Status: ${_formatStatus(event.status)}',
                onTap: () => _showMessage(
                  'Participant records for event ${event.id} '
                  'will be connected after verifying the registration API.',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyticsPage() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _pageHeader(
          'Event Analytics',
          'A summary of your event records.',
        ),
        const SizedBox(height: 22),
        if (_isLoadingEvents)
          const Center(
            child: CircularProgressIndicator(color: _lavender),
          )
        else if (_eventError != null)
          _errorCard(_eventError!, _loadEvents)
        else ...[
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.event_rounded,
                  title: 'Total events',
                  value: '${_events.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.public_rounded,
                  title: 'Published',
                  value: '$_publishedCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.pending_actions_rounded,
                  title: 'Pending',
                  value: '$_pendingCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.event_available_rounded,
                  title: 'Completed',
                  value: '$_completedCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: const Text(
              'Participant totals and revenue analytics require '
              'their corresponding backend data.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _eventCard(
    Event event, {
    bool showDescription = false,
  }) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.17),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: _lavender,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.venue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusChip(event.status),
                  const SizedBox(height: 2),
                  _eventActionsMenu(event),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(
            Icons.calendar_today_rounded,
            _formatDate(event.startDateTime),
          ),
          const SizedBox(height: 8),
          _detailRow(
            Icons.payments_outlined,
            event.paymentType.toUpperCase() == 'PAID'
                ? 'Fee: ₹${event.registrationFee.toStringAsFixed(2)}'
                : 'Free event',
          ),
          if (showDescription && event.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _eventActionsMenu(Event event) {
    final status = event.status.toUpperCase();
    final isProcessing = _processingEventIds.contains(event.id);

    final canSubmit = status == 'DRAFT' || status == 'REJECTED';
    final canPublish = status == 'APPROVED';
    final canCancel = status == 'PUBLISHED';

    return PopupMenuButton<String>(
      tooltip: 'Event actions',
      enabled: !isProcessing,
      icon: isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _lavender,
              ),
            )
          : const Icon(
              Icons.more_vert_rounded,
              color: Colors.white70,
              size: 22,
            ),
      color: const Color(0xFF171033),
      onSelected: (action) => _handleEventAction(event, action),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (canSubmit) {
          items.add(
            const PopupMenuItem(
              value: 'submit',
              child: Row(
                children: [
                  Icon(Icons.send_rounded, color: _lavender, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Submit for approval',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        if (canPublish) {
          items.add(
            const PopupMenuItem(
              value: 'publish',
              child: Row(
                children: [
                  Icon(Icons.public_rounded, color: _lavender, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Publish event',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        if (canCancel) {
          items.add(
            const PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    color: Colors.orangeAccent,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Cancel event',
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                ],
              ),
            ),
          );
        }

        if (status != 'CANCELLED') {
          items.add(
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Delete event',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          );
        }

        if (items.isEmpty) {
          items.add(
            const PopupMenuItem(
              enabled: false,
              child: Text(
                'No actions available',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        return items;
      },
    );
  }

  Future<void> _handleEventAction(
    Event event,
    String action,
  ) async {
    if (_processingEventIds.contains(event.id)) return;

    final isDelete = action == 'delete';
    final isCancel = action == 'cancel';
    final isSubmit = action == 'submit';

    final title = isDelete
        ? 'Delete event?'
        : isCancel
            ? 'Cancel event?'
            : isSubmit
                ? 'Submit for approval?'
                : 'Publish event?';

    final message = isDelete
        ? 'Delete "${event.title}"? This action may not be reversible.'
        : isCancel
            ? 'Cancel "${event.title}"?'
            : isSubmit
                ? 'Submit "${event.title}" for approval?'
                : 'Publish "${event.title}"?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDelete ? Colors.redAccent : _purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingEventIds.add(event.id);
    });

    try {
      switch (action) {
        case 'submit':
          await _eventService.submitForApproval(event.id);
          break;
        case 'publish':
          await _eventService.publishEvent(event.id);
          break;
        case 'cancel':
          await _eventService.cancelEvent(event.id);
          break;
        case 'delete':
          await _eventService.deleteEvent(event.id);
          break;
        default:
          return;
      }

      if (!mounted) return;

      _showMessage(
        action == 'submit'
            ? 'Event submitted for approval.'
            : action == 'publish'
                ? 'Event published.'
                : action == 'cancel'
                    ? 'Event cancelled.'
                    : 'Event deleted.',
      );

      await _loadEvents();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() {
          _processingEventIds.remove(event.id);
        });
      }
    }
  }

  Widget _statusChip(String status) {
    final normalized = status.toUpperCase();

    final Color statusColor = normalized == 'PUBLISHED'
        ? const Color(0xFF86EFAC)
        : normalized == 'REJECTED' || normalized == 'CANCELLED'
            ? const Color(0xFFFCA5A5)
            : normalized == 'APPROVED'
                ? const Color(0xFF93C5FD)
                : _lavender;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.30),
        ),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/${date.year} • $hour:$minute $period';
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _lavender),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return _glassCard(
      child: Column(
        children: [
          Icon(icon, size: 44, color: _lavender),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message, VoidCallback retry) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load data',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            child: Row(
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
                _navItem(
                  index: 4,
                  icon: Icons.tune_rounded,
                  label: 'Manage',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? _purple.withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? _lavender : Colors.white54,
                size: 23,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _lavender, size: 25),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.white.withOpacity(0.06),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _lavender, size: 23),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white38,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Material(
        color: Colors.white.withOpacity(0.07),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _purple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  void _selectTab(int index) {
    if (!mounted) return;

    setState(() {
      selectedIndex = index;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF171033),
      ),
    );
  }
}
