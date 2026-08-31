class Organizer {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String phoneNumber;
  final int organizationId;
  final String organizationName;
  final String designation;
  final String accountStatus;
  final bool firstLogin;

  const Organizer({
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

  factory Organizer.fromJson(
    Map<String, dynamic> json,
  ) {
    return Organizer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber:
          json['phoneNumber']?.toString() ?? '',
      organizationId:
          (json['organizationId'] as num?)?.toInt() ?? 0,
      organizationName:
          json['organizationName']?.toString() ?? '',
      designation:
          json['designation']?.toString() ?? '',
      accountStatus:
          json['accountStatus']?.toString() ?? '',
      firstLogin: json['firstLogin'] == true,
    );
  }

  Organizer copyWith({
    int? id,
    int? userId,
    String? name,
    String? email,
    String? phoneNumber,
    int? organizationId,
    String? organizationName,
    String? designation,
    String? accountStatus,
    bool? firstLogin,
  }) {
    return Organizer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      organizationId:
          organizationId ?? this.organizationId,
      organizationName:
          organizationName ?? this.organizationName,
      designation:
          designation ?? this.designation,
      accountStatus:
          accountStatus ?? this.accountStatus,
      firstLogin: firstLogin ?? this.firstLogin,
    );
  }
}