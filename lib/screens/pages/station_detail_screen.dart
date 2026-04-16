import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/tank.dart';
import '../../models/gas_station.dart';
import 'tank_detail_screen.dart';
class StationDetailScreen extends StatelessWidget {
  final GasStation station;

  const StationDetailScreen({super.key, required this.station});

  // 🔥 FAKE TANK LEVEL LOGIC
  double getTankLevel(Tank tank) {
    if (tank.maxCapacity <= 0) return 0.0;

    final level = tank.currentVolume / tank.maxCapacity;

    if (level < 0) return 0.0;
    if (level > 1) return 1.0;

    return level;
  }

  // COLOR LOGIC
  Color getTankColor(double level) {
    if (level <= 0.25) return Colors.red;
    if (level <= 0.5) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: Text(station.companyName),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              station.address,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Tanks (${station.tanks.length})",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: ListView.builder(
                itemCount: station.tanks.length,
                itemBuilder: (context, index) {
                  final tank = station.tanks[index];

                  final level = getTankLevel(tank);
                  final color = getTankColor(level);


                  return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TankDetailScreen(tank: tank),
                          ),
                        );
                      },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ⛽ NAME
                        Text(
                          tank.productName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 🔥 VISUAL BAR (THIS WAS MISSING)
                        LinearProgressIndicator(
                          value: level,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 10,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "${(level * 100).toStringAsFixed(0)}% remaining",
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (level <= 0.25)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              "⚠ LOW TANK WARNING",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        // DETAILS
                        Text(
                          "Capacity: ${tank.maxCapacity} L",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Avg Throughput: ${tank.length} L/hr",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Dry Up: ${tank.currentVolume}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Fill Alert: ${tank.status}",
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}