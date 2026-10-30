import '../config/app_config.dart';

/// Device connectivity, mirroring `TelemetryService.connectivity` in the
/// backend (`services/telemetry_services.py`):
///
/// * `is_active == false`             -> disabled
/// * no contact at all                -> never
/// * last contact <= ONLINE minutes   -> online
/// * last contact <= STALE minutes    -> delayed
/// * otherwise                        -> offline
///
/// "Last contact" is the newest of `last_seen` and the latest payload time.
/// The backend does not expose this state through `/api`, so the same rule
/// and the same defaults (15 / 60 minutes, overridable with
/// `--dart-define=DEVICE_ONLINE_MINUTES` / `DEVICE_STALE_MINUTES`) are used
/// here. A successful HTTP request says nothing about the device itself.
enum ConnectivityState { online, delayed, offline, never, disabled }

/// Whether the latest stored readings are recent enough to trust.
enum ReadingsFreshness { fresh, stale, none }

class DeviceConnectivity {
  DeviceConnectivity({
    required this.state,
    required this.freshness,
    this.lastContact,
    this.lastPayloadAt,
  });

  final ConnectivityState state;
  final ReadingsFreshness freshness;
  final DateTime? lastContact;
  final DateTime? lastPayloadAt;

  static DeviceConnectivity evaluate({
    bool? isActive,
    DateTime? lastSeen,
    DateTime? lastPayloadAt,
    DateTime? now,
    int? onlineMinutes,
    int? staleMinutes,
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    final online = Duration(minutes: onlineMinutes ?? AppConfig.deviceOnlineMinutes);
    final stale = Duration(minutes: staleMinutes ?? AppConfig.deviceStaleMinutes);

    DateTime? lastContact;
    for (final candidate in [lastSeen, lastPayloadAt]) {
      if (candidate == null) continue;
      if (lastContact == null || candidate.isAfter(lastContact)) {
        lastContact = candidate;
      }
    }

    ConnectivityState state;
    if (isActive == false) {
      state = ConnectivityState.disabled;
    } else if (lastContact == null) {
      state = ConnectivityState.never;
    } else {
      final age = current.difference(lastContact);
      if (age <= online) {
        state = ConnectivityState.online;
      } else if (age <= stale) {
        state = ConnectivityState.delayed;
      } else {
        state = ConnectivityState.offline;
      }
    }

    ReadingsFreshness freshness;
    if (lastPayloadAt == null) {
      freshness = ReadingsFreshness.none;
    } else if (current.difference(lastPayloadAt) > stale) {
      freshness = ReadingsFreshness.stale;
    } else {
      freshness = ReadingsFreshness.fresh;
    }

    return DeviceConnectivity(
      state: state,
      freshness: freshness,
      lastContact: lastContact,
      lastPayloadAt: lastPayloadAt,
    );
  }

  String get label {
    switch (state) {
      case ConnectivityState.online:
        return 'Online';
      case ConnectivityState.delayed:
        return 'Delayed';
      case ConnectivityState.offline:
        return 'Offline';
      case ConnectivityState.never:
        return 'Never connected';
      case ConnectivityState.disabled:
        return 'Disabled';
    }
  }

  /// One-line explanation of what the readings mean right now.
  String get summary {
    switch (state) {
      case ConnectivityState.disabled:
        return 'This device is disabled.';
      case ConnectivityState.never:
        return 'This device has never sent telemetry.';
      case ConnectivityState.offline:
        return 'Device offline. Values shown are the last known readings.';
      case ConnectivityState.delayed:
        return 'Device has not reported recently.';
      case ConnectivityState.online:
        if (freshness == ReadingsFreshness.none) {
          return 'Device is online but has not sent any readings yet.';
        }
        if (freshness == ReadingsFreshness.stale) {
          return 'Device is online but its readings are outdated.';
        }
        return 'Live readings.';
    }
  }

  /// True when values should be treated as current.
  bool get readingsAreLive =>
      (state == ConnectivityState.online ||
          state == ConnectivityState.delayed) &&
      freshness == ReadingsFreshness.fresh;
}
