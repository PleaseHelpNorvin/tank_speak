import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tank_speak/screens/pages/set_calibration_screen.dart';

import '../../models/me_response.dart';
import '../../models/tank.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

import 'edit_sensor_name.dart';

class TankDetailScreen extends StatefulWidget {
  final MeResponse me;
  final String deviceId;
  final String sensorPin;
  final String productName;
  final String deviceKey;
  final int? activeCalibProfileId;
  final int stationId;
  const TankDetailScreen({
    super.key,
    required this.me,
    required this.deviceId,
    required this.sensorPin,
    required this.productName,
    required this.deviceKey,
    required this.activeCalibProfileId,
    required this.stationId,
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

  String selectedRange = "all";

  final List<String> ranges = [
    "all",
    "week",
    "month",
  ];

  Timer? refreshTimer;
  String formatTime(DateTime? time) {
    if (time == null) return "-";
    return DateFormat('MMM dd, yyyy • hh:mm a').format(time);
  }

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

  // ================= FETCH =================

  Future<void> fetchAllData() async {
    if (fetching) return;

    fetching = true;

    if (readings.isEmpty) {
      setState(() => loading = true);
    }
    try {
      final history = await api.getDeviceReadings(
        deviceId: widget.deviceKey,
        sensorPin: widget.sensorPin,
        limit: 100,
        range: selectedRange,
      );
      // sort oldest -> newest
      history.sort(
            (a, b) => a.timestamp.compareTo(b.timestamp),
      );

      if (!mounted) return;

      setState(() {
        readings = history.length > 30
            ? history.sublist(history.length - 30)
            : history;

        latestReading = readings.isNotEmpty
            ? readings.last
            : null;

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
    if (latestReading == null) {
      return Colors.grey;
    }

    final age = DateTime.now()
        .difference(latestReading!.timestamp);

    debugPrint("NOW: ${DateTime.now()}");
    debugPrint("READING: ${latestReading!.timestamp}");
    debugPrint("AGE MINUTES: ${age.inMinutes}");
    if (age.inMinutes > 5) {
      return Colors.red;
    }

    switch (latestReading!.status) {
      case "dry_alert":
        return Colors.orange;

      case "normal":
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  String getStatusLabel() {
    if (latestReading == null) {
      return "No Data";
    }

    final age = DateTime.now()
        .difference(latestReading!.timestamp);

    if (age.inMinutes > 5) {
      return "Offline";
    }

    if (latestReading!.refillAlert) {
      return "Refill Alert";
    }

    switch (latestReading!.status) {
      case "dry_alert":
        return "Dry Alert";

      case "normal":
        return "Normal";

      default:
        return "Unknown";
    }
  }

  // ================= CHART =================

  List<FlSpot> getSpots() {
    if (readings.isEmpty) {
      return [];
    }

    return readings.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.liters,
      );
    }).toList();
  }

  double getMaxY() {
    if (readings.isEmpty) {
      return 1;
    }

    final max = readings
        .map((e) => e.liters)
        .reduce((a, b) => a > b ? a : b);

    return max + (max * 0.05);
  }

  double getMinY() {
    if (readings.isEmpty) {
      return 0;
    }

    final min = readings
        .map((e) => e.liters)
        .reduce((a, b) => a < b ? a : b);

    return (min - (min * 0.05))
        .clamp(0, double.infinity);
  }

  List<VerticalLine> getEventLines() {
    List<VerticalLine> lines = [];

    for (int i = 0; i < readings.length; i++) {
      final r = readings[i];

      if (r.status == "dry_alert") {
        lines.add(
          VerticalLine(
            x: i.toDouble(),
            color: Colors.orange,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        );
      }

      if (r.event == "refill") {
        lines.add(
          VerticalLine(
            x: i.toDouble(),
            color: Colors.blue,
            strokeWidth: 2,
          ),
        );
      }
    }

    return lines;
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
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.orange,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

// ================= DEVICE INFO =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // LEFT SIDE (TEXT INFO)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const SizedBox(height: 6),

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
                                color:
                                getStatusColor(),
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        Text(
                          "${latestReading?.liters.toStringAsFixed(1) ?? "---"} L",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // 👇 THIS WILL NOW WRAP PROPERLY
                        Text(
                          "Updated: ${formatTime(latestReading?.timestamp)}",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                          softWrap: true,
                        ),


                      ],
                    ),
                  ),

                  // RIGHT SIDE (BUTTONS)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(120, 35),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditSensorNameScreen(
                                deviceId: widget.deviceId,   // IMPORTANT: must be INT ID (1,2,3)
                                sensorKey: widget.sensorPin, // A0, A3, etc
                                currentLabel: widget.productName, // replace with real label if you have it
                              ),
                            ),
                          );

                          if (result == true) {
                            fetchAllData(); // refresh UI after save
                          }
                        },
                        child: const Text("Change Name"),
                      ),

                      const SizedBox(height: 8),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(120, 35),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SetCalibrationScreen(me: widget.me, activeCalibProfileId: widget.activeCalibProfileId, stationId: widget.stationId, channelKey: widget.sensorPin,),
                            ),
                          );
                        },
                        child: const Text("Set Lookup"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.show_chart, color: Colors.orange, size: 14),
                      SizedBox(width: 6),
                      Text("Orange dashed line = Dry Alert",
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.vertical_align_center, color: Colors.blue, size: 14),
                      SizedBox(width: 6),
                      Text("Blue line = Refill Alert",
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ================= HEADER =================

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

              children: [

                const Text(
                  "Tank Trend",

                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),

                  decoration: BoxDecoration(
                    color:
                    Colors.white.withOpacity(0.08),

                    borderRadius:
                    BorderRadius.circular(10),
                  ),

                  child: DropdownButton<String>(
                    value: selectedRange,

                    dropdownColor:
                    const Color(0xFF1C2C34),

                    underline: const SizedBox(),

                    style: const TextStyle(
                      color: Colors.white,
                    ),

                    items: ranges.map((range) {
                      return DropdownMenuItem(
                        value: range,
                        child: Text(
                          range.toUpperCase(),
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

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

            // ================= CHART =================

            Container(
              height: 450,

              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),

                borderRadius:
                BorderRadius.circular(16),
              ),

              child: readings.length < 2
                  ? const Center(
                child: Text(
                  "Not enough data",

                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              )
                  : LineChart(
                LineChartData(
                  minX: 0,

                  maxX:
                  readings.length.toDouble() - 1,

                  minY: getMinY(),
                  maxY: getMaxY(),

                  gridData:
                  const FlGridData(show: true),

                  borderData:
                  FlBorderData(show: false),

                  extraLinesData: ExtraLinesData(
                    verticalLines: getEventLines(),
                  ),

                  titlesData: FlTitlesData(

                    rightTitles:
                    const AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: false,
                      ),
                    ),

                    topTitles:
                    const AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: false,
                      ),
                    ),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,

                        reservedSize: 42,

                        getTitlesWidget:
                            (value, meta) {
                          return Text(
                            value
                                .toInt()
                                .toString(),

                            style:
                            const TextStyle(
                              color:
                              Colors.white54,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),

                    bottomTitles:
                    AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: true,

                        interval: 5,

                        getTitlesWidget:
                            (value, meta) {

                          final index =
                          value.toInt();

                          if (index < 0 ||
                              index >=
                                  readings.length) {
                            return const SizedBox();
                          }

                          final time =
                              readings[index]
                                  .timestamp;

                          return Text(
                            selectedRange == "all"
                                ? "${time.hour}:${time.minute.toString().padLeft(2, '0')}"
                                : "${time.month}/${time.day}",

                            style:
                            const TextStyle(
                              color:
                              Colors.white54,
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

                      dotData:
                      const FlDotData(
                        show: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}