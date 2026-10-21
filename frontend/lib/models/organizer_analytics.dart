
class EventAnalytics {
  final int eventId;
  final String eventTitle;
  final int totalParticipants;
  final double grossRevenue;
  final double completedRefunds;
  final double netRevenue;

  const EventAnalytics({
    required this.eventId,
    required this.eventTitle,
    required this.totalParticipants,
    required this.grossRevenue,
    required this.completedRefunds,
    required this.netRevenue,
  });

  factory EventAnalytics.fromJson(Map<String, dynamic> json) {
    return EventAnalytics(
      eventId: (json['eventId'] as num).toInt(),
      eventTitle: json['eventTitle'] as String? ?? 'Untitled event',
      totalParticipants:
          (json['totalParticipants'] as num?)?.toInt() ?? 0,
      grossRevenue:
          (json['grossRevenue'] as num?)?.toDouble() ?? 0.0,
      completedRefunds:
          (json['completedRefunds'] as num?)?.toDouble() ?? 0.0,
      netRevenue:
          (json['netRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrganizerAnalytics {
  final int totalEvents;
  final int totalParticipants;
  final double grossRevenue;
  final double completedRefunds;
  final double netRevenue;
  final List<EventAnalytics> events;

  const OrganizerAnalytics({
    required this.totalEvents,
    required this.totalParticipants,
    required this.grossRevenue,
    required this.completedRefunds,
    required this.netRevenue,
    required this.events,
  });

  factory OrganizerAnalytics.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as List<dynamic>? ?? [];

    return OrganizerAnalytics(
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
      totalParticipants:
          (json['totalParticipants'] as num?)?.toInt() ?? 0,
      grossRevenue:
          (json['grossRevenue'] as num?)?.toDouble() ?? 0.0,
      completedRefunds:
          (json['completedRefunds'] as num?)?.toDouble() ?? 0.0,
      netRevenue:
          (json['netRevenue'] as num?)?.toDouble() ?? 0.0,
      events: rawEvents
          .map(
            (item) => EventAnalytics.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
