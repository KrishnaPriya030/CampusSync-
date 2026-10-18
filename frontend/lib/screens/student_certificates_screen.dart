import 'package:flutter/material.dart';
import '../services/student_portal_service.dart';

class StudentCertificatesScreen extends StatefulWidget {
  const StudentCertificatesScreen({super.key});
  @override
  State<StudentCertificatesScreen> createState() => _StudentCertificatesScreenState();
}

class _StudentCertificatesScreenState extends State<StudentCertificatesScreen> {
  static const _bg = Color(0xFF060917);
  static const _surface = Color(0xFF11152D);
  static const _lavender = Color(0xFFC4B5FD);
  final _service = StudentPortalService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getMyCertificates();
      if (!mounted) return;
      setState(() { _items = result; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  String _v(Map<String, dynamic> m, List<String> keys, [String fallback = '—']) {
    for (final k in keys) { final v = m[k]; if (v != null && '$v'.trim().isNotEmpty) return '$v'; }
    return fallback;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(title: const Text('My Certificates'), backgroundColor: _bg, foregroundColor: Colors.white, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator(color: _lavender))
      : _error != null ? _errorWidget()
      : _items.isEmpty ? const Center(child: Text('No certificates issued yet.', style: TextStyle(color: Colors.white70)))
      : RefreshIndicator(color: _lavender, onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, i) {
        final item = _items[i];
        return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.workspace_premium_rounded, color: _lavender, size: 32), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_v(item, ['eventTitle'], 'Event certificate'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6), Text('Certificate: ${_v(item, ['certificateNumber'])}', style: const TextStyle(color: Colors.white70)),
            Text('Issued: ${_v(item, ['issuedAt'])}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if (_v(item, ['certificateUrl'], '').isNotEmpty) ...[const SizedBox(height: 8), SelectableText(_v(item, ['certificateUrl']), style: const TextStyle(color: _lavender, fontSize: 12))],
          ])),
        ]));
      })),
  );

  Widget _errorWidget() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 12), OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry'))])));
}
