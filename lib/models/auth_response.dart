class AuthResponse {
  final String token;
  final String type;

  AuthResponse({
    required this.token,
    required this.type,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      type: json['type'],
    );
  }
}