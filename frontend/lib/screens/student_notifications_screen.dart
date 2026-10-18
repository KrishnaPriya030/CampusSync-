import 'package:flutter/material.dart';
import '../services/student_portal_service.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});
  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  static const _bg = Color(0xFF060917);
  static const _surface = Color(0xFF11152D);
  static const _lavender = Color(0xFFC4B5FD);
  final _api = StudentPortalService();
  bool _loading = true;
  String? _error;
  int _unread = 0;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final values = await _api.getNotifications();
      final unread = await _api.getUnreadCount();
      if (!mounted) return;
      setState(() { _items = values; _unread = unread; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  int? _id(Map<String, dynamic> m) { final v = m['id'] ?? m['notificationId']; return v is num ? v.toInt() : int.tryParse('$v'); }
  String _v(Map<String, dynamic> m, String key, [String fallback = '']) => m[key]?.toString() ?? fallback;
  bool _read(Map<String, dynamic> m) => m['read'] == true || m['isRead'] == true;

  Future<void> _markRead(int id) async {
    try { await _api.markNotificationRead(id); await _load(); }
    catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  Future<void> _markAll() async {
    try { await _api.markAllNotificationsRead(); await _load(); }
    catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(title: const Text('Notifications'), backgroundColor: _bg, foregroundColor: Colors.white, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator(color: _lavender))
      : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 12), OutlinedButton(onPressed: _load, child: const Text('Retry'))])))
      : Column(children: [Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [Expanded(child: Text('Unread: $_unread', style: const TextStyle(color: _lavender, fontWeight: FontWeight.w700))), if (_unread > 0) TextButton(onPressed: _markAll, child: const Text('Mark all read'))])), Expanded(child: _items.isEmpty ? const Center(child: Text('No notifications.', style: TextStyle(color: Colors.white70))) : RefreshIndicator(color: _lavender, onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, i) {
        final item = _items[i]; final read = _read(item); final id = _id(item);
        return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(_v(item, 'title', 'Notification'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), Text(read ? 'READ' : 'UNREAD', style: TextStyle(color: read ? Colors.white54 : _lavender, fontSize: 11, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 6), Text(_v(item, 'message', 'No message'), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6), Text(_v(item, 'createdAt'), style: const TextStyle(color: Colors.white38, fontSize: 11)),
          if (!read && id != null) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _markRead(id), child: const Text('Mark as read'))),
        ]));
      })))]),
  );
}
