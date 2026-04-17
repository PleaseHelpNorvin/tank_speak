import 'package:flutter/material.dart';
import '../../models/tank.dart';
import '../../services/api_service.dart';
import '../../models/invitation.dart';
import '../../models/gas_station.dart';

class StationDetailScreen extends StatefulWidget {
  final int stationId;

  const StationDetailScreen({super.key, required this.stationId});

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

  List<Map<String, dynamic>> getMockDevices() {
    return List.generate(10, (index) {
      return {
        "id": index,
        "name": "Device ${index + 1}",
        "type": index % 3 == 0
            ? "dispenser"
            : index % 3 == 1
            ? "flow_sensor"
            : "unknown",
        "isActive": index % 2 == 0,
        "lastSeen": "2026-04-17 10:${index}0 AM",
      };
    });
  }

  StationDetailResponse getMockStation() {
    return StationDetailResponse(
      station: GasStation(
        id: 12,
        name: "Mock Station 1",
        address: "Cebu City, Philippines",
        phone: "09123456789",
        businessHours: "8AM - 6PM",
        tanks: getMockDevices().map((e) => Device(
          id: e["id"].toString(),
          stationId: 12,
          name: e["name"],
          deviceKey: "mock-key-${e["id"]}",
          type: e["type"],
          isActive: e["isActive"],
          lastSeen: DateTime.tryParse(e["lastSeen"]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )).toList(),
      ),

      manager: {
        "id": 2,
        "name": "Mock Manager",
        "username": "manager_mock",
        "email": "manager@mock.com",
        "invite_code": "123456",
      },

      owner: {
        "id": 3,
        "name": "Mock Owner",
        "username": "owner_mock",
        "email": "owner@mock.com",
        "invite_code": "987654",
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadStation();
  }

  Future<void> loadStation() async {
    try {
      final result = useMock
          ? getMockStation()
          : await api.getStationById(widget.stationId);

      setState(() {
        station = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
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

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F2027),
        body: Center(
          child: Text(
            error!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final data = station!;
    final devices = data.station.tanks;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: Text(data!.station.name),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
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
              "Devices (${devices.length})",
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


    Widget infoBox(String value, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(10),
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.5,
            children: children,
          ),
        ],
      );
    }

    Widget toggleHeader(String title, bool value, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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


            const SizedBox(height: 10),

            if (showStationInfo)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.5,
                children: [
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
            const SizedBox(height: 10),

            if (showManager)
              section("MANAGER DETAILS", [
                infoBox(" ${manager["name"]}", Icons.person),
                infoBox(" ${manager["username"]}", Icons.badge),
                infoBox(" ${manager["email"]}", Icons.email),
                infoBox(" ${manager["invite_code"]}", Icons.key),
              ]),


            // ================= OWNER =================
            toggleHeader("OWNER", showOwner, () {
              setState(() => showOwner = !showOwner);
            }),
            const SizedBox(height: 10),

            if (showOwner)
              section("OWNER DETAILS", [
                infoBox(" ${owner["name"]}", Icons.verified_user),
                infoBox(" ${owner["username"]}", Icons.person_outline),
                infoBox(" ${owner["email"]}", Icons.alternate_email),
                infoBox(" ${owner["invite_code"]}", Icons.key),
              ]),
          ],
        );
      },
    );
  }
}

void _openInviteManagerSheet(BuildContext context,  GasStation station) {
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

      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
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
                  onChanged: (value) {
                    setState(() {
                      foundUser = null;
                      isInvited = false;
                    });
                  },
                  onSubmitted: (value) async {
                    if (value.isEmpty) return;

                    setState(() => isSearching = true);

                    try {
                      final result =
                      await ApiService().searchInvitation(value);

                      setState(() {
                        foundUser = result;
                        isInvited = false;
                      });
                    } finally {
                      setState(() => isSearching = false);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Enter invite code",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

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
                              Text(foundUser!.username,
                                  style: const TextStyle(color: Colors.white)),
                              Text(foundUser!.email,
                                  style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: isInvited
                              ? null
                              : () async {
                            await ApiService().sendInvite(
                              code: foundUser!.inviteCode,
                              role: selectedRole,
                              stationId: station.id,
                            );

                            setState(() => isInvited = true);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Invited ${foundUser!.username}",
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            isInvited
                                ? Icons.check
                                : Icons.person_add_alt_1,
                            color: isInvited ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}