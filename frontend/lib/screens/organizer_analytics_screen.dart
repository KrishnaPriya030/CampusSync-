
import 'package:flutter/material.dart';

import '../models/organizer_analytics.dart';
import '../services/organizer_analytics_service.dart';

class OrganizerAnalyticsScreen extends StatefulWidget {
  final Future<String?> Function() getToken;

  const OrganizerAnalyticsScreen({
    super.key,
    required this.getToken,
  });

  @override
  State<OrganizerAnalyticsScreen> createState() =>
      _OrganizerAnalyticsScreenState();
}

class _OrganizerAnalyticsScreenState
    extends State<OrganizerAnalyticsScreen> {
  late final OrganizerAnalyticsService _service;

  OrganizerAnalytics? _analytics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _service = OrganizerAnalyticsService(
      getToken: widget.getToken,
    );

    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await _service.fetchAnalytics();

      if (!mounted) return;

      setState(() {
        _analytics = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  String _money(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF172554);
    const purple = Color(0xFF6D5AE6);
    const background = Color(0xFFF5F7FC);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Event Analytics',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: _loading ? null : _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _buildBody(navy, purple),
      ),
    );
  }

  Widget _buildBody(Color navy, Color purple) {
    if (_loading && _analytics == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _analytics == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 52,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load analytics',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final analytics = _analytics!;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF172554),
                  Color(0xFF6D5AE6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Organizer overview',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${analytics.totalEvents} events',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${analytics.totalParticipants} confirmed participants',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                if (_loading) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          const Text(
            'Financial summary',
            style: TextStyle(
              color: Color(0xFF172554),
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 3 : 2;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * 12) /
                      columns;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _metricCard(
                      title: 'Gross revenue',
                      value: _money(analytics.grossRevenue),
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF287D60),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _metricCard(
                      title: 'Completed refunds',
                      value: _money(analytics.completedRefunds),
                      icon: Icons.currency_exchange,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _metricCard(
                      title: 'Net revenue',
                      value: _money(analytics.netRevenue),
                      icon: Icons.trending_up,
                      color: purple,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 26),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Event breakdown',
                  style: TextStyle(
                    color: Color(0xFF172554),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${analytics.events.length} events',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (analytics.events.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 42,
                    color: Colors.black38,
                  ),
                  SizedBox(height: 10),
                  Text('No events found for this organizer.'),
                ],
              ),
            )
          else
            ...analytics.events.map(
              (event) => _eventCard(event, navy, purple),
            ),

          if (_error != null && _analytics != null) ...[
            const SizedBox(height: 12),
            Text(
              'Refresh failed: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ],

          const SizedBox(height: 20),
          const Text(
            'Participants include registrations currently marked REGISTERED. '
            'Revenue is based on captured payments less completed refunds.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172554),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(
    EventAnalytics event,
    Color navy,
    Color purple,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.eventTitle,
            style: TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                color: Colors.blueGrey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text('Confirmed participants')),
              Text(
                '${event.totalParticipants}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _eventAmount(
            'Gross revenue',
            _money(event.grossRevenue),
          ),
          _eventAmount(
            'Completed refunds',
            _money(event.completedRefunds),
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Net revenue',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _money(event.netRevenue),
                style: TextStyle(
                  color: purple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _eventAmount(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
