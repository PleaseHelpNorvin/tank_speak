import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/ble_provision_service.dart';

class BleProvisionScreen extends StatefulWidget {
  const BleProvisionScreen({super.key});

  @override
  State<BleProvisionScreen> createState() => _BleProvisionScreenState();
}

class _BleProvisionScreenState extends State<BleProvisionScreen> {
  List<ScanResult> devices = [];
  StreamSubscription<List<ScanResult>>? scanSub;

  bool isScanning = false;
  String status = "Idle";

  final BleProvisionService ble = BleProvisionService();

  // ---------------- SCAN ----------------
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

  // ---------------- CONNECT ----------------
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

  // ---------------- BOTTOM SHEET ----------------
  void openDeviceSheet(ScanResult device) {
    final ssidController = TextEditingController();
    final passController = TextEditingController();

    bool provisioning = false;
    bool provisioningSuccess = false;

    String sheetStatus = "";
    String savedMac = "";
    String debugLog = ""; // 👈 ADD THIS

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

                  // 👇 SHOW MAC
                  if (savedMac.isNotEmpty)
                    Text(
                      "Saved Device MAC: $savedMac",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // 👇 DEBUG PANEL (VERY IMPORTANT)
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

                            setModalState(() {
                              sheetStatus = isConnected
                                  ? "Connected"
                                  : "Not Connected";
                            });

                            if (isConnected && !provisioningSuccess) {
                              provisioningSuccess = true;

                              log("Reading MAC...");

                              try {
                                await Future.delayed(
                                    const Duration(milliseconds: 300));

                                final mac =
                                await ble.readDeviceMac();

                                log("MAC READ: $mac");

                                final prefs =
                                await SharedPreferences.getInstance();

                                await prefs.setString("device_mac", mac);

                                setModalState(() {
                                  savedMac = mac;
                                  sheetStatus = "Saved MAC: $mac";
                                });

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

                        log("Sending SSID...");
                        await ble.sendSsid(ssidController.text);

                        log("Sending PASS...");
                        await ble.sendPassword(passController.text);
                      } catch (e) {
                        log("ERROR: $e");

                        setModalState(() {
                          sheetStatus = "Error: $e";
                        });
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
    });
  }

  @override
  void dispose() {
    scanSub?.cancel();
    ble.disconnect();
    super.dispose();
  }

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