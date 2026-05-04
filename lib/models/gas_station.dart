import 'area_manager.dart';
import 'owner.dart';
import 'tank.dart';
class GasStation {
  final int id;
  final int companyId;
  final String name;
  final String address;
  final String phone;
  final String businessHours;
  final List<Device> tanks;

  GasStation({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    required this.phone,
    required this.businessHours,
    required this.tanks,
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    return GasStation(
      id: json['id'],
      companyId: json['company_id'],
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
  final AreaManager? manager;
  final Owner? owner;
  final Device? norvi;

  StationDetailResponse({
    required this.station,
    this.manager,
    this.owner,
    this.norvi,
  });

  factory StationDetailResponse.fromJson(Map<String, dynamic> json) {
    return StationDetailResponse(
      station: GasStation.fromJson(json['station']),

      manager: json['manager'] != null
          ? AreaManager.fromJson(json['manager'])
          : null,

      owner: json['owner'] != null
          ? Owner.fromJson(json['owner'])
          : null,

      norvi: json['norvi'] != null
          ? Device.fromJson(json['norvi'])
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