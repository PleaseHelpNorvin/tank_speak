import '../services/api_service.dart';
import '../models/auth_response.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  bool isLoggedIn = false;
  String? token;
  String? type;

  Future<AuthResponse> login(String username, String password) async {
    final response = await _apiService.login(
      username: username,
      password: password,
    );

    isLoggedIn = true;
    token = response.token;
    type = response.type;

    return response;
  }

  Future<bool> register(String username, String password) async {
    return await _apiService.register(
      username: username,
      password: password,
    );
  }

  void logout() {
    isLoggedIn = false;
    token = null;
    type = null;
  }
}