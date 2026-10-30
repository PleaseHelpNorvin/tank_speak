import '../core/json_utils.dart';

/// A calibration ("lookup") profile: level -> volume table shared by
/// channels. Calibration math is done by the backend; the app only displays
/// profiles and assigns them to channels.
class CalibrationProfile {
  CalibrationProfile({required this.id, required this.name, this.percentage});

  final int id;
  final String name;

  /// Low-level threshold percentage, when the endpoint includes it.
  final double? percentage;

  factory CalibrationProfile.fromJson(Map<String, dynamic> json) {
    return CalibrationProfile(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      percentage: asDouble(json['percentage']),
    );
  }
}

/// One row of a calibration table.
class CalibrationEntry {
  CalibrationEntry({
    required this.id,
    required this.level,
    this.dipstickLiters,
    this.volumeLiters,
    this.actualLiters,
  });

  final int id;
  final double level;
  final double? dipstickLiters;
  final double? volumeLiters;
  final double? actualLiters;

  factory CalibrationEntry.fromJson(Map<String, dynamic> json) {
    return CalibrationEntry(
      id: asInt(json['id']) ?? 0,
      level: asDouble(json['level']) ?? 0,
      dipstickLiters: asDouble(json['dipstick_liters']),
      volumeLiters: asDouble(json['volume_liters']),
      actualLiters: asDouble(json['actual_liters']),
    );
  }
}

/// `GET /api/calibration/profile/{profile_id}`.
class CalibrationProfileDetailResponse {
  CalibrationProfileDetailResponse({
    required this.profile,
    required this.calibrations,
  });

  final CalibrationProfile profile;
  final List<CalibrationEntry> calibrations;

  factory CalibrationProfileDetailResponse.fromJson(Map<String, dynamic> json) {
    return CalibrationProfileDetailResponse(
      profile: CalibrationProfile.fromJson(asMap(json['profile'])),
      calibrations: asMapList(json['calibrations'])
          .map(CalibrationEntry.fromJson)
          .toList(),
    );
  }
}
