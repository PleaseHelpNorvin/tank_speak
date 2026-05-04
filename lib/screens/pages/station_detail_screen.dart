import 'package:flutter/material.dart';
import 'package:tank_speak/screens/pages/add_device_screen.dart';
import '../../models/tank.dart';
import '../../services/api_service.dart';
import '../../models/invitation.dart';
import '../../models/gas_station.dart';
import 'ble_provision_screen.dart';

class StationDetailScreen extends StatefulWidget {
  final GasStation station;

  const StationDetailScreen({super.key, required this.station});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {


  final ApiService api = ApiService();

  StationDetailResponse? station;
  bool isLoading = true;
  String? error;
  final bool useMock = false;
  bool showManager = false;
  bool showOwner = false;
  bool showStationInfo = true;
  bool showRegisteredDevice = false;

  @override
  void initState() {
    super.initState();
    loadStation();
  }

  Future<void> loadStation() async {
    try {
      final result = await api.getStationById(widget.station.id);

      setState(() {
        station = result;
        isLoading = false;
        error = null;
      });

    } catch (e) {
      String message = "Something went wrong";

      // 🔥 Try to extract backend message
      if (e.toString().contains("Station not Found")) {
        message = "You're not a member of this station";
      } else if (e.toString().contains("404")) {
        message = "Station not found";
      }

      setState(() {
        error = message;
        isLoading = false;
      });
    }
  }

  // ================= UI HELPERS =================

  Color getStatusColor(bool isActive) {
    return isActive ? Colors.green : Colors.red;
  }

  IconData getDeviceIcon(String type) {
    switch (type) {
      case "dispenser":
        return Icons.local_gas_station;
      case "flow_sensor":
        return Icons.sensors;
      default:
        return Icons.memory;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F2027),
        body: Center(child: CircularProgressIndicator()),
      );
    }


    if (error != null || station == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F2027),
        appBar: AppBar(
          title: Text(widget.station.name),
          backgroundColor: const Color(0xFF0F2027),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            error == "Station not found"
                ? "You're not a member of this station"
                : error ?? "Station data not available",
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final data = station;
    final devices = station?.station.tanks ?? [];


    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: Text(data!.station.name),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDeviceScreen(station: station!.station, devices: devices,maxDevicesPerStation: 6),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= STATION INFO =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoChip(data),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= INVITE BUTTON =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BleProvisionScreen(station: widget.station),
                    ),
                  );
                  // _openInviteManagerSheet(context, data.station);
                },
                icon: const Icon(Icons.precision_manufacturing),
                label: const Text("Register Norvi"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openInviteManagerSheet(context, data.station);
                },
                icon: const Icon(Icons.person_add),
                label: const Text("Invite Manager"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Norvi Sensors (${devices.length})",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // ================= DEVICE LIST =================
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];

                  final isActive = device.isActive;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: getStatusColor(isActive).withOpacity(0.5),
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
                                color: getStatusColor(isActive)
                                    .withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                getDeviceIcon(device.type),
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
                                    device.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    device.type,
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
                                color: getStatusColor(isActive)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? "ACTIVE" : "OFFLINE",
                                style: TextStyle(
                                  color: getStatusColor(isActive),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Last Seen: ${device.lastSeen}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _infoChip(StationDetailResponse data) {
    final station = data.station;
    final manager = data.manager;
    final owner = data.owner;
    final norvi = data.norvi;


    Widget infoBox(String value, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 16),

            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    Widget section(String title, List<Widget> children) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 3.5,

            // 🔥 IMPORTANT FIXES
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: children,
          ),
        ],
      );
    }

    Widget toggleHeader(String title, bool value, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              Icon(
                value ? Icons.expand_less : Icons.expand_more,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= STATION =================
            toggleHeader("STATION INFO", showStationInfo, () {
                setState(() => showStationInfo = !showStationInfo);
              }),


            const SizedBox(height: 5),

            if (showStationInfo)
              section(
                "Station Info",
                [
                  infoBox(" ${station.name}", Icons.local_gas_station),
                  infoBox(" ${station.phone}", Icons.phone),
                  infoBox(" ${station.address}", Icons.location_on),
                  infoBox(" ${station.businessHours}", Icons.schedule),
                ],
              ),


            // ================= MANAGER =================
            toggleHeader("MANAGER", showManager, () {
              setState(() => showManager = !showManager);
            }),
            const SizedBox(height: 5),

            if (showManager)
              section("MANAGER DETAILS", [
                infoBox(" ${manager?.name ?? "N/A"}", Icons.person),
                infoBox(" ${manager?.username ?? "N/A"}", Icons.supervised_user_circle),
                infoBox(" ${manager?.inviteCode ?? "N/A"}", Icons.code),
                infoBox(" ${manager?.email ?? "N/A"}", Icons.email),

              ]),


            // ================= OWNER =================
            toggleHeader("OWNER", showOwner, () {
              setState(() => showOwner = !showOwner);
            }),
            const SizedBox(height: 5),

            if (showOwner)
              section("OWNER DETAILS", [
                infoBox(" ${owner?.name ?? "N/A"}", Icons.verified_user),
                infoBox(" ${owner?.inviteCode ?? "N/A"}", Icons.person_outline),
                infoBox(" ${owner?.email ?? "N/A"}", Icons.alternate_email),
                infoBox(" ${owner?.inviteCode ?? "N/A"}", Icons.key),
              ]),

            toggleHeader("REGISTERED DEVICE", showRegisteredDevice, () {
              setState(() => showRegisteredDevice = !showRegisteredDevice);
            }),
            const SizedBox(height: 5),

            if (showRegisteredDevice)
              section("REGISTERED DEVICE", [
                infoBox(" ${norvi?.name ?? "N/A"}", Icons.memory),
                infoBox(" ${norvi?.deviceKey ?? "N/A"}", Icons.fingerprint),
                infoBox(" ${norvi?.type ?? "N/A"}", Icons.device_hub),
                infoBox(
                  norvi?.isActive == true ? "ACTIVE" : "OFFLINE",
                  Icons.power,
                ),
              ]),
          ],
        );
      },
    );
  }
}

void _openInviteManagerSheet(BuildContext context, GasStation station) {
  final controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0F2027),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      Invitation? foundUser;
      bool isSearching = false;
      bool isInvited = false;
      String selectedRole = "manager";

      Future<void> searchUser(String value, StateSetter setState) async {
        if (value.isEmpty) return;

        setState(() => isSearching = true);

        try {
          final result = await ApiService().searchInvitation(value);

          setState(() {
            foundUser = result;
            isInvited = false;
          });

          // 🔥 If already invited (backend flag)
          if (result.invited) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("User already invited"),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          setState(() {
            foundUser = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invite code not found"),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          setState(() => isSearching = false);
        }
      }

      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Invite Manager",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ================= INPUT =================
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) {
                      setState(() {
                        foundUser = null;
                        isInvited = false;
                      });
                    },
                    onSubmitted: (value) => searchUser(value, setState),
                    decoration: InputDecoration(
                      hintText: "Enter invite code",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.orange),
                        onPressed: () =>
                            searchUser(controller.text, setState),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),

                  const SizedBox(height: 10),

                  // ================= ROLE =================
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: const Color(0xFF0F2027),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: "owner", child: Text("Owner")),
                      DropdownMenuItem(value: "manager", child: Text("Manager")),
                    ],
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                  ),

                  const SizedBox(height: 16),

                  // ================= RESULT =================
                  if (foundUser != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.2),
                            child: const Icon(Icons.person, color: Colors.orange),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  foundUser!.username,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  foundUser!.email,
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            onPressed: (isInvited || foundUser!.invited)
                                ? null
                                : () async {
                              try {
                                await ApiService().sendInvite(
                                  code: foundUser!.inviteCode,
                                  role: selectedRole,
                                  stationId: station.id,
                                  companyId: station.companyId,
                                );

                                setState(() => isInvited = true);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Invited ${foundUser!.username}",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to send invite"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              (isInvited || foundUser!.invited)
                                  ? Icons.check
                                  : Icons.person_add_alt_1,
                              color: (isInvited || foundUser!.invited)
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

