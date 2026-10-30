import '../models/gas_station.dart';
import '../models/me_response.dart';
import '../models/member.dart';

/// Decides which mobile role the signed-in user has at a station, for
/// showing or hiding actions. The backend checks every request again, so
/// this is a user-experience aid, not a security boundary.
///
/// Order mirrors `services/access_services.py`: a station-level owner or
/// manager row, then company ownership (company owners manage every station
/// of their company), then any other visible station counts as member.
StationRole stationRoleFor(
  MeResponse me,
  int stationId, {
  StationDetailResponse? detail,
  bool isCompanyOwner = false,
}) {
  if (me.ownsStation(stationId) || detail?.owner?.id == me.id) {
    return StationRole.owner;
  }
  if (isCompanyOwner) return StationRole.owner;
  if (me.managesStation(stationId) || detail?.manager?.id == me.id) {
    return StationRole.manager;
  }
  if (detail != null) {
    for (final m in detail.members) {
      if (m.person.id == me.id && m.role == StationRole.manager) {
        return StationRole.manager;
      }
    }
  }
  return StationRole.member;
}
