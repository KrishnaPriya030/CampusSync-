class LoginResponse {
  final String token;
  final int userId;
  final String name;
  final String email;
  final String role;
  final bool firstLogin;

  const LoginResponse({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.firstLogin,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      userId: json['userId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      firstLogin: json['firstLogin'] as bool,
    );
  }
}