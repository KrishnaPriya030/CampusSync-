import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';
import '../models/user_profile.dart';
//All api calls happens here
class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8080'; //this is the backend address.All api calls will go here
  
  Future<LoginResponse> login(String email, String password) async {//this is login method.You give the email and password and it will return login response
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(//Go to /api/auth/login and give email/password to backend. Backend will check and return token.
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LoginResponse.fromJson(data);//If status is 200 (success), then LoginResponse.fromJson(data) - convert backend JSON into Dart object.
    }
    throw Exception('Login failed');
  }

  
  Future<UserProfile> getCurrentUser(String token) async {
    final url = Uri.parse('$baseUrl/api/users/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserProfile.fromJson(data);
    } else {
      throw Exception('Token expired');
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/users/change-password');
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