import 'package:flutter/material.dart';
import 'create_gas_station_screen.dart';
import 'station_detail_screen.dart';
import 'profile_screen.dart';
import '../../services/api_service.dart';
import '../../models/gas_station.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();
  List<GasStation> stations = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    stations = await api.fetchStations();
    setState(() {});
  }

  // 🔥 STATUS LOGIC (temporary mock rules)
  String getStatus(GasStation station) {
    if (station.tanks.isEmpty) return "normal";

    final tank = station.tanks.first;

    final fillPercent = tank.currentVolume / tank.maxCapacity;

    if (fillPercent <= 0.15) {
      return "dry";
    }

    if (fillPercent >= 0.85) {
      return "fill";
    }

    return "normal";
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "dry":
        return Colors.red;
      case "fill":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case "dry":
        return Icons.warning_amber_rounded;
      case "fill":
        return Icons.local_gas_station;
      default:
        return Icons.check_circle;
    }
  }

  // 🧩 INFO BOX WIDGET
  Widget _infoBox(String title, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateGasStationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      backgroundColor: const Color(0xFF0F2027),

      // 🔥 APP BAR
      appBar: AppBar(
        title: Text("Gas Stations"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,

        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: stations.isEmpty
          ? const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          final status = getStatus(station);

          return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StationDetailScreen(station: station),
                    ),
                  );
                },
                child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: getStatusColor(status).withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 HEADER
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: getStatusColor(status).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_gas_station,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.companyName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                station.address,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 🔥 STATUS BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                            getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: getStatusColor(status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                    ),

                    const SizedBox(height: 15),

                    // 🔥 INFO GRID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoBox(
                          "Manager",
                          station.areaManager.name,
                          Icons.person,
                        ),
                        _infoBox(
                          "Contact",
                          station.areaManager.contactInfo,
                          Icons.phone,
                        ),
                        _infoBox(
                          "Hours",
                          station.businessHours,
                          Icons.access_time,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}