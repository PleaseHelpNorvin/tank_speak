class VolumeReading {
  final String id;
  final double volume;
  final String timeStamp;

  VolumeReading({
    required this.id,
    required this.volume,
    required this.timeStamp,
  });

  factory VolumeReading.fromJson(Map<String, dynamic> json) {
    return VolumeReading(
      id: json['id'].toString(),
      volume: (json['volume'] as num).toDouble(),
      timeStamp: json['time_stamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}