import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../models/connectivity.dart';
import '../../models/me_response.dart';
import '../../models/tank.dart';
import '../../services/device_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/auto_refresh.dart';
import '../../widgets/state_views.dart';
import 'edit_sensor_name.dart';
import 'set_calibration_screen.dart';

/// One tank (device channel): latest calibrated volume, history chart and
/// alerts, from `GET /api/device/{id}/{channel}/readings`.
class TankDetailScreen extends StatefulWidget {
  final MeResponse me;
  final Device device;
  final String channelKey;
  final String channelLabel;
  final String? channelUnit;
  final int? activeCalibProfileId;
  final int stationId;
  final bool canManage;

  /// Latest payload time of the device from the station screen.
  final DateTime? lastPayloadAt;

  const TankDetailScreen({
    super.key,
    required this.me,
    required this.device,
    required this.channelKey,
    required this.channelLabel,
    required this.stationId,
    this.channelUnit,
    this.activeCalibProfileId,
    this.canManage = false,
    this.lastPayloadAt,
  });

  @override
  State<TankDetailScreen> createState() => _TankDetailScreenState();
}

class _TankDetailScreenState extends State<TankDetailScreen>
    with AutoRefreshMixin<TankDetailScreen> {
  final DeviceService _devices = DeviceService();

  ReadingsResponse? data;
  Object? error;
  bool loading = true;
  bool _inFlight = false;
  DateTime? lastUpdated;

  late String label = widget.channelLabel;
  late String? unit = widget.channelUnit;
  late int? profileId = widget.activeCalibProfileId;

  String selectedRange = "day";

  static const Map<String, String> rangeLabels = {
    'day': '24 h',
    'week': '7 days',
    'month': '30 days',
    'all': 'Latest',
  };

  @override
  void initState() {
    super.initState();
    fetchAllData();
    startAutoRefresh();
  }

  @override
  Future<void> onAutoRefresh() => fetchAllData(silent: true);

  Future<void> fetchAllData({bool silent = false}) async {
    if (_inFlight) return;
    _inFlight = true;

    if (!silent) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final result = await _devices.getReadings(
        deviceId: widget.device.id,
        deviceKey: widget.device.deviceKey,
        channelKey: widget.channelKey,
        range: selectedRange,
        limit: selectedRange == 'all' ? 200 : 2000,
      );
      if (!mounted) return;
      setState(() {
        data = result;
        error = null;
        loading = false;
        lastUpdated = DateTime.now().toUtc();
        if (result.profile != null) profileId = result.profile!.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e;
        loading = false;
      });
    } finally {
      _inFlight = false;
    }
  }

  DeviceConnectivity get connectivity {
    DateTime? lastPayload = widget.lastPayloadAt;
    final latest = data?.latest?.timestamp;
    if (latest != null && (lastPayload == null || latest.isAfter(lastPayload))) {
      lastPayload = latest;
    }
    return DeviceConnectivity.evaluate(
      isActive: widget.device.isActive,
      lastSeen: widget.device.lastSeen,
      lastPayloadAt: lastPayload,
    );
  }

  bool get _channelNotMapped =>
      error is ApiException &&
      (error as ApiException).isNotFound &&
      (error as ApiException).message.toLowerCase().contains('channel');

  // ================= CHART DATA =================

  /// Readings with a numeric value, oldest first.
  List<DeviceReading> get chartReadings =>
      (data?.readings ?? const <DeviceReading>[])
          .where((r) => r.value != null)
          .toList();

  List<FlSpot> getSpots(List<DeviceReading> points) => [
        for (var i = 0; i < points.length; i++)
          FlSpot(i.toDouble(), points[i].value!),
      ];

  (double, double) getYRange(List<DeviceReading> points) {
    var minY = points.map((e) => e.value!).reduce(math.min);
    var maxY = points.map((e) => e.value!).reduce(math.max);
    final threshold = data?.threshold;
    if (data?.isCalibrated == true && threshold != null) {
      minY = math.min(minY, threshold);
      maxY = math.max(maxY, threshold);
    }
    final pad = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY) * 0.08;
    return (math.max(0, minY - pad).toDouble(), maxY + pad);
  }

  List<VerticalLine> getEventLines(List<DeviceReading> points) {
    final lines = <VerticalLine>[];
    for (var i = 0; i < points.length; i++) {
      final r = points[i];
      if (r.isRefill) {
        lines.add(VerticalLine(
            x: i.toDouble(), color: context.status.info, strokeWidth: 2));
      } else if (r.isLow) {
        lines.add(VerticalLine(
          x: i.toDouble(),
          color: context.status.danger.withValues(alpha: 0.5),
          strokeWidth: 1,
          dashArray: [4, 4],
        ));
      }
    }
    return lines;
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _inFlight ? null : () => fetchAllData(),
          ),
          if (widget.canManage)
            PopupMenuButton<String>(
              tooltip: 'Tank settings',
              onSelected: (value) {
                if (value == 'rename') _openRename();
                if (value == 'lookup') _openSetLookup();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Rename tank'),
                  ),
                ),
                PopupMenuItem(
                  value: 'lookup',
                  child: ListTile(
                    leading: Icon(Icons.table_chart_outlined),
                    title: Text('Set lookup table'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading && data == null) return const LoadingView();

    if (data == null && error != null) {
      if (_channelNotMapped) {
        return EmptyView(
          icon: Icons.label_off_outlined,
          title: 'No history for this channel yet',
          message: 'History is available once the channel has a name. '
              '${widget.canManage ? 'Give it a name to enable it.' : 'Ask the station owner or manager to name it.'}',
          action: widget.canManage ? _renameButton() : null,
        );
      }
      return ErrorView(error: error!, onRetry: () => fetchAllData());
    }

    final readings = data!;
    final points = chartReadings;
    final conn = connectivity;
    final latest = readings.latestValid;
    final percent =
        readings.isCalibrated ? readings.percentOf(latest?.value) : null;
    final thresholdPercent =
        readings.isCalibrated ? readings.percentOf(readings.threshold) : null;
    final valueUnit = readings.isCalibrated ? 'L' : unit;
    final live = conn.readingsAreLive;
    final faded = context.colors.onSurfaceVariant;

    return RefreshIndicator(
      onRefresh: () => fetchAllData(silent: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (error != null) ...[
            InfoBanner(
              icon: Icons.cloud_off_outlined,
              color: context.status.warning,
              message: 'Could not refresh: ${error.toString()}\n'
                  'Showing data loaded ${Fmt.ago(lastUpdated)}.',
            ),
            const SizedBox(height: 12),
          ],

          // ================= HERO =================
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ConnectivityBadge(conn),
                    const Spacer(),
                    if (latest != null &&
                        latest.status != ChannelStatus.unknown)
                      StatusPill(
                        label: latest.status.label,
                        color: channelStatusColor(context, latest.status),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: latest == null ? '—' : Fmt.number(latest.value),
                      style: context.text.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: live ? context.colors.onSurface : faded,
                      ),
                    ),
                    if (latest != null && valueUnit != null)
                      TextSpan(
                        text: ' $valueUnit',
                        style: context.text.titleLarge?.copyWith(color: faded),
                      ),
                  ]),
                ),
                if (percent != null) ...[
                  const SizedBox(height: 16),
                  TankLevelBar(
                    percent: percent,
                    thresholdPercent: thresholdPercent,
                    height: 14,
                    dimmed: !live,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${percent.toStringAsFixed(0)}% full',
                          style: context.text.labelLarge),
                      const Spacer(),
                      Text(
                        'of ${Fmt.withUnit(readings.maxCapacity, 'L')}',
                        style: context.text.labelMedium?.copyWith(color: faded),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  live
                      ? (latest == null
                          ? 'No readings in this period'
                          : 'Reading time ${Fmt.dateTime(latest.timestamp)}')
                      : conn.summary,
                  style: context.text.bodySmall?.copyWith(
                    color: live ? faded : context.status.warning,
                  ),
                ),
              ],
            ),
          ),

          // ================= DETAILS =================
          AppCard(
            child: Column(
              children: [
                InfoRow(
                    icon: Icons.sensors,
                    label: 'Channel',
                    value: widget.channelKey),
                InfoRow(
                    icon: Icons.memory,
                    label: 'Device',
                    value: widget.device.displayName),
                InfoRow(
                    icon: Icons.table_chart_outlined,
                    label: 'Lookup table',
                    value:
                        readings.profile?.name ?? 'None (raw values shown)'),
                if (readings.isCalibrated)
                  InfoRow(
                      icon: Icons.warning_amber_rounded,
                      label: 'Low alert',
                      value:
                          'Below ${Fmt.withUnit(readings.threshold, 'L')}'),
              ],
            ),
          ),

          // ================= TREND =================
          const SectionTitle('Trend'),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: rangeLabels.entries
                .map((e) =>
                    ButtonSegment<String>(value: e.key, label: Text(e.value)))
                .toList(),
            selected: {selectedRange},
            onSelectionChanged: (selection) {
              final value = selection.first;
              if (value == selectedRange) return;
              setState(() {
                selectedRange = value;
                data = null;
              });
              fetchAllData();
            },
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 260,
                  child: points.length < 2
                      ? Center(
                          child: Text(
                            points.isEmpty
                                ? 'No numeric readings in this period'
                                : 'Not enough readings to draw a trend',
                            style: context.text.bodyMedium
                                ?.copyWith(color: faded),
                          ),
                        )
                      : _chart(points),
                ),
                const SizedBox(height: 12),
                _legend(readings.isCalibrated),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${points.length} readings • updated ${Fmt.time(lastUpdated)}',
              style: context.text.labelSmall?.copyWith(color: faded),
            ),
          ),
          if (widget.canManage) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _renameButton()),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openSetLookup,
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Lookup table'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legend(bool calibrated) {
    Widget item(Widget mark, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: 6),
            Text(text,
                style: context.text.labelSmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        );

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        item(Container(width: 14, height: 3, color: context.colors.primary),
            calibrated ? 'Volume (L)' : 'Raw value'),
        item(Container(width: 2, height: 12, color: context.status.info),
            'Refill'),
        item(Container(width: 2, height: 12, color: context.status.danger),
            'Low level'),
        if (calibrated)
          item(Container(width: 14, height: 1, color: context.status.danger),
              'Alert threshold'),
      ],
    );
  }

  Widget _chart(List<DeviceReading> points) {
    final (minY, maxY) = getYRange(points);
    final threshold = data?.threshold;
    final showDates = selectedRange != 'day';
    final labelInterval = math.max(1, (points.length / 4).floor()).toDouble();
    final line = context.colors.primary;
    final axis = TextStyle(color: context.colors.onSurfaceVariant, fontSize: 10);
    final grid = context.colors.outlineVariant.withValues(alpha: 0.5);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: points.length.toDouble() - 1,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          verticalLines: getEventLines(points),
          horizontalLines: [
            if (data?.isCalibrated == true && threshold != null)
              HorizontalLine(
                y: threshold,
                color: context.status.danger,
                strokeWidth: 1,
                dashArray: [6, 4],
              ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => context.colors.inverseSurface,
            getTooltipItems: (spots) => spots.map((spot) {
              final r = points[spot.x.toInt()];
              return LineTooltipItem(
                '${Fmt.number(r.value)}\n${Fmt.dateTime(r.timestamp)}',
                TextStyle(
                    color: context.colors.onInverseSurface, fontSize: 11),
              );
            }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) =>
                  Text(Fmt.number(value, decimals: 0), style: axis),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: labelInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                final time = points[index].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    showDates ? Fmt.shortDay(time) : Fmt.time(time),
                    style: axis,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: getSpots(points),
            isCurved: true,
            preventCurveOverShooting: true,
            color: line,
            barWidth: 3,
            dotData: FlDotData(show: points.length <= 30),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  line.withValues(alpha: 0.25),
                  line.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renameButton() {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: _openRename,
      icon: const Icon(Icons.edit_outlined),
      label: const Text("Rename"),
    );
  }

  Future<void> _openRename() async {
    final result = await Navigator.push<ChannelLabelResult>(
      context,
      MaterialPageRoute(
        builder: (_) => EditSensorNameScreen(
          deviceId: widget.device.id,
          sensorKey: widget.channelKey,
          currentLabel: label,
          currentUnit: unit,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        label = result.label;
        unit = result.unit;
      });
      fetchAllData();
    }
  }

  Future<void> _openSetLookup() async {
    final assigned = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => SetCalibrationScreen(
          me: widget.me,
          deviceId: widget.device.id,
          activeCalibProfileId: profileId,
          stationId: widget.stationId,
          channelKey: widget.channelKey,
        ),
      ),
    );
    if (assigned != null && mounted) {
      setState(() => profileId = assigned);
      fetchAllData();
    }
  }
}
