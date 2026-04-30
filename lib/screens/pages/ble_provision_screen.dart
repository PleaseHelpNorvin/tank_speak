import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tank_speak/models/gas_station.dart';
import '../../services/ble_provision_service.dart';
import '../../services/api_service.dart';

class BleProvisionScreen extends StatefulWidget {
  final GasStation station;

  const BleProvisionScreen({super.key, required this.station});

  @override
  State<BleProvisionScreen> createState() => _BleProvisionScreenState();
}

class _BleProvisionScreenState extends State<BleProvisionScreen> {
  List<ScanResult> devices = [];
  StreamSubscription<List<ScanResult>>? scanSub;

  bool isScanning = false;
  String status = "Idle";

  String? savedMac; // 👈 IMPORTANT

  final BleProvisionService ble = BleProvisionService();

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    loadSavedMac();
  }

  Future<void> loadSavedMac() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString("device_mac_${widget.station.id}");

    if (!mounted) return;

    setState(() {
      savedMac = mac;
    });
  }

  // ================= SCAN =================
  Future<void> scan() async {
    setState(() {
      isScanning = true;
      devices.clear();
      status = "Scanning...";
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    scanSub?.cancel();

    scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() => devices = results);
    });

    await Future.delayed(const Duration(seconds: 5));
    await FlutterBluePlus.stopScan();

    if (!mounted) return;

    setState(() {
      isScanning = false;
      status = "Scan complete";
    });
  }

  // ================= CONNECT =================
  Future<void> connectAndOpenSheet(ScanResult device) async {
    setState(() => status = "Connecting...");

    final connected = await ble.connect(device);

    if (!mounted) return;

    if (!connected) {
      setState(() => status = "Connection failed");
      return;
    }

    setState(() => status = "Connected");

    openDeviceSheet(device);
  }

  // ================= REGISTER DEVICE =================
  Future<void> registerDevice() async {
    try {
      setState(() => status = "Registering device...");

      await ApiService().registerDevice(
        deviceId: savedMac!,
        stationId: widget.station.id,
      );

      setState(() => status = "Device Registered!");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device registered successfully")),
      );
    } catch (e) {
      setState(() => status = "Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  // ================= BOTTOM SHEET =================
  void openDeviceSheet(ScanResult device) {
    final ssidController = TextEditingController();
    final passController = TextEditingController();

    bool provisioning = false;
    bool provisioningSuccess = false;

    String sheetStatus = "";
    String debugLog = "";

    StreamSubscription? statusSub;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void log(String msg) {
              print(msg);
              setModalState(() {
                debugLog = "$msg\n$debugLog";
              });
            }

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
                  Text(
                    device.device.platformName.isEmpty
                        ? "Unknown Device"
                        : device.device.platformName,
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(8),
                    color: Colors.black,
                    child: SingleChildScrollView(
                      child: Text(
                        debugLog,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: ssidController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "SSID",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  TextField(
                    controller: passController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: provisioning
                        ? null
                        : () async {
                      setModalState(() => provisioning = true);

                      try {
                        log("Starting provisioning...");

                        await statusSub?.cancel();

                        statusSub = ble.listenStatus().listen(
                              (isConnected) async {
                            log("STATUS EVENT: $isConnected");

                            if (isConnected && !provisioningSuccess) {
                              provisioningSuccess = true;

                              try {
                                final mac =
                                await ble.readDeviceMac();

                                final prefs =
                                await SharedPreferences.getInstance();

                                await prefs.setString(
                                  "device_mac_${widget.station.id}",
                                  mac,
                                );

                                log("MAC SAVED: $mac");

                                Future.delayed(
                                  const Duration(seconds: 1),
                                      () => Navigator.pop(context),
                                );
                              } catch (e) {
                                log("MAC ERROR: $e");
                              }
                            }
                          },
                        );

                        await ble.sendSsid(ssidController.text);
                        await ble.sendPassword(passController.text);
                      } catch (e) {
                        log("ERROR: $e");
                      }

                      setModalState(() => provisioning = false);
                    },
                    child: Text(provisioning ? "Sending..." : "Provision"),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    sheetStatus,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() async {
      await statusSub?.cancel();

      if (!provisioningSuccess) {
        await ble.disconnect();
        setState(() => status = "Disconnected");
      }

      await loadSavedMac(); // 👈 refresh UI
    });
  }

  @override
  void dispose() {
    scanSub?.cancel();
    ble.disconnect();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: const Text("BLE Provision"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    savedMac == null
                        ? "Selected Device ID: None"
                        : "Selected Device ID: $savedMac",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),

                ElevatedButton(
                  onPressed: savedMac == null ? null : registerDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: isScanning ? null : scan,
              child: Text(isScanning ? "Scanning..." : "Scan Devices"),
            ),
          ),

          Text(status, style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];

                return Card(
                  color: const Color(0xFF1B2B34),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      d.device.name.isEmpty
                          ? "Unknown"
                          : d.device.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      d.device.remoteId.str,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () => connectAndOpenSheet(d),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}