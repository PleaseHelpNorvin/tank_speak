import 'package:flutter/material.dart';
import 'package:tank_speak/screens/pages/invitations_screen.dart';
import 'package:tank_speak/screens/pages/station_detail_screen.dart';
import '../../models/me_response.dart';
import 'create_gas_station_screen.dart';
import 'profile_screen.dart';
import '../../services/api_service.dart';
import '../../models/gas_station.dart';
import '../../widgets/pagination_bar.dart';

class HomeScreen extends StatefulWidget {
  final MeResponse me;

  const HomeScreen({super.key, required this.me});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();

  List<GasStation> stations = [];
  bool isLoading = true;

  int currentPage = 1;
  int pageSize = 10;
  int total = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData({int page = 1}) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await api.fetchStations(page: page);

      setState(() {
        stations = response.items;
        currentPage = response.page;
        total = response.total;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ================= STATUS UI =================
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
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text("Gas Stations"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.mail),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvitationsScreen(me: widget.me),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>  ProfileScreen(me: widget.me,),
                ),
              );
            },
          ),
        ],
      ),

      // ================= FLOATING BUTTON =================
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGasStationScreen(me: widget.me),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      // ================= BODY =================
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      )
          : Column(
        children: [
          // ================= PAGINATION =================
          PaginationBar(
            currentPage: currentPage,
            total: total,
            pageSize: pageSize,
            onPrev: () => loadData(page: currentPage - 1),
            onNext: () => loadData(page: currentPage + 1),
          ),

          // ================= LIST =================
          Expanded(
          child: RefreshIndicator(
          color: Colors.orange,
            onRefresh: () async {
            await loadData(page: currentPage);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                final status = "normal"; // temporary

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text("Tapped! Navigation not ready yet."),
                      //     duration: Duration(milliseconds: 800),
                      //   ),
                      // );

                      // TODO: enable later
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StationDetailScreen(station: station),
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
                          // HEADER
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status)
                                      .withOpacity(0.15),
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
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      station.name,
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
                                        color:
                                        Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status)
                                      .withOpacity(0.2),
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

                          // INFO ROW
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              _infoBox("Manager", station.name,
                                  Icons.person),
                              _infoBox("Contact", station.phone,
                                  Icons.phone),
                              _infoBox("Hours",
                                  station.businessHours,
                                  Icons.access_time),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ),
        ],
      ),
    );
  }
}
