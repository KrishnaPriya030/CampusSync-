import 'package:flutter/material.dart';

import '../services/organizer_notification_service.dart';

class OrganizerNotificationsScreen extends StatefulWidget {
  const OrganizerNotificationsScreen({super.key});

  @override
  State<OrganizerNotificationsScreen> createState() =>
      _OrganizerNotificationsScreenState();
}

class _OrganizerNotificationsScreenState
    extends State<OrganizerNotificationsScreen> {
  static const Color _background = Color(0xFF060917);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _lavender = Color(0xFFB8A4FF);
  static const Color _card = Color(0xFF171C36);

  final OrganizerNotificationService _service = OrganizerNotificationService();
  List<OrganizerNotification> _notifications = [];
  bool _loading = true;
  bool _markingAll = false;
  String? _error;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getNotifications();
      items.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      if (!mounted) return;
      setState(() {
        _notifications = items;
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

  Future<void> _markRead(OrganizerNotification notification) async {
    if (notification.isRead) return;
    try {
      await _service.markAsRead(notification.id);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((item) {
          if (item.id != notification.id) return item;
          return OrganizerNotification(
            id: item.id,
            title: item.title,
            message: item.message,
            type: item.type,
            isRead: true,
            createdAt: item.createdAt,
            eventTitle: item.eventTitle,
          );
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0 || _markingAll) return;
    setState(() => _markingAll = true);
    try {
      await _service.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((item) => OrganizerNotification(
          id: item.id,
          title: item.title,
          message: item.message,
          type: item.type,
          isRead: true,
          createdAt: item.createdAt,
          eventTitle: item.eventTitle,
        )).toList();
        _markingAll = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _markingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
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
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh notifications',
            onPressed: _loading ? null : _loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_background, Color(0xFF0B1430), Color(0xFF171033)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: _purple,
            onRefresh: _loadNotifications,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _summaryCard(),
                const SizedBox(height: 14),
                if (_unreadCount > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _markingAll ? null : _markAllRead,
                      icon: _markingAll
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.done_all_rounded),
                      label: const Text('Mark all as read'),
                      style: TextButton.styleFrom(foregroundColor: _lavender),
                    ),
                  ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: _lavender),
                    ),
                  )
                else if (_error != null)
                  _stateCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load notifications',
                    message: _error!,
                    action: ElevatedButton.icon(
                      onPressed: _loadNotifications,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  )
                else if (_notifications.isEmpty)
                  _stateCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'You are all caught up',
                    message: 'Notifications for your account will appear here.',
                  )
                else
                  ..._notifications.map(_notificationCard),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF29215D), Color(0xFF50339A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your updates',
                    style: TextStyle(color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  _loading ? 'Loading your notifications…'
                      : '$_unreadCount unread of ${_notifications.length} notifications',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(OrganizerNotification item) {
    final icon = _iconForType(item.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _markRead(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.isRead ? _card.withOpacity(0.72) : const Color(0xFF242442),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item.isRead ? Colors.white10 : _lavender.withOpacity(0.48),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: _lavender),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(item.title,
                              style: const TextStyle(color: Colors.white,
                                fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5, left: 6),
                              decoration: const BoxDecoration(
                                color: _lavender, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item.message,
                        style: const TextStyle(color: Colors.white70,
                          fontSize: 12, height: 1.5)),
                      if (item.eventTitle != null && item.eventTitle!.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text('Event: ${item.eventTitle}',
                          style: const TextStyle(color: _lavender,
                            fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: Text(_formatDate(item.createdAt),
                              style: const TextStyle(color: Colors.white38,
                                fontSize: 10)),
                          ),
                          if (!item.isRead)
                            const Text('Tap to mark read',
                              style: TextStyle(color: _lavender, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _lavender, size: 34),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60,
              fontSize: 12, height: 1.5)),
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'NEW_EVENT': return Icons.event_available_rounded;
      case 'REGISTRATION_CONFIRMED': return Icons.how_to_reg_rounded;
      case 'EVENT_REMINDER': return Icons.alarm_rounded;
      case 'EVENT_UPDATED': return Icons.edit_calendar_rounded;
      case 'EVENT_CANCELLED': return Icons.event_busy_rounded;
      case 'PAYMENT_SUCCESS': return Icons.payments_rounded;
      case 'PAYMENT_FAILED': return Icons.money_off_rounded;
      case 'REFUND_PROCESSED': return Icons.currency_exchange_rounded;
      case 'CERTIFICATE_ISSUED': return Icons.workspace_premium_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} · '
        '$hour:$minute $period';
  }
}
