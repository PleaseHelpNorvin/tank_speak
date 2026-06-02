class DeviceReading {
  final String deviceId;
  final String sensorPin;

  final double raw;
  final double liters;

  final String status;
  final String? event; // 👈 ADD THIS
  final bool refillAlert;

  final DateTime timestamp;

  DeviceReading({
    required this.deviceId,
    required this.sensorPin,
    required this.raw,
    required this.liters,
    required this.status,
    this.event,

    required this.refillAlert,
    required this.timestamp,
  });

  factory DeviceReading.fromJson({
    required Map<String, dynamic> json,
    required String deviceId,
    required String sensorPin,
  }) {

    final rawValue = json['raw'];
    final litersValue = json['value'];

    return DeviceReading(
      deviceId: deviceId,
      sensorPin: sensorPin,

      raw: rawValue is num
          ? rawValue.toDouble()
          : double.tryParse(rawValue.toString()) ?? 0,

      liters: litersValue is num
          ? litersValue.toDouble()
          : double.tryParse(litersValue.toString()) ?? 0,
      status: json['status'] ?? "normal",
      event: json['event'],
      refillAlert: json['refill_alert'] ?? false,

      timestamp: DateTime.parse(
        "${json['timestamp']}Z",
      ).toLocal(),
    );
  }

  static List<DeviceReading> listFromJson(
      Map<String, dynamic> json,
      ) {

    final deviceId =
        json['device_id']?.toString() ?? '';

    final sensorPin =
        json['sensor_pin']?.toString() ?? '';

    final readings =
        json['readings'] as List? ?? [];

    return readings.map((e) {
      return DeviceReading.fromJson(
        json: e,
        deviceId: deviceId,
        sensorPin: sensorPin,
      );
    }).toList();
  }
}

class StationDevice {
  final Device device;
  final Map<String, dynamic> latestPayload;
  final String? payloadCreatedAt;

  StationDevice({
    required this.device,
    required this.latestPayload,
    this.payloadCreatedAt,
  });

  factory StationDevice.fromJson(Map<String, dynamic> json) {
    return StationDevice(
      device: Device.fromJson(json['device']),
      latestPayload: json['latest_payload'] ?? {},
      payloadCreatedAt: json['payload_created_at'],
    );
  }
}

class Device {
  final String id;
  final String name;
  final String deviceKey;
  final String type;

  Device({
    required this.id,
    required this.name,
    required this.deviceKey,
    required this.type,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      deviceKey: json['device_key'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class RegisterDeviceResponse {
  final String message;
  final Device device;

  RegisterDeviceResponse({
    required this.message,
    required this.device,
  });

  factory RegisterDeviceResponse.fromJson(Map<String, dynamic> json) {
    return RegisterDeviceResponse(
      message: json['message'],
      device: Device.fromJson(json['device']),
    );
  }
}
