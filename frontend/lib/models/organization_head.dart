class OrganizationHead {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String? phoneNumber;
  final int organizationId;
  final String organizationName;
  final String designation;
  final String accountStatus;
  final bool firstLogin;

  const OrganizationHead({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.organizationId,
    required this.organizationName,
    required this.designation,
    required this.accountStatus,
    required this.firstLogin,
  });

  factory OrganizationHead.fromJson(Map<String, dynamic> json) {
    return OrganizationHead(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      organizationId: (json['organizationId'] as num?)?.toInt() ?? 0,
      organizationName: json['organizationName']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      accountStatus: json['accountStatus']?.toString() ?? '',
      firstLogin: json['firstLogin'] == true,
    );
  }
}
