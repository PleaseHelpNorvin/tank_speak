import '../core/api_exception.dart';
import '../core/json_utils.dart';
import '../models/gas_station.dart';
import '../models/paginated_response.dart';
import '../models/tank.dart';
import 'api_service.dart';

/// `/api/station/*` and `/api/stations/{company}`.
class StationService {
  StationService([ApiService? api]) : _api = api ?? ApiService.instance;

  final ApiService _api;

  /// Station detail with owner, manager, members, devices + latest
  /// calibrated readings and subscription. Access is checked by the backend
  /// (404 when the user cannot see the station).
  Future<StationDetailResponse> getStation(int stationId) async {
    final body = asMap(await _api.get('/station/g/$stationId'));
    return StationDetailResponse.fromJson(body);
  }

  /// Devices of a station including `is_active` and `last_seen`.
  ///
  /// The backend only answers this for users with a station-level
  /// membership row; company owners without one get 404. Callers treat that
  /// as "connectivity metadata unavailable".
  Future<List<Device>> getStationDevices({
    required int companyId,
    required int stationId,
  }) async {
    final devices = <Device>[];
    var page = 1;
    while (true) {
      final body = asMap(await _api.get(
        '/station/$companyId/$stationId/devices',
        query: {'page': page, 'size': 50},
      ));
      final pageItems = asMapList(body['devices']).map(Device.fromJson).toList();
      devices.addAll(pageItems);
      final total = asInt(body['total']) ?? devices.length;
      if (pageItems.isEmpty || devices.length >= total || page >= 20) break;
      page++;
    }
    return devices;
  }

  /// Station detail plus device connectivity metadata when available.
  Future<StationDetailResponse> getStationWithDeviceStatus(
      int stationId) async {
    final detail = await getStation(stationId);
    if (detail.devices.isEmpty) return detail;

    try {
      final devices = await getStationDevices(
        companyId: detail.station.companyId,
        stationId: stationId,
      );
      final byId = {for (final d in devices) d.id: d};
      final merged = detail.devices.map((sd) {
        final extra = byId[sd.device.id];
        if (extra == null) return sd;
        return sd.withDevice(sd.device.copyWith(
          isActive: extra.isActive,
          lastSeen: extra.lastSeen,
          stationId: extra.stationId,
        ));
      }).toList();

      return StationDetailResponse(
        station: detail.station,
        owner: detail.owner,
        manager: detail.manager,
        members: detail.members,
        devices: merged,
        subscription: detail.subscription,
      );
    } on ApiException catch (e) {
      if (e.isNotFound || e.isForbidden) return detail;
      rethrow;
    }
  }

  /// Stations of a company where the user has a station-level membership.
  Future<PaginatedResponse<GasStation>> fetchMyStations(
    int companyId, {
    int page = 1,
    int size = 10,
  }) async {
    final body = asMap(await _api.get('/stations/$companyId',
        query: {'page': page, 'size': size}));
    return PaginatedResponse<GasStation>.fromJson(
        body, GasStation.fromJson, 'stations');
  }

  /// Creates a station in a company the user owns. The backend requires an
  /// active subscription plan id and starts the subscription immediately.
  Future<CreateGasStationResponse> createStation({
    required int companyId,
    required String name,
    required String address,
    required String phone,
    required String businessHours,
    String? extendedBusinessHours,
    required int subscriptionPlanId,
  }) async {
    final ex = extendedBusinessHours?.trim();
    final body = asMap(await _api.post(
      '/station/c/$companyId/station-create',
      body: {
        'name': name.trim(),
        'address': address.trim(),
        'phone': phone.trim(),
        'business_hours': businessHours.trim(),
        'ex_business_hour': (ex == null || ex.isEmpty) ? null : ex,
        'subscription_plan_id': subscriptionPlanId,
      },
    ));
    return CreateGasStationResponse.fromJson(body);
  }
}
