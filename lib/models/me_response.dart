import 'area_manager.dart';
import 'owner.dart';

class MeResponse {
  final int id;
  final String username;
  final String email;
  final String inviteCode;
  final List<AreaManager> manager;
  final List<Owner> owner;

  MeResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.inviteCode,
    required this.manager,
    required this.owner,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      inviteCode: json['invite_code'] ?? '',

      // 👇 SAFE LIST PARSING (key fix)
      manager: (json['manager'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => AreaManager.fromJson(e))
          .toList(),

      owner: (json['owner'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => Owner.fromJson(e))
          .toList(),
    );
  }
  String get role {
    if (owner.isNotEmpty) return "OWNER";
    if (manager.isNotEmpty) return "MANAGER";
    return "UNKNOWN";
  }

  bool get isOwner => owner.isNotEmpty;
  bool get isManager => manager.isNotEmpty;
}