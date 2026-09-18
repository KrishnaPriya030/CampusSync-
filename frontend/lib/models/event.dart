class Event {
  final int id;
  final int organizerId;
  final String organizerName;
  final int organizationId;
  final String organizationName;
  final String title;
  final String description;
  final String venue;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final DateTime registrationDeadline;
  final String capacityType;
  final int? capacity;
  final String paymentType;
  final double registrationFee;
  final String? refundPolicy;
  final bool attendanceEnabled;
  final bool certificateEnabled;
  final String status;

  Event({
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
    required this.capacityType,
    this.capacity,
    required this.paymentType,
    required this.registrationFee,
    this.refundPolicy,
    required this.attendanceEnabled,
    required this.certificateEnabled,
    required this.status,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: (json['id'] as num).toInt(),
      organizerId: (json['organizerId'] as num).toInt(),
      organizerName: json['organizerName']?.toString() ?? '',
      organizationId: (json['organizationId'] as num).toInt(),
      organizationName: json['organizationName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      startDateTime: DateTime.parse(
        json['startDateTime'].toString(),
      ),
      endDateTime: DateTime.parse(
        json['endDateTime'].toString(),
      ),
      registrationDeadline: DateTime.parse(
        json['registrationDeadline'].toString(),
      ),
      capacityType: json['capacityType']?.toString() ?? '',
      capacity: json['capacity'] == null
          ? null
          : (json['capacity'] as num).toInt(),
      paymentType: json['paymentType']?.toString() ?? '',
      registrationFee: json['registrationFee'] == null
          ? 0.0
          : (json['registrationFee'] as num).toDouble(),
      refundPolicy: json['refundPolicy']?.toString(),
      attendanceEnabled:
          json['attendanceEnabled'] == true,
      certificateEnabled:
          json['certificateEnabled'] == true,
      status: json['status']?.toString() ?? '',
    );
  }
}