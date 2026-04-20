import 'tank.dart';
class GasStation {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String businessHours;
  final List<Device> tanks;

  GasStation({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.businessHours,
    required this.tanks,
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    return GasStation(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      businessHours: json['business_hours'] ?? '',
      tanks: (json['tanks'] as List<dynamic>? ?? [])
          .map((item) => Device.fromJson(item))
          .toList(),
    );
  }
}

class StationDetailResponse {
  final GasStation station;
  final Map<String, dynamic>? manager;
  final Map<String, dynamic>? owner;

  StationDetailResponse({
    required this.station,
    this.manager,
    this.owner,
  });

  factory StationDetailResponse.fromJson(Map<String, dynamic> json) {
    return StationDetailResponse(
      station: GasStation.fromJson(json['station']),
      manager: json['manager'] != null
          ? Map<String, dynamic>.from(json['manager'])
          : null,
      owner: json['owner'] != null
          ? Map<String, dynamic>.from(json['owner'])
          : null,
    );
  }
}


class CreateGasStationResponse {
  final String message;
  final GasStation station;

  CreateGasStationResponse({
    required this.message,
    required this.station,
  });

  factory CreateGasStationResponse.fromJson(Map<String, dynamic> json) {
    return CreateGasStationResponse(
      message: json['message'],
      station: GasStation.fromJson(json['station']),
    );
  }
}