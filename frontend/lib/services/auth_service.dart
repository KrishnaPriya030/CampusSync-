import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_response.dart';
import '../models/user_profile.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8080';

  // ============================================================
  // LOGIN
  // ============================================================

  Future<LoginResponse> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

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
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      return LoginResponse.fromJson(data);
    }

    throw Exception(
      'Login failed: ${response.statusCode}',
    );
  }

  // ============================================================
  // GET CURRENT USER
  // ============================================================

  Future<UserProfile> getCurrentUser(
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/users/me');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      return UserProfile.fromJson(data);
    }

    throw Exception(
      'Failed to get current user: ${response.statusCode}',
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
    String token,
  ) async {
    final url =
        Uri.parse('$baseUrl/api/users/change-password');

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
      throw Exception(
        'Password change failed: ${response.statusCode}',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove authentication/session information.
    await prefs.remove('token');
    await prefs.remove('accessToken');
    await prefs.remove('user');
    await prefs.remove('userProfile');
  }

  // ============================================================
  // CLEAR ALL SESSION DATA
  // ============================================================

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}