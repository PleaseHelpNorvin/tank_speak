import '../core/json_utils.dart';
import 'gas_station.dart';

/// `GET /api/me`.
///
/// The backend returns the user plus the stations where the user has a
/// station-level `owner` or `manager` membership. Plain `member` stations are
/// not listed here; they are discovered through `/api/company`.
class MeResponse {
  MeResponse({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.inviteCode,
    required this.ownerStations,
    required this.managerStations,
    required this.isAdmin,
    required this.isSuperAdmin,
  });

  final int id;
  final String username;
  final String name;
  final String email;
  final String inviteCode;
  final List<GasStation> ownerStations;
  final List<GasStation> managerStations;

  /// Only known if the backend includes these fields in `/api/me`. The
  /// current backend does not (see the integration report); when they are
  /// present and true the mobile app refuses the session.
  final bool isAdmin;
  final bool isSuperAdmin;

  bool get isAdministrator => isAdmin || isSuperAdmin;

  String get displayName => name.isNotEmpty ? name : username;

  bool ownsStation(int stationId) =>
      ownerStations.any((s) => s.id == stationId);

  bool managesStation(int stationId) =>
      managerStations.any((s) => s.id == stationId);

  /// Station ids where the user is owner or manager.
  Set<int> get managedStationIds => {
        ...ownerStations.map((s) => s.id),
        ...managerStations.map((s) => s.id),
      };

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      id: asInt(json['id']) ?? 0,
      username: asString(json['username']) ?? '',
      name: asString(json['name']) ?? '',
      email: asString(json['email']) ?? '',
      inviteCode: asString(json['invite_code']) ?? '',
      ownerStations:
          asMapList(json['owner']).map(GasStation.fromJson).toList(),
      managerStations:
          asMapList(json['manager']).map(GasStation.fromJson).toList(),
      isAdmin: asBool(json['is_admin']) ?? false,
      isSuperAdmin: asBool(json['is_super_admin']) ?? false,
    );
  }
}
