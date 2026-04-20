import 'package:shared_preferences/shared_preferences.dart';
import '../models/me_response.dart';
import '../services/api_service.dart';
import '../models/auth_response.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  bool isLoggedIn = false;
  String? token;
  String? type;
  // =========================
  // 🔐 LOGIN
  // =========================
  Future<AuthResponse> login(String username, String password) async {
    final response = await _apiService.login(
      username: username,
      password: password,
    );

    token = response.token;
    type = response.type;
    isLoggedIn = true;
    print("login token: $token");
    await saveToken(token!);

    return response;
  }

  // =========================
  // 💾 TOKEN STORAGE
  // =========================
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // =========================
  // 🧪 REGISTER
  // =========================
  Future<bool> register(
      String username,
      String name,
      String email,
      String password,
      ) async {
    return await _apiService.register(
      username: username,
      name: name,
      email: email,
      password: password,
    );
  }

  Future<MeResponse> getMe() async {

    final response = await _apiService.getMe();
    return response;
  }

  // =========================
  // 🚪 LOGOUT
  // =========================
  Future<void> logout() async {
    isLoggedIn = false;
    token = null;
    type = null;

    await clearToken();
  }
}