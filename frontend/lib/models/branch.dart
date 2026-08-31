class Branch {
  final int id;
  final String name;
  final String code;
  final bool active;

  Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.active,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      active: json['active'] ?? false,
    );
  }
}