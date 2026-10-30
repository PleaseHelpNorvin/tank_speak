import '../core/json_utils.dart';

/// Mobile-facing roles. Administrators are not a mobile role.
enum StationRole { owner, manager, member }

extension StationRoleLabel on StationRole {
  String get label {
    switch (this) {
      case StationRole.owner:
        return 'Owner';
      case StationRole.manager:
        return 'Manager';
      case StationRole.member:
        return 'Member';
    }
  }

  /// Owners and managers may manage station resources (invite people,
  /// rename channels, assign calibration, register devices). The backend
  /// enforces the same rule; this only decides which buttons are shown.
  bool get canManageStation =>
      this == StationRole.owner || this == StationRole.manager;
}

StationRole? parseStationRole(Object? value) {
  switch (asString(value)?.trim().toLowerCase()) {
    case 'owner':
      return StationRole.owner;
    case 'manager':
      return StationRole.manager;
    case 'member':
      return StationRole.member;
  }
  return null;
}

/// A person attached to a station (owner, manager or member).
///
/// Only display fields are parsed. The backend currently serialises full
/// user rows here (including password hashes); those fields are ignored and
/// never stored.
class StationPerson {
  StationPerson({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
  });

  final int id;
  final String name;
  final String username;
  final String email;

  String get displayName => name.isNotEmpty ? name : username;

  factory StationPerson.fromJson(Map<String, dynamic> json) {
    return StationPerson(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      username: asString(json['username']) ?? '',
      email: asString(json['email']) ?? '',
    );
  }
}

/// `{"user": {...}, "member": {"role": ...}}` entries of the station detail.
class StationMember {
  StationMember({required this.person, required this.role, this.rawRole});

  final StationPerson person;
  final StationRole? role;

  /// Original role text, kept for rows with a non-standard role.
  final String? rawRole;

  String get roleLabel => role?.label ?? (rawRole ?? 'Unknown');

  factory StationMember.fromJson(Map<String, dynamic> json) {
    final member = asMap(json['member']);
    return StationMember(
      person: StationPerson.fromJson(asMap(json['user'])),
      role: parseStationRole(member['role']),
      rawRole: asText(member['role']),
    );
  }
}

/// `GET /api/company/{company}/company-members` entries.
class CompanyMember {
  CompanyMember({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    this.rawRole,
  });

  final int userId;
  final String username;
  final String email;
  final StationRole? role;
  final String? rawRole;

  String get roleLabel => role?.label ?? (rawRole ?? 'Unknown');

  factory CompanyMember.fromJson(Map<String, dynamic> json) {
    return CompanyMember(
      userId: asInt(json['id']) ?? 0,
      username: asString(json['username']) ?? '',
      email: asString(json['email']) ?? '',
      role: parseStationRole(json['role']),
      rawRole: asText(json['role']),
    );
  }
}
