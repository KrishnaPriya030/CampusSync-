import 'package:flutter/material.dart';
import '../models/registration.dart';
import '../services/student_registration_service.dart';
import '../services/student_portal_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  static const _bg = Color(0xFF060917);
  static const _surface = Color(0xFF11152D);
  static const _lavender = Color(0xFFC4B5FD);
  final _registrationsApi = StudentRegistrationService();
  final _portalApi = StudentPortalService();
  bool _loading = true;
  String? _error;
  List<({Registration registration, Map<String, dynamic>? attendance})> _rows = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final registrations = await _registrationsApi.getMyRegistrations();
      final rows = <({Registration registration, Map<String, dynamic>? attendance})>[];
      for (final registration in registrations) {
        Map<String, dynamic>? attendance;
        try { attendance = await _portalApi.getMyAttendance(registration.registrationId); } catch (_) { attendance = null; }
        rows.add((registration: registration, attendance: attendance));
      }
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  String _value(Map<String, dynamic>? m, String key, [String fallback = 'Not recorded']) => m == null || m[key] == null ? fallback : '${m[key]}';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(title: const Text('My Attendance'), backgroundColor: _bg, foregroundColor: Colors.white, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator(color: _lavender))
      : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center)))
      : _rows.isEmpty ? const Center(child: Text('You have no registrations yet.', style: TextStyle(color: Colors.white70)))
      : RefreshIndicator(color: _lavender, onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _rows.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, i) {
        final row = _rows[i]; final a = row.attendance;
        final status = _value(a, 'status').toUpperCase();
        return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Event #${row.registration.eventId}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8), Text('Registration: ${row.registration.registrationId}', style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 6), Row(children: [const Text('Attendance: ', style: TextStyle(color: Colors.white70)), Expanded(child: Text(status, style: TextStyle(color: status == 'PRESENT' ? Colors.greenAccent : _lavender, fontWeight: FontWeight.w700))) ]),
          Text('Marked at: ${_value(a, 'markedAt')}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]));
      })),
  );
}
