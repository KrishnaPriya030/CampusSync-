import 'package:flutter/material.dart';

import '../../services/organizer_operations_service.dart';

/// Payments, refunds, notifications, registrations, attendance and certificates.
/// All mutations are sent to the matching authenticated backend endpoints.
class OrganizerOperationsScreen extends StatefulWidget {
  const OrganizerOperationsScreen({super.key});

  @override
  State<OrganizerOperationsScreen> createState() => _OrganizerOperationsScreenState();
}

class _OrganizerOperationsScreenState extends State<OrganizerOperationsScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF060917);
  static const _surface = Color(0xFF11152D);
  static const _purple = Color(0xFF8B5CF6);
  static const _lavender = Color(0xFFC4B5FD);
  final _api = OrganizerOperationsService();
  final _eventIdController = TextEditingController();
  late final TabController _tabs;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _unreadCount = 0;
  static const _labels = ['Notifications', 'Payments', 'Refunds', 'Registrations', 'Attendance', 'Certificates'];
  static const _icons = [Icons.notifications_active_rounded, Icons.payments_rounded, Icons.currency_exchange_rounded, Icons.people_alt_rounded, Icons.fact_check_rounded, Icons.workspace_premium_rounded];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _labels.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _loadCurrent();
    });
    _loadCurrent();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _eventIdController.dispose();
    super.dispose();
  }

  int? get _eventId => int.tryParse(_eventIdController.text.trim());

  Future<void> _loadCurrent() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      List<Map<String, dynamic>> items;
      switch (_tabs.index) {
        case 0:
          items = await _api.getNotifications();
          _unreadCount = await _api.getUnreadCount();
          break;
        case 1:
          items = await _api.getPayments();
          break;
        case 2:
          items = await _api.getRefunds();
          break;
        case 3:
          final id = _eventId;
          if (id == null || id <= 0) { items = []; break; }
          items = await _api.getRegistrations(id);
          break;
        case 4:
          final id = _eventId;
          if (id == null || id <= 0) { items = []; break; }
          final registrations = await _api.getRegistrations(id);
          final attendance = await _api.getAttendance(id);
          final byRegistration = <int, Map<String, dynamic>>{};
          for (final row in attendance) {
            final regId = _int(row['registrationId']);
            if (regId != null) byRegistration[regId] = row;
          }
          items = registrations.map((r) {
            final idValue = _int(r['id'] ?? r['registrationId']);
            return <String, dynamic>{...r, '_attendance': idValue == null ? null : byRegistration[idValue]};
          }).toList();
          break;
        case 5:
          final id = _eventId;
          if (id == null || id <= 0) { items = []; break; }
          final certificates = await _api.getCertificates(id);
          final registrations = await _api.getRegistrations(id);
          final issuedStudentIds = certificates.map((c) => _int(c['studentId'])).whereType<int>().toSet();
          final notIssued = registrations.where((r) {
            final studentId = _int(r['studentId']);
            return studentId != null && !issuedStudentIds.contains(studentId) &&
                _value(r, ['status', 'registrationStatus']).toUpperCase() == 'REGISTERED';
          }).map((r) => <String, dynamic>{...r, '_toIssue': true}).toList();
          items = [...certificates, ...notIssued];
          break;
        default:
          items = [];
      }
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _cleanError(e); _loading = false; });
    }
  }

  static int? _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value');
  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
  String _value(Map<String, dynamic> row, List<String> keys, {String fallback = '—'}) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return fallback;
  }
  String _status(Map<String, dynamic> row) => _value(row, ['status', 'paymentStatus', 'refundStatus', 'registrationStatus', 'state'], fallback: 'UNKNOWN').toUpperCase();

  Future<void> _runAction(Future<dynamic> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      await _loadCurrent();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    }
  }

  Future<String?> _askNote(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      backgroundColor: _surface,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: TextField(controller: controller, maxLines: 3, style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: 'Processing note (optional)', labelStyle: TextStyle(color: Colors.white60))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Continue'))],
    ));
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final eventScoped = _tabs.index >= 3;
    return Container(
      color: _bg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Organizer operations', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('Payments, refunds, notifications and event operations', style: TextStyle(color: Colors.white.withOpacity(.62))),
          const SizedBox(height: 14),
          if (eventScoped) Row(children: [
            Expanded(child: TextField(controller: _eventIdController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Enter event ID', hintStyle: const TextStyle(color: Colors.white38), prefixIcon: const Icon(Icons.event, color: _lavender), filled: true, fillColor: _surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _loadCurrent, icon: const Icon(Icons.search), style: IconButton.styleFrom(backgroundColor: _purple)),
          ]),
        ])),
        SizedBox(height: 48, child: TabBar(controller: _tabs, isScrollable: true, tabAlignment: TabAlignment.start,
          indicatorColor: _lavender, labelColor: Colors.white, unselectedLabelColor: Colors.white54,
          tabs: List.generate(_labels.length, (i) => Tab(icon: Icon(_icons[i], size: 17), text: _labels[i])))),
        if (_tabs.index == 0)
          Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 0), child: Row(children: [
            Expanded(child: Text('Unread notifications: $_unreadCount', style: const TextStyle(color: _lavender, fontWeight: FontWeight.w600))),
            if (_unreadCount > 0) TextButton(onPressed: () => _runAction(() => _api.markAllNotificationsRead(), 'All notifications marked as read'), child: const Text('Mark all read')),
          ])),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _lavender))
          : _error != null
            ? _errorView()
            : _items.isEmpty
              ? _emptyView(eventScoped)
              : RefreshIndicator(color: _lavender, onRefresh: _loadCurrent, child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _buildItem(_items[index]),
                ))),
      ]),
    );
  }

  Widget _emptyView(bool eventScoped) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(_icons[_tabs.index], color: _lavender, size: 42), const SizedBox(height: 12),
    Text(eventScoped && (_eventId == null || _eventId! <= 0) ? 'Enter an event ID above' : 'No ${_labels[_tabs.index].toLowerCase()} found', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
    const SizedBox(height: 6), const Text('Pull down to refresh after making changes.', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
  ])));

  Widget _errorView() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off_rounded, size: 42, color: Colors.orangeAccent), const SizedBox(height: 12),
    Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center), const SizedBox(height: 12),
    OutlinedButton.icon(onPressed: _loadCurrent, icon: const Icon(Icons.refresh), label: const Text('Retry')),
  ])));

  Widget _buildItem(Map<String, dynamic> row) {
    switch (_tabs.index) {
      case 0: return _notificationCard(row);
      case 1: return _paymentCard(row);
      case 2: return _refundCard(row);
      case 3: return _registrationCard(row);
      case 4: return _attendanceCard(row);
      case 5: return _certificateCard(row);
      default: return const SizedBox.shrink();
    }
  }

  Widget _card({required Widget child}) => Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.08))), child: child);
  Widget _heading(String title, String subtitle, {String? status}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))), if (status != null) _pill(status)]),
    if (subtitle.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12))),
  ]);
  Widget _pill(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: _purple.withOpacity(.18), borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(color: _lavender, fontSize: 10, fontWeight: FontWeight.w700)));
  Widget _actions(List<Widget> children) => Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 8, runSpacing: 8, children: children));
  Widget _action(String label, IconData icon, VoidCallback onTap, {bool primary = false}) => OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 16), label: Text(label), style: OutlinedButton.styleFrom(foregroundColor: primary ? _lavender : Colors.white70, side: BorderSide(color: primary ? _purple : Colors.white24), visualDensity: VisualDensity.compact));

  Widget _notificationCard(Map<String, dynamic> row) {
    final id = _int(row['id'] ?? row['notificationId']);
    final read = row['read'] == true || row['isRead'] == true;
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading(_value(row, ['title'], fallback: 'Notification'), _value(row, ['message']), status: read ? 'READ' : 'UNREAD'),
      const SizedBox(height: 8), Text('${_value(row, ['type'])}  •  ${_value(row, ['createdAt'])}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
      if (!read && id != null) _actions([_action('Mark as read', Icons.done, () => _runAction(() => _api.markNotificationRead(id), 'Notification marked as read'), primary: true)]),
      if (!read && id == null) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Notification ID is missing from the API response.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12))),
      if (row.isNotEmpty && row['id'] == null && row['notificationId'] == null) const SizedBox.shrink(),
    ]));
  }

  Widget _paymentCard(Map<String, dynamic> row) {
    final id = _int(row['id'] ?? row['paymentId']);
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading(_value(row, ['eventTitle', 'eventName'], fallback: 'Payment #${id ?? '—'}'), _value(row, ['studentName', 'studentEmail', 'email']), status: _status(row)),
      const SizedBox(height: 8), Text('Amount: ${_value(row, ['amount', 'registrationFee', 'totalAmount'])}  •  Payment ID: ${id ?? '—'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      if (id != null) _actions([_action('Approve', Icons.check_circle_outline, () => _confirmAction('Approve payment #$id?', () => _runAction(() => _api.approvePayment(id), 'Payment approved')), primary: true), _action('Reject', Icons.cancel_outlined, () => _confirmAction('Reject payment #$id?', () => _runAction(() => _api.rejectPayment(id), 'Payment rejected')))]),
    ]));
  }

  Widget _refundCard(Map<String, dynamic> row) {
    final id = _int(row['id'] ?? row['refundId']);
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading(_value(row, ['eventTitle', 'eventName'], fallback: 'Refund #${id ?? '—'}'), _value(row, ['studentName', 'studentEmail', 'reason']), status: _status(row)),
      const SizedBox(height: 8), Text('Amount: ${_value(row, ['amount'])}  •  Refund ID: ${id ?? '—'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      if (id != null) _actions([_action('Approve refund', Icons.check_circle_outline, () async { final note = await _askNote('Approve refund #$id'); if (note != null) await _runAction(() => _api.approveRefund(id, note: note), 'Refund approved'); }, primary: true), _action('Reject refund', Icons.cancel_outlined, () async { final note = await _askNote('Reject refund #$id'); if (note != null) await _runAction(() => _api.rejectRefund(id, note: note), 'Refund rejected'); })]),
    ]));
  }

  Widget _registrationCard(Map<String, dynamic> row) => _card(child: _heading(_value(row, ['studentName', 'name'], fallback: 'Registration #${_value(row, ['id', 'registrationId'])}'), '${_value(row, ['email', 'studentEmail'])}  •  Reg. no: ${_value(row, ['registerNumber'])}', status: _status(row)));

  Widget _attendanceCard(Map<String, dynamic> row) {
    final registrationId = _int(row['id'] ?? row['registrationId']);
    final studentName = _value(row, ['studentName', 'name'], fallback: 'Registration #${registrationId ?? '—'}');
    final attendance = row['_attendance'] is Map ? Map<String, dynamic>.from(row['_attendance'] as Map) : null;
    final current = _value(attendance ?? {}, ['status'], fallback: 'NOT MARKED').toUpperCase();
    final eventId = _eventId;
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading(studentName, 'Registration ID: ${registrationId ?? '—'}  •  ${_value(row, ['registerNumber'])}', status: current),
      if (registrationId != null && eventId != null) _actions([
        _action('Present', Icons.check_circle, () => _runAction(() => _api.markAttendance(eventId, registrationId, 'PRESENT'), '$studentName marked present'), primary: true),
        _action('Absent', Icons.cancel, () => _runAction(() => _api.markAttendance(eventId, registrationId, 'ABSENT'), '$studentName marked absent')),
      ]),
    ]));
  }

  Widget _certificateCard(Map<String, dynamic> row) {
    final id = _int(row['certificateId'] ?? row['id']);
    final eventId = _eventId;
    if (row['_toIssue'] == true) {
      final studentId = _int(row['studentId']);
      final studentName = _value(row, ['studentName', 'name'], fallback: 'Student #${studentId ?? '—'}');
      return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading(studentName, 'Register no: ${_value(row, ['registerNumber'])}', status: 'NOT ISSUED'),
        if (studentId != null && eventId != null) _actions([_action('Issue certificate', Icons.workspace_premium, () => _confirmAction('Issue a certificate to $studentName?', () => _runAction(() => _api.issueCertificate(eventId, studentId), 'Certificate issued to $studentName')), primary: true)]),
      ]));
    }
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading(_value(row, ['studentName'], fallback: 'Certificate #${id ?? '—'}'), 'Certificate no: ${_value(row, ['certificateNumber'])}  •  Register no: ${_value(row, ['registerNumber'])}', status: 'ISSUED'),
      Text('Issued: ${_value(row, ['issuedAt'])}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
      if (_value(row, ['certificateUrl'], fallback: '').startsWith('http')) _actions([_action('View certificate URL', Icons.open_in_new, () => _showUrl(row['certificateUrl'].toString()))]),
    ]));
  }

  Future<void> _showUrl(String url) async {
    await showDialog<void>(context: context, builder: (context) => AlertDialog(backgroundColor: _surface,
      title: const Text('Certificate URL', style: TextStyle(color: Colors.white)),
      content: SelectableText(url, style: const TextStyle(color: Colors.white70)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }

  Future<void> _confirmAction(String message, Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(backgroundColor: _surface,
      title: const Text('Confirm action', style: TextStyle(color: Colors.white)), content: Text(message, style: const TextStyle(color: Colors.white70)),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm'))]));
    if (confirmed == true) await action();
  }
}
