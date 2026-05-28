class CalibrationProfile {
  final int id;
  final String name;

  CalibrationProfile({
    required this.id,
    required this.name,
  });

  factory CalibrationProfile.fromJson(Map<String, dynamic> json) {
    return CalibrationProfile(
      id: json['id'],
      name: json['name'],
    );
  }

  static List<CalibrationProfile> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((e) => CalibrationProfile.fromJson(e))
        .toList();
  }
}


class CreateCalibrationProfileResponse {
  final String message;
  final CalibrationProfile profile;

  CreateCalibrationProfileResponse({
    required this.message,
    required this.profile,
  });

  factory CreateCalibrationProfileResponse.fromJson(Map<String, dynamic> json) {
    return CreateCalibrationProfileResponse(
      message: json['message'] ?? '',
      profile: CalibrationProfile.fromJson(json['profile']),
    );
  }
}

class CalibrationEntry {
  final int id;
  final int deviceCalibrationProfileId;

  final double? dipstickLiters;
  final double? actualLiters;
  final double? volumeLiters;

  final int level;

  final double? lengthCm;
  final double? radiusCm;

  final String createdAt;

  CalibrationEntry({
    required this.id,
    required this.deviceCalibrationProfileId,
    required this.dipstickLiters,
    required this.actualLiters,
    required this.volumeLiters,
    required this.level,
    required this.lengthCm,
    required this.radiusCm,
    required this.createdAt,
  });

  factory CalibrationEntry.fromJson(Map<String, dynamic> json) {
    return CalibrationEntry(
      id: (json['id'] as num).toInt(),

      deviceCalibrationProfileId:
      (json['device_calibration_profile_id'] as num)
          .toInt(),

      dipstickLiters:
      (json['dipstick_liters'] as num?)
          ?.toDouble(),

      actualLiters:
      (json['actual_liters'] as num?)
          ?.toDouble(),

      volumeLiters:
      (json['volume_liters'] as num?)
          ?.toDouble(),

      level:
      (json['level'] as num?)?.toInt() ?? 0,

      lengthCm:
      (json['length_cm'] as num?)
          ?.toDouble(),

      radiusCm:
      (json['radius_cm'] as num?)
          ?.toDouble(),

      createdAt: json['created_at'] ?? '',
    );
  }

  static List<CalibrationEntry> listFromJson(
      List<dynamic> jsonList,
      ) {
    return jsonList
        .map((e) => CalibrationEntry.fromJson(e))
        .toList();
  }
}

class CalibrationProfileDetailResponse {
  final CalibrationProfile profile;
  final List<CalibrationEntry> calibrations;

  CalibrationProfileDetailResponse({
    required this.profile,
    required this.calibrations,
  });

  factory CalibrationProfileDetailResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return CalibrationProfileDetailResponse(
      profile: CalibrationProfile.fromJson(json['profile']),
      calibrations: CalibrationEntry.listFromJson(
        json['calibrations'] ?? [],
      ),
    );
  }
}