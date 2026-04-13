import 'fuel.dart';

class GasStation {
  final String id;
  final String name;
  final String address;
  final String manager;
  final String contactNumber;
  final String businessHours;
  final String timeStamp;
  List<Fuel> fuels;

  GasStation({
    required this.id,
    required this.name,
    required this.address,
    required this.manager,
    required this.contactNumber,
    required this.businessHours,
    required this.timeStamp,
    required this.fuels,
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    return GasStation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      manager: json['manager'],
      contactNumber: json['contactNumber'],
      businessHours: json['businessHours'],
      timeStamp: json['timeStamp'],
      fuels: (json['fuels'] as List)
          .map((e) => Fuel.fromJson(e))
          .toList(),
    );
  }
}