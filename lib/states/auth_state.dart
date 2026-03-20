import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/states/http_api.dart';

class AuthService {
  static final ApiService _api = ApiService();

  // ================= LOGIN =================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final token = res['access_token'];

    if (token != null) {
      await saveToken(token);
    }

    return res;
  }

  // ================= REGISTER =================
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/auth/register', {
      'email': email,
      'password': password,
    });

    return res;
  }

  // ================= SAVE TOKEN =================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ================= GET TOKEN =================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ================= GET SESSION =================
  static Future<Map<String, dynamic>?> getSession() async {
    try {
      final res = await _api.get('/auth/session');
      return res;
    } catch (e) {
      return null;
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _api.delete("/auth/logout");

    await prefs.remove('token');
  }

  // ================= CHECK LOGIN =================
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
