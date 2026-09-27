import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      tokenKey,
      token,
    );
  }

  Future<String?> getToken() async {
    final preferences =
        await SharedPreferences.getInstance();

    return preferences.getString(tokenKey);
  }

  Future<void> clearToken() async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(tokenKey);
  }
}