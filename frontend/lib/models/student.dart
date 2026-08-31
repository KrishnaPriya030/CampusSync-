class Student {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
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
  final String accountStatus;

  Student({
    required this.id,
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
    required this.accountStatus,
  });

  factory Student.fromJson(
    Map<String, dynamic> json,
  ) {
    return Student(
      id: (json['id'] as num?)?.toInt() ?? 0,

      name: json['name']?.toString() ?? '',

      email: json['email']?.toString() ?? '',

      phoneNumber:
          json['phoneNumber']?.toString(),

      registerNumber:
          json['registerNumber']?.toString() ?? '',

      departmentId:
          (json['departmentId'] as num?)?.toInt() ?? 0,

      departmentName:
          json['departmentName']?.toString() ?? '',

      branchId:
          (json['branchId'] as num?)?.toInt() ?? 0,

      branchName:
          json['branchName']?.toString() ?? '',

      programme:
          json['programme']?.toString() ?? '',

      admissionYear:
          (json['admissionYear'] as num?)?.toInt() ?? 0,

      semester:
          (json['semester'] as num?)?.toInt() ?? 0,

      graduationYear:
          (json['graduationYear'] as num?)?.toInt() ?? 0,

      internal:
          json['internal'] == true,

      status:
          json['status']?.toString() ?? '',

      accountStatus:
          json['accountStatus']?.toString() ?? '',
    );
  }
}