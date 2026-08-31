class UpdateStudentRequest {
  final String name;
  final String? phoneNumber;
  final String programme;
  final int admissionYear;
  final int departmentId;
  final int branchId;
  final int semester;
  final int graduationYear;
  final bool internal;

  UpdateStudentRequest({
    required this.name,
    this.phoneNumber,
    required this.programme,
    required this.admissionYear,
    required this.departmentId,
    required this.branchId,
    required this.semester,
    required this.graduationYear,
    required this.internal,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'programme': programme,
      'admissionYear': admissionYear,
      'departmentId': departmentId,
      'branchId': branchId,
      'semester': semester,
      'graduationYear': graduationYear,
      'internal': internal,
    };
  }
}