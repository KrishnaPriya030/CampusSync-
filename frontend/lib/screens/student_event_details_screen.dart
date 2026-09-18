import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/student_event_service.dart';
import 'student_registration_screen.dart';

class StudentEventDetailsScreen extends StatefulWidget {
  final int eventId;

  const StudentEventDetailsScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<StudentEventDetailsScreen> createState() =>
      _StudentEventDetailsScreenState();
}

class _StudentEventDetailsScreenState
    extends State<StudentEventDetailsScreen> {
  static const Color backgroundColor = Color(0xFF080B1F);

  final StudentEventService _eventService = StudentEventService();

  Event? _event;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _eventService.getPublishedEvent(
        widget.eventId,
      );

      if (!mounted) return;

      setState(() {
        _event = event;
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

  Future<void> _openRegistration() async {
    if (_event == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return StudentRegistrationScreen(
            event: _event!,
          );
        },
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');

    return '$day/$month/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour =
        dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11152D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            mainAxisAlignment: MainAxisAlignment.center,
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
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  _loadEvent();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_event == null) {
      return const Center(
        child: Text(
          'Event not found',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }

    final event = _event!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

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
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _infoRow(
            Icons.description_outlined,
            'Description',
            event.description,
          ),

          _infoRow(
            Icons.location_on_outlined,
            'Venue',
            event.venue,
          ),

          _infoRow(
            Icons.calendar_today_outlined,
            'Date',
            _formatDate(event.startDateTime),
          ),

          _infoRow(
            Icons.access_time_rounded,
            'Time',
            '${_formatTime(event.startDateTime)} - '
                '${_formatTime(event.endDateTime)}',
          ),

          _infoRow(
            Icons.event_available_outlined,
            'Registration Deadline',
            '${_formatDate(event.registrationDeadline)} '
                '${_formatTime(event.registrationDeadline)}',
          ),

          _infoRow(
            Icons.people_outline_rounded,
            'Capacity',
            event.capacityType == 'UNLIMITED'
                ? 'Unlimited'
                : '${event.capacity ?? 0} participants',
          ),

          _infoRow(
            Icons.payments_outlined,
            'Registration Fee',
            event.paymentType == 'PAID'
                ? '₹${event.registrationFee.toStringAsFixed(2)}'
                : 'FREE',
          ),

          if (event.refundPolicy != null &&
              event.refundPolicy!.isNotEmpty)
            _infoRow(
              Icons.currency_exchange_rounded,
              'Refund Policy',
              event.refundPolicy!,
            ),

          if (event.attendanceEnabled)
            _infoRow(
              Icons.qr_code_rounded,
              'Attendance',
              'QR-based attendance is enabled',
            ),

          if (event.certificateEnabled)
            _infoRow(
              Icons.workspace_premium_outlined,
              'Certificate',
              'Certificate will be available after the event',
            ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _openRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                event.paymentType == 'PAID'
                    ? 'Register & Pay ₹${event.registrationFee.toStringAsFixed(0)}'
                    : 'Register for Event',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Event Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}