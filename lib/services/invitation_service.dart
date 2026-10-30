import '../core/json_utils.dart';
import '../models/invitation.dart';
import '../models/member.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

/// `/api/invite/*`.
///
/// Backend rules (enforced server-side): only station owners/managers can
/// invite; roles are `manager` or `member`; a station has at most one
/// manager; rejecting or cancelling an invitation deletes it.
class InvitationService {
  InvitationService([ApiService? api]) : _api = api ?? ApiService.instance;

  final ApiService _api;

  /// Roles the backend accepts for invitations.
  static const List<StationRole> invitableRoles = [
    StationRole.manager,
    StationRole.member,
  ];

  Future<PaginatedResponse<Invitation>> fetchReceived({
    int page = 1,
    int size = 50,
  }) async {
    final body = asMap(
        await _api.get('/invite', query: {'page': page, 'size': size}));
    return PaginatedResponse<Invitation>.fromJson(
        body, Invitation.fromJson, 'received_invitations');
  }

  Future<PaginatedResponse<Invitation>> fetchSent({
    int page = 1,
    int size = 50,
  }) async {
    final body = asMap(
        await _api.get('/invite/sent', query: {'page': page, 'size': size}));
    return PaginatedResponse<Invitation>.fromJson(
        body, Invitation.fromJson, 'sent_invitations');
  }

  /// Looks up the user who owns [code]. Returns null when no user has it.
  Future<InviteCodeLookup?> lookupInviteCode(String code) async {
    final body = await _api.get('/invite/search/${ApiService.seg(code.trim())}');
    if (body == null) return null;
    return InviteCodeLookup.fromJson(asMap(body));
  }

  Future<String> sendInvitation({
    required String code,
    required StationRole role,
    required int stationId,
    required int companyId,
  }) async {
    final body = asMap(await _api.post('/invite', body: {
      'code': code.trim(),
      'role': role.name,
      'station_id': stationId,
      'company_id': companyId,
    }));
    return asText(body['message']) ?? 'Invitation sent';
  }

  Future<String> accept(int invitationId) async {
    final body = asMap(await _api.post('/invite/$invitationId/accept'));
    return asText(body['message']) ?? 'Invitation accepted';
  }

  /// Rejects a received invitation or cancels a sent one.
  Future<String> delete(int invitationId) async {
    final body = asMap(await _api.delete('/invite/$invitationId'));
    return asText(body['message']) ?? 'Invitation removed';
  }
}
