import '../core/json_utils.dart';
import 'member.dart';

/// `GET /api/invite/search/{code}`: the user who owns an invite code.
class InviteCodeLookup {
  InviteCodeLookup({
    required this.name,
    required this.email,
    required this.inviteCode,
    required this.alreadyInvitedByMe,
    this.invitedToCompanyName,
  });

  /// The backend returns the user's display name under `username`.
  final String name;
  final String email;
  final String inviteCode;

  /// True when the current user has already sent this person an invitation
  /// (to any station).
  final bool alreadyInvitedByMe;
  final String? invitedToCompanyName;

  factory InviteCodeLookup.fromJson(Map<String, dynamic> json) {
    final invitedTo = json['invited_to'];
    return InviteCodeLookup(
      name: asString(json['username']) ?? '',
      email: asString(json['email']) ?? '',
      inviteCode: asString(json['invite_code']) ?? '',
      alreadyInvitedByMe: asBool(json['invited']) ?? false,
      invitedToCompanyName:
          invitedTo is Map ? asText(asMap(invitedTo)['name']) : null,
    );
  }
}

/// An `invitations` row (received or sent).
///
/// The backend has no status column: accepted invitations are kept, and
/// rejecting or cancelling deletes the row.
class Invitation {
  Invitation({
    required this.id,
    required this.companyId,
    required this.stationId,
    required this.inviterId,
    required this.receiverId,
    required this.role,
    required this.rawRole,
    required this.message,
    this.createdAt,
  });

  final int id;
  final int companyId;
  final int stationId;
  final int inviterId;
  final int receiverId;
  final StationRole? role;
  final String rawRole;
  final String message;
  final DateTime? createdAt;

  String get roleLabel => role?.label ?? rawRole;

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: asInt(json['id']) ?? 0,
      companyId: asInt(json['company_id']) ?? 0,
      stationId: asInt(json['gas_station']) ?? 0,
      inviterId: asInt(json['user_inviter']) ?? 0,
      receiverId: asInt(json['user_receiver']) ?? 0,
      role: parseStationRole(json['role']),
      rawRole: asString(json['role']) ?? '',
      message: asString(json['message']) ?? '',
      createdAt: parseServerDate(json['created_at']),
    );
  }
}

/// Status shown for a received invitation, derived from the stations the
/// user can access (the backend stores no status).
enum InvitationStatus { pending, accepted }
