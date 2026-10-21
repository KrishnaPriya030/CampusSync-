
import 'package:flutter/material.dart';
import '../services/admin_event_service.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final AdminEventService _service = AdminEventService();

  static const Color _background = Color(0xFF080B18);
  static const Color _card = Color(0xFF14182B);
  static const Color _purple = Color(0xFF8B5CF6);

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadEvents();
  }

  Future<List<Map<String, dynamic>>> _loadEvents() {
    return _service.getAllEvents();
  }

  void _reload() {
    setState(() {
      _future = _loadEvents();
    });
  }

  Future<void> _refreshEvents() async {
    final future = _loadEvents();

    setState(() {
      _future = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error and Retry option.
    }
  }

  String _text(
    Map<String, dynamic> event,
    String key, [
    String fallback = '—',
  ]) {
    final value = event[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '—';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final localDate = date.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(localDate.day)}/'
        '${twoDigits(localDate.month)}/'
        '${localDate.year} '
        '${twoDigits(localDate.hour)}:'
        '${twoDigits(localDate.minute)}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return Colors.greenAccent;
      case 'APPROVED':
        return Colors.lightBlueAccent;
      case 'PENDING':
      case 'PENDING_APPROVAL':
      case 'SUBMITTED':
        return Colors.orangeAccent;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.redAccent;
      case 'DRAFT':
        return Colors.white70;
      default:
        return const Color(0xFFC4B5FD);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Events',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh events',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.redAccent,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load events',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error
                          .toString()
                          .replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return RefreshIndicator(
              color: _purple,
              onRefresh: _refreshEvents,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.event_busy_rounded,
                    color: Colors.white38,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No events found.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: _purple,
            onRefresh: _refreshEvents,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];

                final status = _text(
                  event,
                  'status',
                  'UNKNOWN',
                ).toUpperCase();

                final statusColor = _statusColor(status);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _text(event, 'title', 'Untitled event'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _detail(
                        Icons.person_outline_rounded,
                        'Organizer',
                        _text(event, 'organizerName'),
                      ),
                      _detail(
                        Icons.business_outlined,
                        'Organization',
                        _text(event, 'organizationName'),
                      ),
                      _detail(
                        Icons.location_on_outlined,
                        'Venue',
                        _text(event, 'venue'),
                      ),
                      _detail(
                        Icons.calendar_month_outlined,
                        'Starts',
                        _formatDate(event['startDateTime']),
                      ),
                      if (_text(event, 'description', '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _text(event, 'description', ''),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            height: 1.4,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _detail(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFFC4B5FD),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
