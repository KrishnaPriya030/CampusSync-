import 'package:flutter/material.dart';

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
  int _selectedFilter = 0;

  final List<_MockEvent> _events = [
    _MockEvent(
      id: 1,
      title: 'Campus Hackathon 2026',
      organizer: 'Tech Club',
      venue: 'Main Auditorium',
      date: '05 Oct 2026',
      time: '09:00 AM',
      scope: 'DEPARTMENT',
      paymentType: 'PAID',
      fee: '₹250',
      status: 'PENDING_APPROVAL',
      description:
          'A technical hackathon organized for students to build innovative solutions.',
    ),
    _MockEvent(
      id: 2,
      title: 'AI Workshop',
      organizer: 'AI Club',
      venue: 'Seminar Hall',
      date: '10 Oct 2026',
      time: '10:00 AM',
      scope: 'DEPARTMENT',
      paymentType: 'FREE',
      fee: '₹0',
      status: 'APPROVED',
      description:
          'Hands-on workshop covering artificial intelligence fundamentals.',
    ),
    _MockEvent(
      id: 3,
      title: 'Tech Fest 2026',
      organizer: 'MCA Association',
      venue: 'College Ground',
      date: '18 Oct 2026',
      time: '09:30 AM',
      scope: 'ORGANIZATION',
      paymentType: 'PAID',
      fee: '₹500',
      status: 'PUBLISHED',
      description:
          'Annual technology festival featuring competitions and technical events.',
    ),
    _MockEvent(
      id: 4,
      title: 'Python Programming Contest',
      organizer: 'Programming Club',
      venue: 'Computer Lab',
      date: '22 Oct 2026',
      time: '02:00 PM',
      scope: 'DEPARTMENT',
      paymentType: 'PAID',
      fee: '₹100',
      status: 'PENDING_APPROVAL',
      description:
          'Competitive programming contest focused on Python problem solving.',
    ),
  ];

  List<_MockEvent> get _visibleEvents {
    if (widget.role == HeadRole.departmentHead) {
      return _events
          .where((event) => event.scope == 'DEPARTMENT')
          .toList();
    }

    return _events
        .where((event) => event.scope == 'ORGANIZATION')
        .toList();
  }

  List<_MockEvent> get _filteredEvents {
    final events = _visibleEvents;

    switch (_selectedFilter) {
      case 1:
        return events
            .where((event) => event.status == 'PENDING_APPROVAL')
            .toList();

      case 2:
        return events
            .where((event) => event.status == 'APPROVED')
            .toList();

      case 3:
        return events
            .where((event) => event.status == 'PUBLISHED')
            .toList();

      default:
        return events;
    }
  }

  String get _roleTitle {
    return widget.role == HeadRole.departmentHead
        ? 'Department Events'
        : 'Organization Events';
  }

  String get _scopeDescription {
    return widget.role == HeadRole.departmentHead
        ? 'Events posted within your department'
        : 'Events posted within your organization';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: _filteredEvents.isEmpty
                  ? _buildEmptyState()
                  : _buildEventList(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _roleTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _scopeDescription,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    final filters = [
      'All',
      'Pending',
      'Approved',
      'Published',
    ];

    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;

          return ChoiceChip(
            label: Text(filters[index]),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = index;
              });
            },
            selectedColor: const Color(0xFF7C3AED),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: selected
                  ? Colors.transparent
                  : Colors.grey.shade200,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // EVENT LIST
  // ============================================================

  Widget _buildEventList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        if (isWide) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 520,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.25,
            ),
            itemCount: _filteredEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(_filteredEvents[index]);
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: _filteredEvents.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return _buildEventCard(_filteredEvents[index]);
          },
        );
      },
    );
  }

  // ============================================================
  // EVENT CARD
  // ============================================================

  Widget _buildEventCard(_MockEvent event) {
    final pending = event.status == 'PENDING_APPROVAL';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _showEventDetails(event),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusBadge(status: event.status),
              ],
            ),

            const SizedBox(height: 16),

            _EventInfoRow(
              icon: Icons.person_outline_rounded,
              text: event.organizer,
            ),

            _EventInfoRow(
              icon: Icons.location_on_outlined,
              text: event.venue,
            ),

            _EventInfoRow(
              icon: Icons.calendar_today_outlined,
              text: '${event.date} • ${event.time}',
            ),

            _EventInfoRow(
              icon: Icons.payments_outlined,
              text:
                  event.paymentType == 'PAID'
                      ? 'Paid • ${event.fee}'
                      : 'Free event',
            ),

            const Spacer(),

            if (pending)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _showApprovalDialog(event);
                  },
                  icon: const Icon(
                    Icons.rate_review_outlined,
                    size: 19,
                  ),
                  label: const Text('Review Approval'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _showEventDetails(event);
                  },
                  child: const Text('View Details'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EVENT DETAILS
  // ============================================================

  void _showEventDetails(_MockEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(22),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _StatusBadge(status: event.status),

                  const SizedBox(height: 22),

                  const Text(
                    'Event Details',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _DetailTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Organizer',
                    value: event.organizer,
                  ),

                  _DetailTile(
                    icon: Icons.location_on_outlined,
                    title: 'Venue',
                    value: event.venue,
                  ),

                  _DetailTile(
                    icon: Icons.calendar_month_outlined,
                    title: 'Date',
                    value: event.date,
                  ),

                  _DetailTile(
                    icon: Icons.schedule_outlined,
                    title: 'Time',
                    value: event.time,
                  ),

                  _DetailTile(
                    icon: Icons.category_outlined,
                    title: 'Scope',
                    value: event.scope,
                  ),

                  _DetailTile(
                    icon: Icons.payments_outlined,
                    title: 'Payment',
                    value:
                        event.paymentType == 'PAID'
                            ? event.fee
                            : 'Free',
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),

                  if (event.status == 'PENDING_APPROVAL') ...[
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showApprovalDialog(event);
                        },
                        icon: const Icon(
                          Icons.rate_review_outlined,
                        ),
                        label: const Text(
                          'Review Approval',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF7C3AED),
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // APPROVAL DIALOG
  // ============================================================

  void _showApprovalDialog(_MockEvent event) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Review Event',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Do you want to approve or reject "${event.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showRejectDialog(event);
              },
              child: const Text(
                'Reject',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _approveEvent(event);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // APPROVE
  // ============================================================

  void _approveEvent(_MockEvent event) {
    setState(() {
      event.status = 'APPROVED';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Event approved successfully.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // REJECT
  // ============================================================

  void _showRejectDialog(_MockEvent event) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reject Event',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter rejection reason',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reason = controller.text.trim();

                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Rejection reason is required.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                setState(() {
                  event.status = 'REJECTED';
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Event rejected.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 70,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No events found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no events matching this filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STATUS BADGE
// ============================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late Color background;
    late Color foreground;
    late String label;

    switch (status) {
      case 'PENDING_APPROVAL':
        background = Colors.orange.shade50;
        foreground = Colors.orange.shade800;
        label = 'Pending';
        break;

      case 'APPROVED':
        background = Colors.green.shade50;
        foreground = Colors.green.shade800;
        label = 'Approved';
        break;

      case 'PUBLISHED':
        background = Colors.blue.shade50;
        foreground = Colors.blue.shade800;
        label = 'Published';
        break;

      case 'REJECTED':
        background = Colors.red.shade50;
        foreground = Colors.red.shade800;
        label = 'Rejected';
        break;

      default:
        background = Colors.grey.shade100;
        foreground = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// EVENT INFO
// ============================================================

class _EventInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EventInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DETAIL TILE
// ============================================================

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF7C3AED),
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MOCK EVENT MODEL
// ============================================================

class _MockEvent {
  final int id;
  final String title;
  final String organizer;
  final String venue;
  final String date;
  final String time;
  final String scope;
  final String paymentType;
  final String fee;
  final String description;
  String status;

  _MockEvent({
    required this.id,
    required this.title,
    required this.organizer,
    required this.venue,
    required this.date,
    required this.time,
    required this.scope,
    required this.paymentType,
    required this.fee,
    required this.status,
    required this.description,
  });
}