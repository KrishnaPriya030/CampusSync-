
import 'package:flutter/material.dart';

import '../services/organizer_participant_service.dart';

class OrganizerEventParticipantsScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const OrganizerEventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<OrganizerEventParticipantsScreen> createState() =>
      _OrganizerEventParticipantsScreenState();
}

class _OrganizerEventParticipantsScreenState
    extends State<OrganizerEventParticipantsScreen> {
  static const Color background = Color(0xFF060917);
  static const Color card = Color(0xFF11152D);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color lavender = Color(0xFFB8A4FF);

  late final OrganizerParticipantService _service;
  List<EventParticipant> _participants = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _service = OrganizerParticipantService();
    _loadParticipants();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getParticipants(widget.eventId);

      if (!mounted) return;

      setState(() {
        _participants = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<EventParticipant> get _filteredParticipants {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return _participants;

    return _participants.where((participant) {
      return participant.name.toLowerCase().contains(query) ||
          participant.email.toLowerCase().contains(query) ||
          participant.registerNumber.toLowerCase().contains(query) ||
          participant.departmentName.toLowerCase().contains(query) ||
          participant.branchName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleParticipants = _filteredParticipants;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Event Participants',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadParticipants,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: lavender,
          onRefresh: _loadParticipants,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25205A), Color(0xFF5B35A8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.eventTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loading
                          ? 'Loading registrations…'
                          : '${_participants.length} confirmed participants',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) => setState(() => _search = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search name, email, register number…',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: lavender,
                  ),
                  filled: true,
                  fillColor: card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(
                    child: CircularProgressIndicator(color: lavender),
                  ),
                )
              else if (_error != null)
                _messageCard(
                  icon: Icons.cloud_off_rounded,
                  message: _error!,
                  action: TextButton.icon(
                    onPressed: _loadParticipants,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                )
              else if (_participants.isEmpty)
                _messageCard(
                  icon: Icons.people_outline_rounded,
                  message: 'No confirmed participants have registered for this event yet.',
                )
              else if (visibleParticipants.isEmpty)
                _messageCard(
                  icon: Icons.search_off_rounded,
                  message: 'No participants match your search.',
                )
              else
                ...visibleParticipants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final participant = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _participantCard(participant, index + 1),
                  );
                }),
              const SizedBox(height: 20),
              const Text(
                'Only registrations returned by the backend are displayed. '
                'Payment-pending registrations are not included in this confirmed-participant list.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _participantCard(EventParticipant participant, int number) {
    final initials = participant.name.trim().isEmpty
        ? '?'
        : participant.name.trim().substring(0, 1).toUpperCase();

    final courseDetails = [
      if (participant.programme.isNotEmpty) participant.programme,
      if (participant.semester != null)
        'Semester ${participant.semester}',
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: purple.withOpacity(0.3),
                foregroundColor: lavender,
                child: Text(initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (participant.email.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        participant.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '#$number',
                style: const TextStyle(
                  color: lavender,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (participant.registerNumber.isNotEmpty)
            _detail(
              Icons.badge_outlined,
              'Register number',
              participant.registerNumber,
            ),
          if (participant.phoneNumber.isNotEmpty)
            _detail(
              Icons.phone_outlined,
              'Phone',
              participant.phoneNumber,
            ),
          if (participant.departmentName.isNotEmpty)
            _detail(
              Icons.account_balance_outlined,
              'Department',
              participant.departmentName,
            ),
          if (participant.branchName.isNotEmpty)
            _detail(
              Icons.school_outlined,
              'Branch',
              participant.branchName,
            ),
          if (courseDetails.isNotEmpty)
            _detail(
              Icons.menu_book_outlined,
              'Programme',
              courseDetails,
            ),
          if (participant.admissionYear != null)
            _detail(
              Icons.calendar_today_outlined,
              'Admission year',
              '${participant.admissionYear}',
            ),
          if (participant.registeredAt != null)
            _detail(
              Icons.access_time_rounded,
              'Registered on',
              _formatDate(participant.registeredAt!),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                participant.status,
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: lavender),
          const SizedBox(width: 9),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: lavender, size: 38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 10),
            action,
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}
