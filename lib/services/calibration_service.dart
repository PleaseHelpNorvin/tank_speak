import '../core/json_utils.dart';
import '../models/calibration_profile.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

/// Read-only access to calibration profiles.
///
/// Profiles are global (shared by every customer) and are managed by
/// TankSpeak administrators in the web portal (`/calibration/`). The mobile
/// app lists and views them and assigns them to channels through
/// [DeviceService.setChannelCalibration]; it does not create, edit, import
/// or delete profiles.
class CalibrationService {
  CalibrationService([ApiService? api]) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<PaginatedResponse<CalibrationProfile>> fetchProfiles({
    int page = 1,
    int size = 20,
    String? name,
  }) async {
    final body = asMap(await _api.get('/calibration/profiles', query: {
      'page': page,
      'size': size,
      'name': name?.trim(),
    }));
    return PaginatedResponse<CalibrationProfile>.fromJson(
        body, CalibrationProfile.fromJson, 'profiles');
  }

  /// `GET /api/calibration/profile/{id}/calibrations` -> `{id, name}`.
  Future<CalibrationProfile> getProfileSummary(int profileId) async {
    final body = asMap(
        await _api.get('/calibration/profile/$profileId/calibrations'));
    return CalibrationProfile.fromJson(body);
  }

  /// Profile with its level -> volume rows.
  Future<CalibrationProfileDetailResponse> getProfileTable(
      int profileId) async {
    final body = asMap(await _api.get('/calibration/profile/$profileId'));
    return CalibrationProfileDetailResponse.fromJson(body);
  }
}
