class Owner {
  final int id;
  final String name;
  final String username;
  final String email;
  final String inviteCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? password; // optional (you may even remove this later)

  Owner({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.inviteCode,
    this.createdAt,
    this.updatedAt,
    this.password,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      inviteCode: json['invite_code'] ?? '',
      password: json['password'], // optional (consider removing later)

      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,

      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}