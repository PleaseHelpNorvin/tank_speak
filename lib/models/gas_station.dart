import '../core/json_utils.dart';
import 'member.dart';
import 'tank.dart';

/// A `gas_stations` row as serialised by the backend.
class GasStation {
  GasStation({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    required this.phone,
    required this.businessHours,
    this.extendedBusinessHours,
    this.createdAt,
  });

  final int id;
  final int companyId;
  final String name;
  final String address;
  final String phone;
  final String businessHours;
  final String? extendedBusinessHours;
  final DateTime? createdAt;

  factory GasStation.fromJson(Map<String, dynamic> json) {
    return GasStation(
      id: asInt(json['id']) ?? 0,
      companyId: asInt(json['company_id']) ?? 0,
      name: asString(json['name']) ?? '',
      address: asString(json['address']) ?? '',
      phone: asString(json['phone']) ?? '',
      businessHours: asString(json['business_hours']) ?? '',
      extendedBusinessHours: asText(json['extended_business_hours']),
      createdAt: parseServerDate(json['created_at']),
    );
  }
}

/// `station_subscriptions` row included in the station detail response.
class StationSubscription {
  StationSubscription({
    required this.id,
    required this.planId,
    required this.isActive,
    this.startedAt,
    this.expiresAt,
  });

  final int id;
  final int? planId;
  final bool isActive;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now().toUtc());

  factory StationSubscription.fromJson(Map<String, dynamic> json) {
    return StationSubscription(
      id: asInt(json['id']) ?? 0,
      planId: asInt(json['subscription_plan_id'] ?? json['plan_id']),
      isActive: asBool(json['is_active']) ?? false,
      startedAt: parseServerDate(json['started_at']),
      expiresAt: parseServerDate(json['expires_at']),
    );
  }
}

/// `GET /api/station/g/{station_id}`.
class StationDetailResponse {
  StationDetailResponse({
    required this.station,
    required this.owner,
    required this.manager,
    required this.members,
    required this.devices,
    required this.subscription,
  });

  final GasStation station;
  final StationPerson? owner;
  final StationPerson? manager;

  /// Users with role `manager` or `member` (the owner is separate).
  final List<StationMember> members;
  final List<StationDevice> devices;
  final StationSubscription? subscription;

  factory StationDetailResponse.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    final manager = json['manager'];
    final subscription = json['subscription'];

    return StationDetailResponse(
      station: GasStation.fromJson(asMap(json['station'])),
      owner: owner is Map ? StationPerson.fromJson(asMap(owner)) : null,
      manager: manager is Map ? StationPerson.fromJson(asMap(manager)) : null,
      members: asMapList(json['members']).map(StationMember.fromJson).toList(),
      devices: asMapList(json['devices']).map(StationDevice.fromJson).toList(),
      subscription: subscription is Map
          ? StationSubscription.fromJson(asMap(subscription))
          : null,
    );
  }
}

/// `POST /api/station/c/{company}/station-create` response.
class CreateGasStationResponse {
  CreateGasStationResponse({required this.message, required this.station});

  final String message;
  final GasStation station;

  factory CreateGasStationResponse.fromJson(Map<String, dynamic> json) {
    return CreateGasStationResponse(
      message: asString(json['message']) ?? 'Gas station created',
      station: GasStation.fromJson(asMap(json['station'])),
    );
  }
}
