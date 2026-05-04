class AreaManager {
  final int id;
  final String name;
  final String username;
  final String inviteCode;
  final String email;

  AreaManager({
    required this.id,
    required this.name,
    required this.username,
    required this.inviteCode,
    required this.email,
  });

  factory AreaManager.fromJson(Map<String, dynamic> json) {
    return AreaManager(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      inviteCode: json['invite_code'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
