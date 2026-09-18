class Registration {
  final int registrationId;
  final int eventId;
  final int studentId;

  final String name;
  final String email;
  final String phoneNumber;
  final String registerNumber;

  final int departmentId;
  final String departmentName;

  final int branchId;
  final String branchName;

  final String programme;
  final int admissionYear;
  final int semester;
  final int graduationYear;

  final bool internal;

  final String status;
  final DateTime registeredAt;

  Registration({
    required this.registrationId,
    required this.eventId,
    required this.studentId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.registerNumber,
    required this.departmentId,
    required this.departmentName,
    required this.branchId,
    required this.branchName,
    required this.programme,
    required this.admissionYear,
    required this.semester,
    required this.graduationYear,
    required this.internal,
    required this.status,
    required this.registeredAt,
  });

  factory Registration.fromJson(
    Map<String, dynamic> json,
  ) {
    return Registration(
      registrationId:
          (json['registrationId'] as num).toInt(),

      eventId:
          (json['eventId'] as num).toInt(),

      studentId:
          (json['studentId'] as num).toInt(),

      name:
          json['name']?.toString() ?? '',

      email:
          json['email']?.toString() ?? '',

      phoneNumber:
          json['phoneNumber']?.toString() ?? '',

      registerNumber:
          json['registerNumber']?.toString() ?? '',

      departmentId:
          (json['departmentId'] as num).toInt(),

      departmentName:
          json['departmentName']?.toString() ?? '',

      branchId:
          (json['branchId'] as num).toInt(),

      branchName:
          json['branchName']?.toString() ?? '',

      programme:
          json['programme']?.toString() ?? '',

      admissionYear:
          (json['admissionYear'] as num).toInt(),

      semester:
          (json['semester'] as num).toInt(),

      graduationYear:
          (json['graduationYear'] as num).toInt(),

      internal:
          json['internal'] == true,

      status:
          json['status']?.toString() ?? '',

      registeredAt:
          DateTime.parse(
        json['registeredAt'].toString(),
      ),
    );
  }
}