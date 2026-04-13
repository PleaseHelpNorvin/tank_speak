import 'tank_reading.dart';

class Fuel {
  final String id;
  final String name;
  final double tankCapacity;
  final double averageThroughput;
  final String anticipatedDryUp;
  final String fillAlert;
  final String timeStamp;
  List<TankReading>? readings;

  Fuel({
    required this.id,
    required this.name,
    required this.tankCapacity,
    required this.averageThroughput,
    required this.anticipatedDryUp,
    required this.fillAlert,
    required this.timeStamp,
    this.readings,
  });

  factory Fuel.fromJson(Map<String, dynamic> json) {
    return Fuel(
      id: json['id'],
      name: json['name'],
      tankCapacity: json['tankCapacity'].toDouble(),
      averageThroughput: json['averageThroughput'].toDouble(),
      anticipatedDryUp: json['anticipatedDryUp'],
      fillAlert: json['fillAlert'],
      timeStamp: json['timeStamp'],
      readings: json['readings'] != null
          ? (json['readings'] as List)
          .map((e) => TankReading.fromJson(e))
          .toList()
          : null,
    );
  }
}