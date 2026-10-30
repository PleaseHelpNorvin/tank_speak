import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tank_speak/models/gas_station.dart';
import '../../services/ble_provision_service.dart';
import '../../services/device_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';

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
    final mac = savedMac;
    if (mac == null ||
        mac.isEmpty ||
        mac == "EMPTY_MAC" ||
        mac == "READ_ERROR") {
      setState(() => status = "No valid device ID. Provision the device again.");
      return;
    }

    try {
      setState(() => status = "Registering device...");

      final result = await DeviceService().registerDevice(
        deviceKey: mac,
        stationId: widget.station.id,
      );

      if (!mounted) return;
      setState(() => status = "Device Registered!");
      showSuccess(context, result.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => status = "Registration failed: $e");
      showError(context, e);
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
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    device.device.platformName.isEmpty
                        ? "Unknown Device"
                        : device.device.platformName,
                    style: context.text.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Send the station's Wi-Fi details to the device.",
                    style: context.text.bodyMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    height: 110,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1220),
                      borderRadius: BorderRadius.circular(Brand.radiusSmall),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        debugLog,
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: ssidController,
                    decoration: const InputDecoration(
                      labelText: "Wi-Fi name (SSID)",
                      prefixIcon: Icon(Icons.wifi),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Wi-Fi password",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),

                  const SizedBox(height: 20),

                  FilledButton(
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
                    style: context.text.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
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
    final mac = savedMac;
    return Scaffold(
      appBar: AppBar(title: const Text("Add device")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _step(
            1,
            "Find the Norvi controller",
            "Power the device on and keep the phone close to it.",
          ),
          _step(
            2,
            "Connect and send Wi-Fi",
            "Tap the device below and enter the station's Wi-Fi details.",
          ),
          _step(
            3,
            "Register it to ${widget.station.name}",
            "Once the device reports its ID, register it here.",
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconTile(Icons.fingerprint,
                        color: mac == null
                            ? context.status.neutral
                            : context.status.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Device ID",
                              style: context.text.labelMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                          Text(mac ?? "Not provisioned yet",
                              style: context.text.titleSmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: mac == null ? null : registerDevice,
                  icon: const Icon(Icons.app_registration),
                  label: const Text("Register device"),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text("Nearby devices",
                    style: context.text.titleMedium),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: isScanning ? null : scan,
                icon: isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(isScanning ? "Scanning…" : "Scan"),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(status,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: 10),
          if (devices.isEmpty && !isScanning)
            AppCard(
              child: Text(
                "No devices found yet. Tap Scan to search.",
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          ...devices.map((d) => AppCard(
                padding: const EdgeInsets.symmetric(vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                onTap: () => connectAndOpenSheet(d),
                child: ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(d.device.name.isEmpty ? "Unknown" : d.device.name),
                  subtitle: Text(d.device.remoteId.str),
                  trailing: const Icon(Icons.chevron_right),
                ),
              )),
        ],
      ),
    );
  }

  Widget _step(int number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: context.colors.primaryContainer,
            foregroundColor: context.colors.onPrimaryContainer,
            child: Text('$number', style: context.text.labelMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(subtitle,
                    style: context.text.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
