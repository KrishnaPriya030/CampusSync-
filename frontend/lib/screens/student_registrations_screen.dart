import 'package:flutter/material.dart';

import '../models/registration.dart';
import '../models/event.dart';
import '../services/student_event_service.dart';
import '../services/student_registration_service.dart';
import 'student_event_details_screen.dart';

class StudentRegistrationsScreen extends StatefulWidget {
  const StudentRegistrationsScreen({super.key});

  @override
  State<StudentRegistrationsScreen> createState() =>
      _StudentRegistrationsScreenState();
}

class _StudentRegistrationsScreenState
    extends State<StudentRegistrationsScreen> {
  static const Color backgroundColor = Color(0xFF080B1F);
  static const Color cardColor = Color(0xFF11152D);

  final StudentRegistrationService _registrationService =
      StudentRegistrationService();

  final StudentEventService _eventService =
      StudentEventService();

  List<Registration> _registrations = [];
  final Map<int, Event> _events = {};

  bool _isLoading = true;
  String? _errorMessage;
  int? _cancellingRegistrationId;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  // ------------------------------------------------------------
  // LOAD REGISTRATIONS
  // ------------------------------------------------------------

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final registrations =
          await _registrationService.getMyRegistrations();

      final eventIds = registrations
          .map((registration) => registration.eventId)
          .toSet();

      for (final eventId in eventIds) {
        try {
          final event =
              await _eventService.getPublishedEvent(eventId);

          _events[eventId] = event;
        } catch (_) {
          // Keep the registration visible even if
          // the event details cannot be loaded.
        }
      }

      if (!mounted) return;

      setState(() {
        _registrations = registrations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ------------------------------------------------------------
  // CANCEL REGISTRATION
  // ------------------------------------------------------------

  Future<void> _confirmCancellation(
    Registration registration,
  ) async {
    final event = _events[registration.eventId];

    final eventName = event?.title ??
        'Event #${registration.eventId}';

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Cancel Registration?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel your registration for '
            '"$eventName"?',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Keep Registration',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: backgroundColor,
              ),
              child: const Text(
                'Cancel Registration',
              ),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

    await _cancelRegistration(registration);
  }

  Future<void> _cancelRegistration(
    Registration registration,
  ) async {
    setState(() {
      _cancellingRegistrationId =
          registration.registrationId;
    });

    try {
      await _registrationService.cancelRegistration(
        registration.registrationId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration cancelled successfully.',
          ),
        ),
      );

      await _loadRegistrations();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );

      setState(() {
        _cancellingRegistrationId = null;
      });
    }
  }

  // ------------------------------------------------------------
  // FORMATTING
  // ------------------------------------------------------------

  String _formatDate(DateTime dateTime) {
    final day =
        dateTime.day.toString().padLeft(2, '0');

    final month =
        dateTime.month.toString().padLeft(2, '0');

    return '$day/$month/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour =
        dateTime.hour % 12 == 0
            ? 12
            : dateTime.hour % 12;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period =
        dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _statusText(String status) {
    switch (status) {
      case 'REGISTERED':
        return 'REGISTERED';

      case 'PAYMENT_PENDING':
        return 'PAYMENT PENDING';

      case 'CANCELLED':
        return 'CANCELLED';

      case 'REFUND_PENDING':
        return 'REFUND PENDING';

      case 'REFUNDED':
        return 'REFUNDED';

      default:
        return status;
    }
  }

  bool _canCancel(Registration registration) {
    return registration.status == 'REGISTERED' ||
        registration.status == 'PAYMENT_PENDING';
  }

  // ------------------------------------------------------------
  // REGISTRATION CARD
  // ------------------------------------------------------------

  Widget _registrationCard(
    Registration registration,
  ) {
    final event =
        _events[registration.eventId];

    final canCancel =
        _canCancel(registration);

    final isCancelling =
        _cancellingRegistrationId ==
            registration.registrationId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // EVENT TITLE
            // --------------------------------------------------

            Text(
              event?.title ??
                  'Event #${registration.eventId}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // ORGANIZATION
            // --------------------------------------------------

            if (event != null)
              Row(
                children: [
                  const Icon(
                    Icons.business_rounded,
                    color: Colors.white60,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.organizationName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

            if (event != null)
              const SizedBox(height: 8),

            // --------------------------------------------------
            // VENUE
            // --------------------------------------------------

            if (event != null)
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white60,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.venue,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

            if (event != null)
              const SizedBox(height: 8),

            // --------------------------------------------------
            // EVENT DATE
            // --------------------------------------------------

            if (event != null)
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white60,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(
                      event.startDateTime,
                    ),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

            if (event != null)
              const SizedBox(height: 8),

            // --------------------------------------------------
            // EVENT TIME
            // --------------------------------------------------

            if (event != null)
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white60,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatTime(event.startDateTime)} - '
                    '${_formatTime(event.endDateTime)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // REGISTRATION INFORMATION
            // --------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: _infoChip(
                    'Registration',
                    '#${registration.registrationId}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoChip(
                    'Status',
                    _statusText(
                      registration.status,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // REGISTERED DATE
            // --------------------------------------------------

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Registered on',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(
                    registration.registeredAt,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // VIEW EVENT
            // --------------------------------------------------

            if (event != null)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return StudentEventDetailsScreen(
                            eventId: registration.eventId,
                          );
                        },
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white30,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Event',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // --------------------------------------------------
            // CANCEL
            // --------------------------------------------------

            if (canCancel) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: isCancelling
                      ? null
                      : () {
                          _confirmCancellation(
                            registration,
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white30,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: isCancelling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Cancel Registration',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // INFO CHIP
  // ------------------------------------------------------------

  Widget _infoChip(
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BODY
  // ------------------------------------------------------------

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadRegistrations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor:
                      backgroundColor,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_registrations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRegistrations,
        color: Colors.white,
        backgroundColor: cardColor,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.event_note_rounded,
              color: Colors.white60,
              size: 70,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No registrations yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Text(
                  'Register for an event and it will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRegistrations,
      color: Colors.white,
      backgroundColor: cardColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _registrations.length,
        itemBuilder: (context, index) {
          return _registrationCard(
            _registrations[index],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Registrations',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadRegistrations,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}