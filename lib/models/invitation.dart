class Invitation {
  final String username;
  final String email;
  final String inviteCode;
  final int? invitedTo;
  final bool invited;

  Invitation({
    required this.username,
    required this.email,
    required this.inviteCode,
    required this.invitedTo,
    required this.invited,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      inviteCode: json['invite_code'] ?? '',
      invitedTo: json['invited_to'],
      invited: json['invited'] ?? false,
    );
  }
}

class ReceivedInvitation {
  final int id;
  final int gasStation;
  final String message;
  final String role;
  final int userInviter;
  final int userReceiver;
  final String createdAt;
  final String updatedAt;

  ReceivedInvitation({
    required this.id,
    required this.gasStation,
    required this.message,
    required this.role,
    required this.userInviter,
    required this.userReceiver,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReceivedInvitation.fromJson(Map<String, dynamic> json) {
    return ReceivedInvitation(
      id: json['id'],
      gasStation: json['gas_station'],
      message: json['message'] ?? '',
      role: json['role'] ?? '',
      userInviter: json['user_inviter'],
      userReceiver: json['user_receiver'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}