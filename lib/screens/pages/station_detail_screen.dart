import 'package:flutter/material.dart';
import '../../models/fuel.dart';
import '../../models/gas_station.dart';
import 'tank_detail_screen.dart';
class StationDetailScreen extends StatelessWidget {
  final GasStation station;

  const StationDetailScreen({super.key, required this.station});

  // 🔥 FAKE TANK LEVEL LOGIC
  double getTankLevel(Fuel fuel) {
    if (fuel.fillAlert.toLowerCase() == "low") {
      return 0.2;
    }

    if (fuel.anticipatedDryUp.toLowerCase().contains("1")) {
      return 0.1;
    }

    return 0.7;
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
        title: Text(station.name),
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
              "Tanks (${station.fuels.length})",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: ListView.builder(
                itemCount: station.fuels.length,
                itemBuilder: (context, index) {
                  final fuel = station.fuels[index];

                  final level = getTankLevel(fuel);
                  final color = getTankColor(level);


                  return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TankDetailScreen(fuel: fuel),
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
                          fuel.name,
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
                          "Capacity: ${fuel.tankCapacity} L",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Avg Throughput: ${fuel.averageThroughput} L/hr",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Dry Up: ${fuel.anticipatedDryUp}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Fill Alert: ${fuel.fillAlert}",
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