class ActivateOrganizerRequest {
  final String token;
  final String password;
  final String confirmPassword;

  const ActivateOrganizerRequest({
    required this.token,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }
}