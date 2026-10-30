import '../core/json_utils.dart';
import '../models/paginated_response.dart';
import '../models/sensor.dart';
import '../models/tank.dart';
import 'api_service.dart';

/// `/api/device/*` and `/api/device-channel/*` used by the mobile app.
///
/// Device ingestion (`/device/command`, `/device/logs-create`) and firmware
/// endpoints belong to the hardware and are not called from the app.
class DeviceService {
  DeviceService([ApiService? api]) : _api = api ?? ApiService.instance;

  final ApiService _api;

  /// Valid `range` values of the readings endpoint.
  static const List<String> readingRanges = ['day', 'week', 'month', 'all'];

  /// Registers a provisioned device (MAC address) to a station.
  Future<RegisterDeviceResponse> registerDevice({
    required String deviceKey,
    required int stationId,
  }) async {
    // BLE characteristic reads can carry a trailing NUL or newline.
    final key = deviceKey.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    final body = asMap(await _api.post('/device/register', body: {
      'key': key,
      'station_id': stationId,
    }));
    return RegisterDeviceResponse.fromJson(body);
  }

  /// Calibrated readings of one channel, oldest first.
  ///
  /// The backend route is `/device/{device_id}/{sensor_pin}/readings` but it
  /// identifies the device by the `device_key` query parameter; the path id
  /// is ignored. 404 "Channel not found" means the channel has no mapping.
  Future<ReadingsResponse> getReadings({
    required int deviceId,
    required String deviceKey,
    required String channelKey,
    int limit = 200,
    String range = 'day',
  }) async {
    final body = asMap(await _api.get(
      '/device/$deviceId/${ApiService.seg(channelKey)}/readings',
      query: {'device_key': deviceKey, 'limit': limit, 'range': range},
    ));
    return ReadingsResponse.fromJson(body);
  }

  Future<List<ChannelMapping>> getChannelMappings(int deviceId) async {
    final body = await _api.get('/device-channel/$deviceId/channel-mapping');
    return ChannelMapping.listFromJson(body);
  }

  /// Creates or updates a channel label/unit. The backend overwrites both,
  /// so the current unit must be sent to keep it.
  Future<void> saveChannelMapping({
    required int deviceId,
    required String channelKey,
    required String label,
    String? unit,
  }) async {
    final cleanUnit = unit?.trim();
    await _api.post('/device-channel/$deviceId/channel-mapping', body: {
      'key': channelKey,
      'label': label.trim(),
      'unit': (cleanUnit == null || cleanUnit.isEmpty) ? null : cleanUnit,
    });
  }

  /// Assigns a calibration profile to one channel (owner/manager only).
  Future<void> setChannelCalibration({
    required int deviceId,
    required String channelKey,
    required int calibrationProfileId,
  }) async {
    await _api.post('/device-channel/$deviceId/channel-calibration', body: {
      'key': channelKey,
      'calibration_profile_id': calibrationProfileId,
    });
  }

  Future<PaginatedResponse<DeviceLog>> getLogs({
    required String deviceKey,
    int page = 1,
    int size = 20,
    String? level,
  }) async {
    final body = asMap(await _api.get(
      '/device/${ApiService.seg(deviceKey)}/logs',
      query: {'page': page, 'size': size, 'level': level},
    ));
    return PaginatedResponse<DeviceLog>.fromJson(
        body, DeviceLog.fromJson, 'logs');
  }
}
