
// import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:tank_speak/services/web_bluetooth_service.dart';

import 'auth/login_screen.dart';
import '../widgets/app_theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {

  @override
  void initState() {
    super.initState();
    checkBluetooth();
  }

  /// 🔥 CHECK BLUETOOTH ON APP OPEN
  // void checkBluetooth() async {
  //   final state = await FlutterBluePlus.adapterState.first;
  //
  //   if (kIsWeb) {
  //     print("Running on Web");
  //     return;
  //   }
  //
  //   if (state != BluetoothAdapterState.on) {
  //     if (!mounted) return;
  //
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => AlertDialog(
  //         title: const Text("Bluetooth Required"),
  //         content: const Text(
  //           "Please turn on Bluetooth to use BLE Provision feature.",
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () async {
  //               Navigator.pop(context);
  //
  //               /// Android only
  //               await FlutterBluePlus.turnOn();
  //             },
  //             child: const Text("Turn On"),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //             child: const Text("Cancel"),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  void checkBluetooth() async {

    // If running in Chrome, don't use FlutterBluePlus
    if (kIsWeb) {
      print("Running on Web");
      return;
    }

    // Android/iOS only
    final state = await FlutterBluePlus.adapterState.first;

    if (state != BluetoothAdapterState.on) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Bluetooth Required"),
          content: const Text(
            "Please turn on Bluetooth to use BLE Provision feature.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FlutterBluePlus.turnOn();
              },
              child: const Text("Turn On"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _testWebBle() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Run this on Chrome")),
      );
      return;
    }

    try {
      final deviceName = await WebBluetoothService.requestDevice();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to $deviceName")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _feature(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          IconTile(icon, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                const SizedBox(height: 2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BrandMark(size: 72),
                  ),
                  const SizedBox(height: 28),
                  Text("TankSpeak", style: context.text.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    "Monitor your fuel tanks easily",
                    style: context.text.titleMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 36),
                  _feature(Icons.propane_tank_outlined, "Live tank levels",
                      "Calibrated volumes from every Norvi sensor."),
                  _feature(Icons.warning_amber_rounded,
                      "Low-level & refill alerts",
                      "See at a glance which tanks need attention."),
                  _feature(Icons.groups_outlined, "Your team",
                      "Invite managers and members to your stations."),
                  const Spacer(flex: 2),
                  FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text("Sign In"),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _testWebBle,
                      icon: const Icon(Icons.bluetooth),
                      label: const Text("Test Web BLE"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
