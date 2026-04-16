import 'volume_reading.dart';

class Tank {
  final String id;
  final String productName;
  final double currentVolume;
  final String status;
  final double maxCapacity;
  final double radius;
  final double length;
  final List<VolumeReading> readings;

  Tank({
    required this.id,
    required this.productName,
    required this.currentVolume,
    required this.status,
    required this.maxCapacity,
    required this.radius,
    required this.length,
    required this.readings,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      id: json['id'],
      productName: json['product_name'],
      currentVolume: (json['current_volume'] as num).toDouble(),
      status: json['status'],
      maxCapacity: (json['max_capacity'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      length: (json['length'] as num).toDouble(),
      readings: (json['readings'] as List)
          .map((e) => VolumeReading.fromJson(e))
          .toList(),
    );
  }
}