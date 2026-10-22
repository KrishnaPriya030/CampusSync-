
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _background = Color(0xFFF6F7FB);
  static const Color _primary = Color(0xFF6D45D8);
  static const Color _textColor = Color(0xFF262342);

  final NotificationService _service = NotificationService();

  List<Map<String, dynamic>> _items = [];

  bool _loading = true;
  bool _busy = false;
  String? _error;

  int? _id(Map<String, dynamic> item) {
    final value = item['id'] ?? item['notificationId'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  bool _read(Map<String, dynamic> item) {
    final value = item['isRead'] ??
        item['read'] ??
        item['readStatus'];

    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  String _value(
    Map<String, dynamic> item,
    String key, [
    String fallback = '—',
  ]) {
    final value = item[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.getMyNotifications();

      items.sort(
        (a, b) => _value(b, 'createdAt').compareTo(
          _value(a, 'createdAt'),
        ),
      );

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _service.markAsRead(id);
      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not mark notification as read: $e',
          ),
        ),
      );
    }
  }

  Future<void> _markAll() async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      await _service.markAllAsRead();
      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not mark all notifications as read: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((item) => !_read(item)).length;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: _textColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh notifications',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Unread: $unread',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _textColor,
                              ),
                            ),
                          ),
                          if (unread > 0)
                            TextButton(
                              onPressed: _busy ? null : _markAll,
                              child: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Mark all read'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: _EmptyNotifications(),
                        )
                      else
                        ..._items.map(_notificationCard),
                    ],
                  ),
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
              _error ?? 'Unable to load notifications.',
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

  Widget _notificationCard(Map<String, dynamic> item) {
    final read = _read(item);
    final notificationId = _id(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: read
              ? Colors.grey.shade100
              : const Color(0xFFEDE7FF),
          child: Icon(
            read
                ? Icons.notifications_none_rounded
                : Icons.notifications_active_rounded,
            color: read ? Colors.grey : _primary,
          ),
        ),
        title: Text(
          _value(item, 'title', 'Notification'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${_value(item, 'message', 'No message')}\n'
            '${_value(item, 'createdAt')}',
          ),
        ),
        isThreeLine: true,
        trailing: !read && notificationId != null
            ? IconButton(
                tooltip: 'Mark as read',
                onPressed: _markRead == null
                    ? null
                    : () => _markRead(notificationId),
                icon: const Icon(
                  Icons.done_rounded,
                  color: _primary,
                ),
              )
            : Text(
                read ? 'Read' : 'New',
                style: TextStyle(
                  fontSize: 11,
                  color: read ? Colors.grey : _primary,
                ),
              ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.notifications_none_rounded,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        const Text(
          'No notifications yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
