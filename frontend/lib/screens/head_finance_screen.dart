
import 'package:flutter/material.dart';

import '../services/head_finance_service.dart';

class HeadFinanceScreen extends StatefulWidget {
  final bool organizationHead;

  const HeadFinanceScreen({
    super.key,
    required this.organizationHead,
  });

  @override
  State<HeadFinanceScreen> createState() => _HeadFinanceScreenState();
}

class _HeadFinanceScreenState extends State<HeadFinanceScreen>
    with SingleTickerProviderStateMixin {
  late final HeadFinanceService _service;
  late final TabController _tabs;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _refunds = [];

  static const Color _background = Color(0xFFF6F7FB);
  static const Color _primary = Color(0xFF6D45D8);
  static const Color _textColor = Color(0xFF262342);

  String _str(
    Map<String, dynamic> map,
    String key, [
    String fallback = '—',
  ]) {
    final value = map[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  double _amount(Map<String, dynamic> map) {
    final value = map['amount'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  @override
  void initState() {
    super.initState();

    _service = HeadFinanceService(
      role: widget.organizationHead
          ? 'organization-head'
          : 'department-head',
    );

    _tabs = TabController(length: 2, vsync: this);

    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || _loading && _error == null && _payments.isNotEmpty) {
      // Prevent an accidental overlapping initial load.
      // Refresh actions remain available once loading completes.
      if (!mounted) return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<
          List<Map<String, dynamic>>>([
        _service.getPayments(),
        _service.getRefunds(),
      ]);

      if (!mounted) return;

      setState(() {
        _payments = results[0];
        _refunds = results[1];
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

  @override
  Widget build(BuildContext context) {
    final title = widget.organizationHead
        ? 'Organization Finance'
        : 'Department Finance';

    final totalPaid = _payments
        .where(
          (payment) =>
              _str(payment, 'status').toUpperCase() == 'PAID',
        )
        .fold<double>(
          0,
          (sum, payment) => sum + _amount(payment),
        );

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: _textColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh finance records',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: _primary,
          unselectedLabelColor: Colors.black54,
          indicatorColor: _primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.payments_outlined),
              text: 'Payments',
            ),
            Tab(
              icon: Icon(Icons.currency_exchange_rounded),
              text: 'Refunds',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? _errorView()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _paymentsView(totalPaid),
                    _refundsView(),
                  ],
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: _primary,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load finance records.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentsView(double totalPaid) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _summary(
            'Paid total',
            '₹${totalPaid.toStringAsFixed(2)}',
            '${_payments.length} payment records',
            Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 12),
          if (_payments.isEmpty)
            const _EmptyState(
              message: 'No payments found for this scope.',
            )
          else
            ..._payments.map(
              (payment) => _recordCard(
                title: _str(
                  payment,
                  'studentName',
                  'Student',
                ),
                subtitle:
                    'Event: ${_str(payment, 'eventId')} • '
                    '${_str(payment, 'status')}',
                amount:
                    '₹${_amount(payment).toStringAsFixed(2)}',
                details: [
                  'Payment ID: ${_str(payment, 'paymentId')}',
                  'Registration ID: ${_str(payment, 'registrationId')}',
                  'Email: ${_str(payment, 'studentEmail')}',
                  'Reference: ${_str(payment, 'paymentReference')}',
                  'Created: ${_str(payment, 'createdAt')}',
                  'Paid at: ${_str(payment, 'paidAt')}',
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _refundsView() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _summary(
            'Refund requests',
            '${_refunds.length}',
            'Refund records for your scope',
            Icons.currency_exchange_rounded,
          ),
          const SizedBox(height: 12),
          if (_refunds.isEmpty)
            const _EmptyState(
              message: 'No refunds found for this scope.',
            )
          else
            ..._refunds.map(
              (refund) => _recordCard(
                title: _str(
                  refund,
                  'studentName',
                  'Student',
                ),
                subtitle:
                    '${_str(refund, 'status')} • '
                    '${_str(refund, 'reason', 'No reason provided')}',
                amount:
                    '₹${_amount(refund).toStringAsFixed(2)}',
                details: [
                  'Refund ID: ${_str(refund, 'refundId')}',
                  'Payment ID: ${_str(refund, 'paymentId')}',
                  'Registration ID: ${_str(refund, 'registrationId')}',
                  'Email: ${_str(refund, 'studentEmail')}',
                  'Requested: ${_str(refund, 'requestedAt')}',
                  'Processed: ${_str(refund, 'processedAt')}',
                  'Processing note: ${_str(refund, 'processingNote')}',
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summary(
    String title,
    String value,
    String caption,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF392779),
            Color(0xFF7654D9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  caption,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordCard({
    required String title,
    required String subtitle,
    required String amount,
    required List<String> details,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        ),
        children: details
            .map(
              (detail) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  2,
                  16,
                  8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
