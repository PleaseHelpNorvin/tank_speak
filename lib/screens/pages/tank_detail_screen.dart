import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/tank.dart';
import '../../services/api_service.dart';

class TankDetailScreen extends StatefulWidget {
  final String deviceId;
  final String sensorPin;
  final String productName;

  const TankDetailScreen({
    super.key,
    required this.deviceId,
    required this.sensorPin,
    required this.productName,
  });

  @override
  State<TankDetailScreen> createState() => _TankDetailScreenState();
}

class _TankDetailScreenState extends State<TankDetailScreen> {
  final ApiService api = ApiService();

  List<DeviceReading> readings = [];
  DeviceReading? latestReading;

  bool loading = false;
  bool fetching = false;

  String selectedRange = "day";
  final List<String> ranges = ["day", "week", "month"];

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchAllData();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) => fetchAllData(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAllData() async {
    if (fetching) return;
    fetching = true;

    if (readings.isEmpty) {
      setState(() => loading = true);
    }

    try {
      final history = await api.getDeviceReadings(
        deviceId: widget.deviceId,
        sensorPin: widget.sensorPin,
        limit: 100,
        range: selectedRange,
      );

      history.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (!mounted) return;

      setState(() {
        readings = history.length > 30
            ? history.sublist(history.length - 30)
            : history;

        latestReading = readings.isNotEmpty ? readings.last : null;
        loading = false;
      });
    } catch (e) {
      debugPrint("FETCH ERROR: $e");
      if (mounted) {
        setState(() => loading = false);
      }
    }

    fetching = false;
  }

  // ================= STATUS =================

  Color getStatusColor() {
    if (latestReading == null) return Colors.grey;

    final age = DateTime.now().difference(latestReading!.timestamp);

    if (age.inMinutes > 10) return Colors.red;
    if (latestReading!.liters < 1000) return Colors.orange;

    return Colors.green;
  }

  String getStatusLabel() {
    if (latestReading == null) return "No Data";

    final now = DateTime.now();
    final time = latestReading!.timestamp;

    final ageInMinutes = now.difference(time).inMinutes;

    if (ageInMinutes < 0) {
      // future timestamp fix (clock mismatch)
      return "Live";
    }

    if (ageInMinutes > 5) return "Offline"; // reduce threshold

    if (latestReading!.liters <= 0) return "No Flow";

    if (latestReading!.liters < 1000) return "Low";

    return "Normal";
  }

  // ================= CHART =================

  List<FlSpot> getSpots() {
    if (readings.isEmpty) return [];

    return readings.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.liters,
      );
    }).toList();
  }

  double getMaxY() {
    if (readings.isEmpty) return 1;

    final max = readings
        .map((e) => e.liters)
        .reduce((a, b) => a > b ? a : b);

    return max + 5;
  }

  double getMinY() {
    if (readings.isEmpty) return 0;

    final min = readings
        .map((e) => e.liters)
        .reduce((a, b) => a < b ? a : b);

    return (min - 5).clamp(0, double.infinity);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: Text(widget.productName),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAllData,
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // DEVICE INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Device: ${widget.deviceId}",
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text("Sensor: ${widget.sensorPin}",
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LIVE CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: latestReading == null
                  ? const Text("No data",
                  style: TextStyle(color: Colors.white))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        getStatusLabel(),
                        style: TextStyle(
                          color: getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "${latestReading!.liters.toStringAsFixed(1)} L",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 RANGE DROPDOWN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tank Trend",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRange,
                    dropdownColor: const Color(0xFF1C2C34),
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),

                    items: ranges.map((range) {
                      return DropdownMenuItem(
                        value: range,
                        child: Text(range.toUpperCase()),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedRange = value;
                        readings = [];
                        latestReading = null;
                      });

                      fetchAllData();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CHART
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              height: 260,
              child: readings.length < 2
                  ? const Center(
                child: Text(
                  "Not enough data",
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : LineChart(
                LineChartData(
                  minX: 0,
                  maxX: readings.length.toDouble() - 1,
                  minY: getMinY(),
                  maxY: getMaxY(),

                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),

                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 ||
                              index >= readings.length) {
                            return const SizedBox();
                          }

                          final time =
                              readings[index].timestamp;

                          return Text(
                            "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: getSpots(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: fetchAllData,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
      ),
    );
  }
}