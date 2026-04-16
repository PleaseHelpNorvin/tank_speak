import 'owner.dart';
import 'area_manager.dart';
import 'tank.dart';

class GasStation {
  final String id;
  final Owner owner;
  final AreaManager areaManager;
  final String companyName;
  final String address;
  final String businessHours;
  final List<Tank> tanks;

  GasStation({
    required this.id,
    required this.owner,
    required this.areaManager,
    required this.companyName,
    required this.address,
    required this.businessHours,
    required this.tanks,
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    return GasStation(
      id: json['id'],
      owner: Owner.fromJson(json['owner']),
      areaManager: AreaManager.fromJson(json['area_manager']),
      companyName: json['company_name'],
      address: json['address'],
      businessHours: json['business_hours'],
      tanks: (json['tanks'] as List)
          .map((e) => Tank.fromJson(e))
          .toList(),
    );
  }
}