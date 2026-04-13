class AuthService {
  bool isLoggedIn = false;

  Future<bool> login(String email, String password) async {
    await Future.delayed(Duration(seconds: 1));
    isLoggedIn = true;
    return true;
  }

  Future<bool> register(String email, String password) async {
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  void logout() {
    isLoggedIn = false;
  }
}