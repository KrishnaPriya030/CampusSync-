class Department {
  final int id;
  final String name;
  final String code;
  final bool active;

  Department({
    required this.id,
    required this.name,
    required this.code,
    required this.active,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      active: json['active'] ?? false,
    );
  }
}