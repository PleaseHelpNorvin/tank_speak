import 'package:flutter/material.dart';
import 'package:tank_speak/screens/pages/add_device_screen.dart';
import 'package:tank_speak/screens/pages/profile_screen.dart';
import 'package:tank_speak/screens/pages/tank_detail_screen.dart';
import '../../models/me_response.dart';
import '../../models/tank.dart';
import '../../services/api_service.dart';
import '../../models/invitation.dart';
import '../../models/gas_station.dart';
import 'ble_provision_screen.dart';
import 'calibration_list_screen.dart';
import 'create_calibration_profile_screen.dart';
import 'invitations_screen.dart';

class StationDetailScreen extends StatefulWidget {
  final GasStation station;
  final MeResponse me;

  const StationDetailScreen({super.key, required this.station, required this.me});

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
  Map<String, double> lastValues = {};

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

  Map<String, dynamic> getFuelState(Map<String, dynamic> sensorData) {
    final status = sensorData["status"] ?? "normal";

    switch (status) {
      case "dry_alert":
        return {
          "label": "DRY ALERT",
          "color": Colors.red,
        };

      case "refill_alert":
        return {
          "label": "REFILL ALERT",
          "color": Colors.blue,
        };

      case "no_profile":
        return {
          "label": "NO PROFILE",
          "color": Colors.orange,
        };

      case "no_data":
        return {
          "label": "NO DATA",
          "color": Colors.grey,
        };

      default:
        return {
          "label": "NORMAL",
          "color": Colors.green,
        };
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F2027),
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateCalibrationProfileScreen(me: widget.me),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: Center(
          child: Text(
            error ?? "Station data not available",
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final data = station!;

    // 🔥 NEW DEVICES
    final registeredDevices = data.devices;

    // 🔥 FIRST DEVICE PAYLOAD
    final firstDevice =
    registeredDevices.isNotEmpty ? registeredDevices.first : null;

    final payload = firstDevice?.latestPayload ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: Text(data.station.name),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
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

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ================= BUTTONS =================
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BleProvisionScreen(station: widget.station),
                          ),
                        );
                      },
                      icon: const Icon(Icons.precision_manufacturing),
                      label: const Text("Register Norvi"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openInviteManagerSheet(context, data.station);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text("Invite Manager"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CalibrationListScreen(me : widget.me),
                          ),
                        );
                      },
                      icon: const Icon(Icons.precision_manufacturing),
                      label: const Text("Manage Lookups"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),

                ]
              ),
              const SizedBox(height: 15),

    // ================= INFO =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _infoChip(data),
              ),

              const SizedBox(height: 20),

              // ================= SENSOR DATA =================
              if (payload.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sensor Data",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      onPressed: () async {
                        await loadStation();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Column(
                  children: payload.entries.map((e) {

                    final sensorData =
                    e.value as Map<String, dynamic>;

                    final value = double.tryParse(
                      sensorData["value"].toString(),
                    ) ?? 0;

                    final label =
                        sensorData["label"] ?? e.key;
                    final activeCalibProfile = sensorData["active_calibration_profile_id"];

                    final int? activeCalibProfileId = activeCalibProfile is int
                        ? activeCalibProfile
                        : int.tryParse(activeCalibProfile.toString());
                    debugPrint('activeCalibProfileId:  $activeCalibProfileId');
                    final status = getFuelState(sensorData);
                    debugPrint("label: $label");
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TankDetailScreen(
                                  me: widget.me,
                                  deviceId: firstDevice!.device.id,
                                  sensorPin: e.key,
                                  productName: label,
                                  deviceKey: firstDevice.device.deviceKey,
                                  activeCalibProfileId: activeCalibProfileId,
                                  stationId: widget.station.id,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [

                            const Icon(
                              Icons.sensors,
                              color: Colors.orange,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Text(
                                    "${e.key}: $value",
                                    style: TextStyle(
                                      color:
                                      Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (status["color"] as Color)
                                    .withOpacity(0.2),
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color: status["color"],
                                ),
                              ),
                              child: Text(
                                status["label"],
                                style: TextStyle(
                                  color: status["color"],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              // ================= REGISTERED DEVICES =================
              // const Text(
              //   "Registered Devices",
              //   style: TextStyle(
              //     color: Colors.orange,
              //     fontWeight: FontWeight.bold,
              //     fontSize: 16,
              //   ),
              // ),
              //
              // const SizedBox(height: 10),
              //
              // ListView.builder(
              //   itemCount: registeredDevices.length,
              //   shrinkWrap: true,
              //   physics: const NeverScrollableScrollPhysics(),
              //   itemBuilder: (context, index) {
              //     final item = registeredDevices[index];
              //     final device = item.device;
              //
              //     return Container(
              //       margin: const EdgeInsets.only(bottom: 14),
              //       padding: const EdgeInsets.all(16),
              //       decoration: BoxDecoration(
              //         color: Colors.white.withOpacity(0.08),
              //         borderRadius: BorderRadius.circular(16),
              //       ),
              //       child: Column(
              //         crossAxisAlignment:
              //         CrossAxisAlignment.start,
              //         children: [
              //
              //           Row(
              //             children: [
              //
              //               Icon(
              //                 getDeviceIcon(device.type),
              //                 color: Colors.white,
              //               ),
              //
              //               const SizedBox(width: 12),
              //
              //               Expanded(
              //                 child: Column(
              //                   crossAxisAlignment:
              //                   CrossAxisAlignment.start,
              //                   children: [
              //
              //                     Text(
              //                       device.name,
              //                       style: const TextStyle(
              //                         color: Colors.white,
              //                         fontWeight: FontWeight.bold,
              //                       ),
              //                     ),
              //
              //                     Text(
              //                       device.type,
              //                       style: TextStyle(
              //                         color: Colors.white
              //                             .withOpacity(0.7),
              //                       ),
              //                     ),
              //                   ],
              //                 ),
              //               ),
              //
              //               const Text(
              //                 "ACTIVE",
              //                 style: TextStyle(
              //                   color: Colors.green,
              //                 ),
              //               ),
              //             ],
              //           ),
              //
              //           const SizedBox(height: 10),
              //
              //           Text(
              //             "Device Key: ${device.deviceKey}",
              //             style: TextStyle(
              //               color:
              //               Colors.white.withOpacity(0.7),
              //             ),
              //           ),
              //
              //           const SizedBox(height: 5),
              //
              //           Text(
              //             "Payload Time: ${item.payloadCreatedAt ?? 'N/A'}",
              //             style: TextStyle(
              //               color:
              //               Colors.white.withOpacity(0.7),
              //               fontSize: 12,
              //             ),
              //           ),
              //         ],
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(StationDetailResponse data) {
    final station = data.station;
    final manager = data.manager;
    final owner = data.owner;
    final devices = data.devices;

    final StationDevice? firstDevice =
    devices.isNotEmpty ? devices.first : null;

    final device = firstDevice?.device;

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
            const SizedBox(width: 6),
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

    Widget section(List<Widget> children) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 3.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: children,
      );
    }

    Widget toggleHeader(String title,
        bool value,
        VoidCallback onTap,) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
              section([
                infoBox(station.name, Icons.local_gas_station),
                infoBox(station.phone, Icons.phone),
                infoBox(station.address, Icons.location_on),
                infoBox(station.businessHours, Icons.schedule),
              ]),

            // ================= MANAGER =================
            toggleHeader("MANAGER", showManager, () {
              setState(() => showManager = !showManager);
            }),

            const SizedBox(height: 5),

            if (showManager)
              section([
                infoBox(manager?.name ?? "N/A", Icons.person),
                infoBox(
                    manager?.username ?? "N/A", Icons.supervised_user_circle),
                infoBox(manager?.inviteCode ?? "N/A", Icons.code),
                infoBox(manager?.email ?? "N/A", Icons.email),
              ]),

            // ================= OWNER =================
            toggleHeader("OWNER", showOwner, () {
              setState(() => showOwner = !showOwner);
            }),

            const SizedBox(height: 5),

            if (showOwner)
              section([
                infoBox(owner?.name ?? "N/A", Icons.verified_user),
                infoBox(owner?.inviteCode ?? "N/A", Icons.person_outline),
                infoBox(owner?.email ?? "N/A", Icons.alternate_email),
              ]),

            // ================= DEVICE =================
            toggleHeader("REGISTERED DEVICE", showRegisteredDevice, () {
              setState(() => showRegisteredDevice = !showRegisteredDevice);
            }),

            const SizedBox(height: 5),

            if (showRegisteredDevice)
              section([
                infoBox(device?.name ?? "N/A", Icons.memory),
                infoBox(device?.deviceKey ?? "N/A", Icons.fingerprint),
                infoBox(device?.type ?? "N/A", Icons.device_hub),
                // infoBox(
                //   firstDevice?.device.isActive == true ? "ACTIVE" : "OFFLINE",
                //   Icons.power,
                // ),
              ]),
          ],
        );
      },
    );
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
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom + 20,
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
                        DropdownMenuItem(value: "manager", child: Text(
                            "Manager")),
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
                              child: const Icon(
                                  Icons.person, color: Colors.orange),
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
                                    style: const TextStyle(
                                        color: Colors.white54),
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
}
