class CreateStudentResponse {
  final int userId;
  final String name;
  final String email;
  final String registerNumber;
  final String temporaryPassword;

  const CreateStudentResponse({
    required this.userId,
    required this.name,
    required this.email,
    required this.registerNumber,
    required this.temporaryPassword,
  });

  factory CreateStudentResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreateStudentResponse(
      userId:
          (json['userId'] as num?)?.toInt() ?? 0,
      name:
          json['name']?.toString() ?? '',
      email:
          json['email']?.toString() ?? '',
      registerNumber:
          json['registerNumber']?.toString() ?? '',
      temporaryPassword:
          json['temporaryPassword']?.toString() ?? '',
    );
  }
}