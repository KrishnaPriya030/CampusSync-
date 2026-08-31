class Organization {
  final int id;
  final String name;
  final String code;
  final String organizationType;
  final int? departmentId;
  final String? departmentName;
  final String description;
  final bool active;

  const Organization({
    required this.id,
    required this.name,
    required this.code,
    required this.organizationType,
    this.departmentId,
    this.departmentName,
    required this.description,
    required this.active,
  });

  factory Organization.fromJson(
    Map<String, dynamic> json,
  ) {
    return Organization(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      organizationType:
          json['organizationType']?.toString() ?? '',
      departmentId:
          (json['departmentId'] as num?)?.toInt(),
      departmentName:
          json['departmentName']?.toString(),
      description:
          json['description']?.toString() ?? '',
      active: json['active'] == true,
    );
  }
}