class Student {
  final int id;
  final String name;
  final String email;
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

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      registerNumber: json['registerNumber'],
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
      branchId: json['branchId'],
      branchName: json['branchName'],
      programme: json['programme'],
      admissionYear: json['admissionYear'],
      semester: json['semester'],
      graduationYear: json['graduationYear'],
      internal: json['internal'] ?? false,
      status: json['status'] ?? '',
      accountStatus: json['accountStatus'] ?? '',
    );
  }
} 