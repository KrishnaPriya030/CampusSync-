import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'login_screen.dart';

enum HeadRole {
  departmentHead,
  organizationHead,
}

class HeadEventManagementScreen extends StatefulWidget {
  final HeadRole role;

  const HeadEventManagementScreen({
    super.key,
    required this.role,
  });

  @override
  State<HeadEventManagementScreen> createState() =>
      _HeadEventManagementScreenState();
}

class _HeadEventManagementScreenState
    extends State<HeadEventManagementScreen> {
  static const String _baseUrl =
      'http://127.0.0.1:8080';

  final TokenStorage _tokenStorage = TokenStorage();

  List<_EventItem> _events = [];

  bool _loading = true;
  String? _errorMessage;

  int _selectedFilter = 0;

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // ---------------------------------------------------------------------------
  // LOAD EVENTS
  // ---------------------------------------------------------------------------

  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found.',
        );
      }

      // The Department Head backend determines the department
      // from the authenticated user. No department ID is sent.
      final String endpoint;

      if (widget.role == HeadRole.departmentHead) {
  endpoint = '/api/department-head/events';
} else {
  endpoint = '/api/organization-head/events';
}
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers(token),
      );

      _throwForBadResponse(response);

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Invalid event data received from server.',
        );
      }

      final events = decoded
          .map(
            (item) => _EventItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD PENDING EVENTS
  // ---------------------------------------------------------------------------
  //
  // This is kept as a separate method because your backend explicitly
  // exposes /events/pending.
  //
  // The normal Events screen still loads all department events.
  // The "Pending" filter uses this backend endpoint so approval data
  // comes directly from the server.
  // ---------------------------------------------------------------------------

  Future<void> _loadPendingEvents() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found.',
        );
      }

      final String endpoint =
          widget.role == HeadRole.departmentHead
              ? '/api/department-head/events/pending'
              : '/api/organization-head/events/pending';

      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers(token),
      );

      _throwForBadResponse(response);

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Invalid pending event data received from server.',
        );
      }

      final events = decoded
          .map(
            (item) => _EventItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // APPROVE EVENT
  // ---------------------------------------------------------------------------

  Future<void> _approveEvent(_EventItem event) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Approve Event?',
      message:
          'Are you sure you want to approve "${event.title}"?',
      confirmText: 'Approve',
    );

    if (confirmed != true) {
      return;
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found.',
        );
      }

      final String endpoint =
          widget.role == HeadRole.departmentHead
              ? '/api/department-head/events/${event.id}/approve'
              : '/api/organization-head/events/${event.id}/approve';

      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers(token),
      );

      _throwForBadResponse(response);

      _showMessage(
        'Event approved successfully.',
      );

      await _loadEvents();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        error: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // REJECT EVENT
  // ---------------------------------------------------------------------------

  Future<void> _rejectEvent(_EventItem event) async {
    final reasonController =
        TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF111827),
          surfaceTintColor:
              Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Reject Event',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Provide a reason for rejecting "${event.title}".',
                style: TextStyle(
                  color:
                      Colors.white.withOpacity(0.65),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 4,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration:
                    InputDecoration(
                  hintText:
                      'Enter rejection reason',
                  hintStyle: TextStyle(
                    color: Colors.white
                        .withOpacity(0.35),
                  ),
                  filled: true,
                  fillColor:
                      Colors.white.withOpacity(
                    0.05,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    reasonController.text.trim();

                if (value.isEmpty) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Rejection reason is required.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: const Text(
                'Reject Event',
              ),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null ||
        reason.trim().isEmpty) {
      return;
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found.',
        );
      }

      final String endpoint =
          widget.role == HeadRole.departmentHead
              ? '/api/department-head/events/${event.id}/reject'
              : '/api/organization-head/events/${event.id}/reject';

      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers(token),
        body: jsonEncode({
          'reason': reason.trim(),
        }),
      );

      _throwForBadResponse(response);

      _showMessage(
        'Event rejected successfully.',
      );

      await _loadEvents();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        error: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // FILTER
  // ---------------------------------------------------------------------------

  List<_EventItem> get _filteredEvents {
    switch (_selectedFilter) {
      case 1:
        return _events
            .where(
              (event) =>
                  event.status ==
                  'PENDING_APPROVAL',
            )
            .toList();

      case 2:
        return _events
            .where(
              (event) =>
                  event.status == 'APPROVED',
            )
            .toList();

      case 3:
        return _events
            .where(
              (event) =>
                  event.status == 'PUBLISHED',
            )
            .toList();

      case 4:
        return _events
            .where(
              (event) =>
                  event.status == 'REJECTED',
            )
            .toList();

      default:
        return _events;
    }
  }

  // ---------------------------------------------------------------------------
  // REFRESH
  // ---------------------------------------------------------------------------

  Future<void> _refresh() async {
    if (_selectedFilter == 1) {
      await _loadPendingEvents();
    } else {
      await _loadEvents();
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;

    return Scaffold(
      backgroundColor:
          const Color(0xFF070B1C),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF8B5CF6),
          onRefresh: _refresh,
          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverToBoxAdapter(
                child: _buildFilters(),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(
                  height: 10,
                ),
              ),
              if (_loading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildLoadingState(),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(),
                )
              else if (events.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    30,
                  ),
                  sliver: SliverList(
                    delegate:
                        SliverChildBuilderDelegate(
                      (context, index) {
                        final event =
                            events[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child:
                              _buildEventCard(
                            event,
                          ),
                        );
                      },
                      childCount:
                          events.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    final bool isDepartmentHead =
        widget.role ==
            HeadRole.departmentHead;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDepartmentHead
                          ? 'Department Events'
                          : 'Organization Events',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDepartmentHead
                          ? 'Review and manage events for your department'
                          : 'Event management',
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed:
                    _loading ? null : _refresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _summaryItem(
                icon: Icons.event_note_rounded,
                label: 'Total',
                value: _events.length
                    .toString(),
              ),
              const SizedBox(width: 10),
              _summaryItem(
                icon: Icons.pending_actions_rounded,
                label: 'Pending',
                value: _events
                    .where(
                      (event) =>
                          event.status ==
                          'PENDING_APPROVAL',
                    )
                    .length
                    .toString(),
              ),
              const SizedBox(width: 10),
              _summaryItem(
                icon: Icons.check_circle_outline_rounded,
                label: 'Approved',
                value: _events
                    .where(
                      (event) =>
                          event.status ==
                          'APPROVED',
                    )
                    .length
                    .toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color:
              Colors.white.withOpacity(0.045),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color:
                Colors.white.withOpacity(0.07),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color:
                  const Color(0xFFA78BFA),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(0.45),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTERS
  // ---------------------------------------------------------------------------

  Widget _buildFilters() {
    final filters = [
      'All',
      'Pending',
      'Approved',
      'Published',
      'Rejected',
    ];

    final icons = [
      Icons.grid_view_rounded,
      Icons.pending_actions_rounded,
      Icons.check_circle_outline_rounded,
      Icons.public_rounded,
      Icons.cancel_outlined,
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                setState(() {
                  _selectedFilter = index;
                });

                if (index == 1) {
                  await _loadPendingEvents();
                } else if (index == 0) {
                  await _loadEvents();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF11162B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF8B5CF6)
                        : Colors.white.withOpacity(0.09),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7C3AED)
                                .withOpacity(0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 16,
                      color: selected
                          ? Colors.white
                          : const Color(0xFFA78BFA),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      filters[index],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.78),
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EVENT CARD
  // ---------------------------------------------------------------------------

  Widget _buildEventCard(
    _EventItem event,
  ) {
    final bool pending =
        event.status ==
            'PENDING_APPROVAL';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11162B),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.065),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.20),
            blurRadius: 25,
            offset:
                const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF7C3AED),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color:
                        Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        event.organizerName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(
                            0.55,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(
                  event.status,
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (event.description
                .trim()
                .isNotEmpty)
              Text(
                event.description,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white
                      .withOpacity(0.62),
                  height: 1.45,
                  fontSize: 12,
                ),
              ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _infoPill(
                  Icons.location_on_outlined,
                  event.venue,
                ),
                _infoPill(
                  Icons.calendar_month_outlined,
                  _formatDateTime(
                    event.startDateTime,
                  ),
                ),
                _infoPill(
                  Icons.people_outline_rounded,
                  event.capacity == null
                      ? 'No capacity'
                      : '${event.capacity}',
                ),
                _infoPill(
                  Icons.payments_outlined,
                  _paymentText(event),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed: () {
                      _showEventDetails(
                        event,
                      );
                    },
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 17,
                    ),
                    label:
                        const Text(
                      'Details',
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          Colors.white,
                      side: BorderSide(
                        color: Colors.white
                            .withOpacity(
                          0.10,
                        ),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                if (pending) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () =>
                              _approveEvent(
                        event,
                      ),
                      icon:
                          const Icon(
                        Icons
                            .check_rounded,
                        size: 17,
                      ),
                      label:
                          const Text(
                        'Approve',
                      ),
                      style: ElevatedButton
                          .styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF16A34A,
                        ),
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            13,
                          ),
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed:
                        () =>
                            _rejectEvent(
                      event,
                    ),
                    tooltip:
                        'Reject',
                    style:
                        IconButton.styleFrom(
                      backgroundColor:
                          Colors.redAccent
                              .withOpacity(
                        0.10,
                      ),
                      foregroundColor:
                          Colors.redAccent,
                    ),
                    icon:
                        const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.035),
        borderRadius:
            BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                const Color(0xFFA78BFA),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.60),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    Color color;

    switch (status) {
      case 'PENDING_APPROVAL':
        color =
            const Color(0xFFF59E0B);
        break;
      case 'APPROVED':
        color =
            const Color(0xFF22C55E);
        break;
      case 'PUBLISHED':
        color =
            const Color(0xFF3B82F6);
        break;
      case 'REJECTED':
        color =
            const Color(0xFFEF4444);
        break;
      default:
        color =
            const Color(0xFF9CA3AF);
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Text(
        _prettyStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EVENT DETAILS
  // ---------------------------------------------------------------------------

  void _showEventDetails(
    _EventItem event,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor:
              const Color(0xFF111827),
          insetPadding:
              const EdgeInsets.all(20),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 650,
            ),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 21,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                      _statusBadge(
                        event.status,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  _detailRow(
                    'Organizer',
                    event.organizerName,
                  ),
                  _detailRow(
                    'Organization',
                    event.organizationName,
                  ),
                  _detailRow(
                    'Venue',
                    event.venue,
                  ),
                  _detailRow(
                    'Scope',
                    event.scope,
                  ),
                  _detailRow(
                    'Start',
                    _formatDateTime(
                      event.startDateTime,
                    ),
                  ),
                  _detailRow(
                    'End',
                    _formatDateTime(
                      event.endDateTime,
                    ),
                  ),
                  _detailRow(
                    'Registration Deadline',
                    _formatDateTime(
                      event.registrationDeadline,
                    ),
                  ),
                  _detailRow(
                    'Capacity Type',
                    event.capacityType,
                  ),
                  _detailRow(
                    'Capacity',
                    event.capacity
                        ?.toString() ??
                        'Not specified',
                  ),
                  _detailRow(
                    'Payment Type',
                    event.paymentType,
                  ),
                  _detailRow(
                    'Registration Fee',
                    event.registrationFee ==
                            null
                        ? '₹0'
                        : '₹${event.registrationFee!.toStringAsFixed(2)}',
                  ),
                  _detailRow(
                    'Refund Policy',
                    event.refundPolicy
                            .trim()
                            .isEmpty
                        ? 'Not specified'
                        : event.refundPolicy,
                  ),
                  _detailRow(
                    'Attendance',
                    event.attendanceEnabled
                        ? 'Enabled'
                        : 'Disabled',
                  ),
                  _detailRow(
                    'Certificate',
                    event.certificateEnabled
                        ? 'Enabled'
                        : 'Disabled',
                  ),

                  if (event.description
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      'Description',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Text(
                      event.description,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(
                          0.65,
                        ),
                        height: 1.5,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 20,
                  ),

                  if (event.status ==
                      'PENDING_APPROVAL')
                    Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                              _rejectEvent(
                                event,
                              );
                            },
                            style:
                                OutlinedButton
                                    .styleFrom(
                              foregroundColor:
                                  Colors
                                      .redAccent,
                              side:
                                  const BorderSide(
                                color:
                                    Colors.redAccent,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  13,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'Reject',
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child:
                              ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                              _approveEvent(
                                event,
                              );
                            },
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF16A34A,
                              ),
                              foregroundColor:
                                  Colors
                                      .white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  13,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'Approve',
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Align(
                      alignment:
                          Alignment.centerRight,
                      child:
                          TextButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                        child:
                            const Text(
                          'Close',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white
                    .withOpacity(0.45),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF8B5CF6),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(
                color:
                    Colors.redAccent
                        .withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color:
                    Colors.redAccent,
                size: 30,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'Unable to load events',
              style:
                  TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white
                    .withOpacity(0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            ElevatedButton.icon(
              onPressed:
                  _refresh,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
                  const Text('Retry'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF7C3AED,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    String title;
    String message;

    switch (_selectedFilter) {
      case 1:
        title = 'No pending approvals';
        message =
            'There are no events waiting for your approval.';
        break;
      case 2:
        title = 'No approved events';
        message =
            'No approved events are available.';
        break;
      case 3:
        title = 'No published events';
        message =
            'No published events are available.';
        break;
      case 4:
        title = 'No rejected events';
        message =
            'No rejected events are available.';
        break;
      default:
        title = 'No events found';
        message = widget.role == HeadRole.departmentHead
            ? 'No events are currently available for your department.'
            : 'No events are currently available for your organization.';
    }

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration:
                  BoxDecoration(
                color: const Color(
                  0xFF8B5CF6,
                ).withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color:
                    Color(0xFFA78BFA),
                size: 34,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              title,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white
                    .withOpacity(0.52),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Map<String, String> _headers(
    String token,
  ) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  void _throwForBadResponse(
    http.Response response,
  ) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    String message =
        'Request failed (${response.statusCode}).';

    try {
      final body =
          jsonDecode(response.body);

      if (body is Map) {
        final possibleMessage =
            body['message'] ??
                body['error'] ??
                body['detail'];

        if (possibleMessage != null &&
            possibleMessage
                .toString()
                .trim()
                .isNotEmpty) {
          message =
              possibleMessage.toString();
        }
      }
    } catch (_) {
      // Keep generic HTTP error.
    }

    throw Exception(message);
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF111827),
          surfaceTintColor:
              Colors.transparent,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.65),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF16A34A,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: Text(
                confirmText,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(
                  0xFFB91C1C,
                )
              : const Color(
                  0xFF166534,
                ),
        ),
      );
  }

  String _prettyStatus(
    String status,
  ) {
    return status
        .replaceAll(
          '_',
          ' ',
        )
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}'
                  '${word.substring(1)}',
        )
        .join(' ');
  }

  String _paymentText(
    _EventItem event,
  ) {
    if (event.paymentType
        .toUpperCase()
        .contains('FREE')) {
      return 'Free';
    }

    if (event.registrationFee !=
        null) {
      return '₹${event.registrationFee!.toStringAsFixed(2)}';
    }

    return event.paymentType;
  }

  String _formatDateTime(
    DateTime? dateTime,
  ) {
    if (dateTime == null) {
      return 'Not specified';
    }

    final day =
        dateTime.day
            .toString()
            .padLeft(2, '0');

    final month =
        dateTime.month
            .toString()
            .padLeft(2, '0');

    final year =
        dateTime.year.toString();

    final hour =
        dateTime.hour % 12 == 0
            ? 12
            : dateTime.hour % 12;

    final minute =
        dateTime.minute
            .toString()
            .padLeft(2, '0');

    final period =
        dateTime.hour >= 12
            ? 'PM'
            : 'AM';

    return '$day/$month/$year  '
        '$hour:$minute $period';
  }
}

// ============================================================================
// EVENT MODEL
// ============================================================================

class _EventItem {
  final int id;
  final int organizerId;
  final String organizerName;
  final int organizationId;
  final String organizationName;
  final String title;
  final String description;
  final String venue;

  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final DateTime? registrationDeadline;

  final String scope;
  final String capacityType;
  final int? capacity;

  final String paymentType;
  final double? registrationFee;

  final String refundPolicy;

  final bool attendanceEnabled;
  final bool certificateEnabled;

  final String status;

  const _EventItem({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.organizationId,
    required this.organizationName,
    required this.title,
    required this.description,
    required this.venue,
    required this.startDateTime,
    required this.endDateTime,
    required this.registrationDeadline,
    required this.scope,
    required this.capacityType,
    required this.capacity,
    required this.paymentType,
    required this.registrationFee,
    required this.refundPolicy,
    required this.attendanceEnabled,
    required this.certificateEnabled,
    required this.status,
  });

  factory _EventItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return _EventItem(
      id: _toInt(
        json['id'],
      ),
      organizerId: _toInt(
        json['organizerId'],
      ),
      organizerName:
          _toString(
        json['organizerName'],
      ),
      organizationId:
          _toInt(
        json['organizationId'],
      ),
      organizationName:
          _toString(
        json['organizationName'],
      ),
      title:
          _toString(
        json['title'],
      ),
      description:
          _toString(
        json['description'],
      ),
      venue:
          _toString(
        json['venue'],
      ),
      startDateTime:
          _toDateTime(
        json['startDateTime'],
      ),
      endDateTime:
          _toDateTime(
        json['endDateTime'],
      ),
      registrationDeadline:
          _toDateTime(
        json['registrationDeadline'],
      ),
      scope:
          _toString(
        json['scope'],
      ),
      capacityType:
          _toString(
        json['capacityType'],
      ),
      capacity:
          json['capacity'] == null
              ? null
              : _toInt(
                  json['capacity'],
                ),
      paymentType:
          _toString(
        json['paymentType'],
      ),
      registrationFee:
          _toDouble(
        json['registrationFee'],
      ),
      refundPolicy:
          _toString(
        json['refundPolicy'],
      ),
      attendanceEnabled:
          json['attendanceEnabled'] ==
              true,
      certificateEnabled:
          json['certificateEnabled'] ==
              true,
      status:
          _toString(
        json['status'],
      ).toUpperCase(),
    );
  }

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static String _toString(
    dynamic value,
  ) {
    return value?.toString() ?? '';
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      text,
    );
  }
}