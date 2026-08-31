class CreateStudentRequest {
  final String name;
  final String email;
  final String phoneNumber;
  final String registerNumber;
  final DateTime dateOfBirth;
  final int departmentId;
  final int branchId;
  final int semester;
  final String programme;
  final int admissionYear;
  final int graduationYear;

  const CreateStudentRequest({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.registerNumber,
    required this.dateOfBirth,
    required this.departmentId,
    required this.branchId,
    required this.semester,
    required this.programme,
    required this.admissionYear,
    required this.graduationYear,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'registerNumber': registerNumber,
      'dateOfBirth':
          dateOfBirth.toIso8601String().split('T').first,
      'departmentId': departmentId,
      'branchId': branchId,
      'semester': semester,
      'programme': programme,
      'admissionYear': admissionYear,
      'graduationYear': graduationYear,
    };
  }
}