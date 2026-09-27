class DepartmentHead {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String? phoneNumber;
  final int departmentId;
  final String departmentName;
  final String designation;
  final String accountStatus;
  final bool firstLogin;

  const DepartmentHead({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.departmentId,
    required this.departmentName,
    required this.designation,
    required this.accountStatus,
    required this.firstLogin,
  });

  factory DepartmentHead.fromJson(Map<String, dynamic> json) {
    return DepartmentHead(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      departmentId: (json['departmentId'] as num?)?.toInt() ?? 0,
      departmentName: json['departmentName']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      accountStatus: json['accountStatus']?.toString() ?? '',
      firstLogin: json['firstLogin'] == true,
    );
  }
}
