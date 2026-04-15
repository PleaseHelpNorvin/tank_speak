import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../services/ble_provision_service.dart';
import 'dart:async';

class BleProvisionScreen extends StatefulWidget {
  const BleProvisionScreen({super.key});

  @override
  State<BleProvisionScreen> createState() => _BleProvisionScreenState();
}

class _BleProvisionScreenState extends State<BleProvisionScreen> {
  final BleProvisionService ble = BleProvisionService();

  List<ScanResult> devices = [];
  StreamSubscription<List<ScanResult>>? scanSub;
  StreamSubscription<String>? statusSub;
  bool isScanning = false;
  String status = "";

  /// ---------------- SCAN ----------------
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

  /// ---------------- DEVICE TAP -> BOTTOM SHEET ----------------
  void openDeviceSheet(ScanResult device) {
    final ssidController = TextEditingController();
    final passController = TextEditingController();

    bool connecting = false;
    bool provisioning = false;
    String sheetStatus = "";

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

                  /// DEVICE HEADER
                  Text(
                    device.device.name.isEmpty
                        ? "Unknown Device"
                        : device.device.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    device.device.remoteId.str,
                    style: const TextStyle(color: Colors.white54),
                  ),

                  const SizedBox(height: 16),

                  /// CONNECT BUTTON
                  ElevatedButton(
                    onPressed: connecting
                        ? null
                        : () async {
                      setModalState(() => connecting = true);

                      try {
                        await ble.connect(device);
                        setModalState(() {
                          sheetStatus = "Connected ";
                        });
                      } catch (e) {
                        setModalState(() {
                          sheetStatus = "Connection failed  $e";
                        });
                      }

                      setModalState(() => connecting = false);
                    },
                    child: Text(connecting ? "Connecting..." : "Connect"),
                  ),

                  const SizedBox(height: 12),

                  /// WIFI FIELDS
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
                    decoration: const InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    obscureText: true,
                  ),

                  const SizedBox(height: 12),

                  /// PROVISION BUTTON
                  ElevatedButton(
                    onPressed: provisioning
                        ? null
                        : () async {
                      setModalState(() => provisioning = true);

                      try {
                        await ble.sendSsid(ssidController.text);
                        await ble.sendPassword(passController.text);

                        // ❌ cancel old listener if exists
                        await statusSub?.cancel();

                        // ✅ listen LIVE status from ESP32
                        statusSub = ble.listenStatus().listen((result) {
                          setModalState(() {
                            sheetStatus = result; // raw ESP32 message
                          });
                        });

                      } catch (e) {
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
    );
  }

  @override
  void dispose() {
    scanSub?.cancel();
    statusSub?.cancel();
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

          /// SCAN BUTTON
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: isScanning ? null : scan,
              child: Text(isScanning ? "Scanning..." : "Scan Devices"),
            ),
          ),

          /// STATUS
          Text(status, style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 10),

          /// DEVICE LIST
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];

                return Card(
                  color: const Color(0xFF1B2B34),
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      d.device.name.isEmpty ? "Unknown" : d.device.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      d.device.remoteId.str,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () => openDeviceSheet(d),
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