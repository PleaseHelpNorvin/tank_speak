import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/tank.dart';
import '../../models/volume_reading.dart';

class TankDetailScreen extends StatefulWidget {
  final Tank tank;

  const TankDetailScreen({super.key, required this.tank});

  @override
  State<TankDetailScreen> createState() => _TankDetailScreenState();
}

class _TankDetailScreenState extends State<TankDetailScreen> {
  String selectedFilter = "Day";

  List<VolumeReading> getFilteredData() {
    final data = widget.tank.readings;
    final now = DateTime.now();

    return data.where((r) {
      final time = DateTime.tryParse(r.timeStamp);
      if (time == null) return false;

      if (selectedFilter == "Day") {
        return now.difference(time).inHours <= 24;
      }

      if (selectedFilter == "Week") {
        return now.difference(time).inDays <= 7;
      }

      if (selectedFilter == "Month") {
        return now.difference(time).inDays <= 30;
      }

      return true;
    }).toList();
  }

  List<FlSpot> getLineSpots(List<VolumeReading> data) {
    return List.generate(data.length, (index) {
      final volumeKL = data[index].volume / 1000;
      return FlSpot(index.toDouble(), volumeKL);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = getFilteredData();

    final maxY = data.isEmpty
        ? 1.0
        : data.map((e) => e.volume / 1000).reduce((a, b) => a > b ? a : b) * 1.2;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: Text("${widget.tank.productName} Analytics"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// FILTER
            Row(
              children: ["Day", "Week", "Month"].map((type) {
                final isSelected = selectedFilter == type;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(child: Text(type)),
                      selected: isSelected,
                      backgroundColor: Colors.white,
                      selectedColor: Colors.orange,
                      labelStyle: const TextStyle(color: Colors.black),
                      shape: const StadiumBorder(),
                      onSelected: (_) {
                        setState(() => selectedFilter = type);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            const Text(
              "Tank Volume (KL)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            /// CHART
            Expanded(
              child: data.isEmpty
                  ? const Center(
                child: Text(
                  "No readings available",
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,

                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),

                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: data.length > 5
                            ? (data.length / 5).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= data.length) {
                            return const SizedBox();
                          }

                          final date = DateTime.tryParse(
                              data[index].timeStamp);

                          return Text(
                            date == null
                                ? ""
                                : "${date.month}/${date.day}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxY / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "${value.toStringAsFixed(0)} KL",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),

                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: getLineSpots(data),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// INFO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tank Capacity: ${widget.tank.maxCapacity} L",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Product: ${widget.tank.productName}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Average Tank Throughput: ${widget.tank.currentVolume} L/day",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Anticipated Dry Up: ${widget.tank.status}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Text(
                        "Fill Alert: ",
                        style: TextStyle(color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.tank.status == "High"
                              ? Colors.red
                              : widget.tank.status == "Low"
                              ? Colors.orange
                              : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.tank.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// RESPONSIVE BUTTONS (FIXED OVERFLOW)
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 400;

                return isSmall
                    ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Alert cleared")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text("Clear Alert"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor:
                            const Color(0xFF1C2A2F),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Select Reason",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    ...[
                                      "Refill",
                                      "Maintenance",
                                      "Leak Check",
                                      "Manual Adjustment",
                                    ].map((reason) {
                                      return ListTile(
                                        title: Text(
                                          reason,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  "Reason: $reason selected"),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side:
                          const BorderSide(color: Colors.orange),
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          "Select Reason",
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ),
                  ],
                )
                    :

                Row(
                  children: [
                    /// 🔴 CLEAR ALERT
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Alert cleared")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: const FittedBox(
                          child: Text("Clear Alert"),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// 🟡 SELECT REASON
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF1C2A2F),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Select Reason",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    ...[
                                      "Refill",
                                      "Maintenance",
                                      "Leak Check",
                                      "Manual Adjustment",
                                    ].map((reason) {
                                      return ListTile(
                                        title: Text(
                                          reason,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Reason: $reason selected")),
                                          );
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: const FittedBox(
                          child: Text(
                            "Select Reason",
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}