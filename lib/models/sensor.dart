class SensorPayload {
  final String deviceId;
  final String payloadType;
  final Map<String, dynamic> payload;
  final String? createdAt;

  SensorPayload({
    required this.deviceId,
    required this.payloadType,
    required this.payload,
    this.createdAt,
  });

  factory SensorPayload.fromJson(Map<String, dynamic> json) {
    return SensorPayload(
      deviceId: json['device_id'] ?? '',
      payloadType: json['payload_type'] ?? '',

      payload: (json['payload'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value)),
      createdAt: json['created_at'],
    );
  }
}