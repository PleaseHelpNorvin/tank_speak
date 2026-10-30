import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/connectivity.dart';
import '../../models/me_response.dart';
import '../../models/sensor.dart';
import '../../models/tank.dart';
import '../../services/device_service.dart';
import '../../widgets/app_theme.dart';
import 'tank_detail_screen.dart';

/// Device information, connectivity, channel mappings and recent logs.
class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({
    super.key,
    required this.me,
    required this.stationDevice,
    required this.stationId,
    this.canManage = false,
  });

  final MeResponse me;
  final StationDevice stationDevice;
  final int stationId;
  final bool canManage;

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  final DeviceService _devices = DeviceService();

  List<ChannelMapping>? mappings;
  Object? mappingError;
  List<DeviceLog>? logs;
  int logTotal = 0;
  Object? logError;
  bool loading = true;

  Device get device => widget.stationDevice.device;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    List<ChannelMapping>? newMappings;
    Object? newMappingError;
    List<DeviceLog>? newLogs;
    int newLogTotal = 0;
    Object? newLogError;

    Future<void> loadMappings() async {
      try {
        newMappings = await _devices.getChannelMappings(device.id);
      } catch (e) {
        newMappingError = e;
      }
    }

    Future<void> loadLogs() async {
      try {
        final page =
            await _devices.getLogs(deviceKey: device.deviceKey, size: 20);
        newLogs = page.items;
        newLogTotal = page.total;
      } catch (e) {
        newLogError = e;
      }
    }

    await Future.wait([loadMappings(), loadLogs()]);

    if (!mounted) return;
    setState(() {
      mappings = newMappings;
      mappingError = newMappingError;
      logs = newLogs;
      logTotal = newLogTotal;
      logError = newLogError;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = DeviceConnectivity.evaluate(
      isActive: device.isActive,
      lastSeen: device.lastSeen,
      lastPayloadAt: widget.stationDevice.payloadCreatedAt,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(device.displayName),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconTile(Icons.memory,
                          size: 52,
                          color:
                              connectivityColor(context, connectivity.state)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(device.displayName,
                                style: context.text.titleMedium),
                            const SizedBox(height: 6),
                            ConnectivityBadge(connectivity),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(connectivity.summary,
                      style: context.text.bodyMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  InfoRow(
                      icon: Icons.fingerprint,
                      label: 'Device key',
                      value: device.deviceKey),
                  InfoRow(
                      icon: Icons.category_outlined,
                      label: 'Type',
                      value: device.type),
                  InfoRow(
                      icon: Icons.wifi_tethering,
                      label: 'Last contact',
                      value: connectivity.lastContact == null
                          ? 'Never'
                          : '${Fmt.dateTime(connectivity.lastContact)} '
                              '(${Fmt.ago(connectivity.lastContact)})'),
                  InfoRow(
                      icon: Icons.update,
                      label: 'Latest reading',
                      value:
                          Fmt.dateTime(widget.stationDevice.payloadCreatedAt)),
                  if (device.createdAt != null)
                    InfoRow(
                        icon: Icons.event_available_outlined,
                        label: 'Registered',
                        value: Fmt.date(device.createdAt)),
                  if (device.lastSeen == null &&
                      widget.stationDevice.payloadCreatedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Connection time is based on the latest reading.',
                        style: context.text.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            const SectionTitle('Channels'),
            _channels(),
            SectionTitle('Recent logs',
                trailing: logTotal > 0
                    ? Text('$logTotal',
                        style: context.text.labelLarge?.copyWith(
                            color: context.colors.onSurfaceVariant))
                    : null),
            _logs(),
          ],
        ),
      ),
    );
  }

  Widget _channels() {
    if (loading && mappings == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }

    // Mapped channels plus channels present in the latest payload.
    final readings = {
      for (final c in widget.stationDevice.channels) c.key: c,
    };
    final mapped = {
      for (final m in mappings ?? <ChannelMapping>[]) m.channelKey: m
    };
    final keys = {...readings.keys, ...mapped.keys}.toList()..sort();

    if (keys.isEmpty) {
      return AppCard(
        child: Text(
          mappingError != null
              ? mappingError.toString()
              : 'No channels yet. Channels appear when the device sends '
                  'readings.',
          style: context.text.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: keys.map((key) {
          final reading = readings[key];
          final mapping = mapped[key];
          final label = mapping?.label ?? reading?.label ?? key;
          final calibrated = (mapping?.calibrationProfileId ??
                  reading?.calibrationProfileId) !=
              null;
          final details = <String>[
            key,
            if (mapping?.unit != null) mapping!.unit!,
            calibrated ? 'calibrated' : 'not calibrated',
            if (reading == null) 'not in latest reading',
          ];

          return ListTile(
            leading: Icon(Icons.propane_tank_outlined,
                color: context.colors.primary),
            title: Text(label),
            subtitle: Text(details.join(' • ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reading != null)
                  StatusPill(
                    label: reading.status.label,
                    color: channelStatusColor(context, reading.status),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TankDetailScreen(
                    me: widget.me,
                    device: device,
                    channelKey: key,
                    channelLabel: label,
                    channelUnit: mapping?.unit ?? reading?.unit,
                    activeCalibProfileId: mapping?.calibrationProfileId ??
                        reading?.calibrationProfileId,
                    stationId: widget.stationId,
                    canManage: widget.canManage,
                    lastPayloadAt: widget.stationDevice.payloadCreatedAt,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _logs() {
    if (loading && logs == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }
    if (logError != null) {
      return AppCard(
        child: Text(logError.toString(),
            style: context.text.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
      );
    }
    final items = logs ?? const <DeviceLog>[];
    if (items.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            Icon(Icons.receipt_long_outlined,
                color: context.colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Text('No logs from this device.',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: items.map((log) {
          final level = log.level.toUpperCase();
          final color = level.startsWith('ERR')
              ? context.status.danger
              : level.startsWith('WARN')
                  ? context.status.warning
                  : context.status.neutral;
          return ListTile(
            title: Text(log.message),
            subtitle: Text(Fmt.dateTime(log.createdAt)),
            trailing:
                StatusPill(label: level.isEmpty ? 'LOG' : level, color: color),
          );
        }).toList(),
      ),
    );
  }
}
