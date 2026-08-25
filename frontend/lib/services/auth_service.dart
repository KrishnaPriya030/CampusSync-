import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/login_response.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  Future<LoginResponse> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/auth/login',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return LoginResponse.fromJson(data);
    }

    throw Exception('Login failed');
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
    String token,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/users/change-password',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Password change failed');
    }
  }
}