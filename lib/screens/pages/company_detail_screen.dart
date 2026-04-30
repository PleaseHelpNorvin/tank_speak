import 'package:flutter/material.dart';
import 'package:tank_speak/screens/pages/create_gas_station_screen.dart';
import 'package:tank_speak/screens/pages/profile_screen.dart';
import 'package:tank_speak/screens/pages/station_detail_screen.dart';
import '../../models/company.dart';
import '../../models/gas_station.dart';
import '../../models/me_response.dart';
import '../../services/api_service.dart';
import 'ble_provision_screen.dart';
import 'invitations_screen.dart';

class CompanyDetailScreen extends StatefulWidget {
  final int companyId;
  final MeResponse me;

  const CompanyDetailScreen({
    super.key,
    required this.companyId,
    required this.me
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  final ApiService api = ApiService();

  Company? company;
  List<GasStation> stations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCompany();
  }

  Future<void> loadCompany() async {
    try {
      final response = await api.getCompanyById(widget.companyId);

      setState(() {
        company = response.company;
        stations = response.stations;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text("Company Details"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
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
                  builder: (_) => ProfileScreen(me: widget.me),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGasStationScreen(me: widget.me, companyId: widget.companyId,),
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
          : company == null
          ? const Center(
        child: Text(
          "Company not found",
          style: TextStyle(color: Colors.white),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= COMPANY CARD =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    company!.address,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Phone: ${company!.phone}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Business Hours: ${company!.businessHours}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Extended: ${company!.extendedBusinessHours}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= STATIONS HEADER =================
            const Text(
              "Stations",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ================= STATION LIST =================
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];

                return Card(
                  color: Colors.white.withOpacity(0.06),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(
                      station.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.address,
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                        Text(
                          station.phone,
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StationDetailScreen(station: station),
                        ),
                      );
                    },


                    // 👇 ACTION BUTTONS
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // REGISTER DEVICE
                        IconButton(
                          icon: const Icon(Icons.devices, color: Colors.green),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BleProvisionScreen(station: station),
                              ),
                            );
                            print("Register device ${station.id}");
                          },
                        ),

                        // EDIT
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            print("Edit ${station.id}");
                          },
                        ),

                        // DELETE
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            print("Delete ${station.id}");
                          },
                        ),


                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}