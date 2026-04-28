import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvisionService {
  BluetoothDevice? _device;

  BluetoothCharacteristic? _ssidChar;
  BluetoothCharacteristic? _passChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _macChar;

  final Guid ssidUuid =
  Guid("90d294fb-a79e-4ae2-8919-98f61c9a844c");

  final Guid passUuid =
  Guid("344e7c6a-b54c-4687-b84e-d057502b521f");

  final Guid statusUuid =
  Guid("70c26fb4-e385-451f-be8b-94badf41983a");

  final Guid macCharUuid =
  Guid("d57ea28a-0e5a-4333-bb24-1bf02057eb83");

  // --------------------------------------------------
  // CONNECT + DISCOVER
  // --------------------------------------------------
  Future<bool> connect(ScanResult result) async {
    try {
      await disconnect();

      _device = result.device;

      await _device!.connect(autoConnect: false);

      final services = await _device!.discoverServices();

      _ssidChar = null;
      _passChar = null;
      _statusChar = null;
      _macChar = null;

      for (var service in services) {
        for (var c in service.characteristics) {
          if (c.uuid == ssidUuid) _ssidChar = c;
          if (c.uuid == passUuid) _passChar = c;
          if (c.uuid == statusUuid) _statusChar = c;
          if (c.uuid == macCharUuid) _macChar = c;
        }
      }

      if (_statusChar != null) {
        await _statusChar!.setNotifyValue(true);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // --------------------------------------------------
  // SSID
  // --------------------------------------------------
  Future<void> sendSsid(String ssid) async {
    if (_ssidChar == null) throw Exception("SSID not found");

    await _ssidChar!.write(
      utf8.encode(ssid),
      withoutResponse: false,
    );
  }

  // --------------------------------------------------
  // PASSWORD
  // --------------------------------------------------
  Future<void> sendPassword(String pass) async {
    if (_passChar == null) throw Exception("PASS not found");

    await _passChar!.write(
      utf8.encode(pass),
      withoutResponse: false,
    );
  }

  // --------------------------------------------------
  // STATUS STREAM
  // --------------------------------------------------
  Stream<bool> listenStatus() {
    if (_statusChar == null) throw Exception("Status not found");

    return _statusChar!.onValueReceived.map((value) {
      if (value.isEmpty) return false;

      final code = value[0];

      print("RAW STATUS: $code"); // 🔥 DEBUG

      switch (code) {
        case 0x01:
          print("BLE: Connecting...");
          return false;

        case 0x02:
          print("BLE: Connected ");
          return true;

        default:
          print("BLE: Unknown status $code");
          return false;
      }
    });
  }

  // --------------------------------------------------
  // 🔥 FIXED MAC READ (IMPORTANT)
  // --------------------------------------------------
  Future<String> readDeviceMac() async {
    if (_macChar == null) {
      throw Exception("MAC characteristic not found");
    }

    try {
      final value = await _macChar!.read();

      if (value.isEmpty) {
        return "EMPTY_MAC";
      }

      return String.fromCharCodes(value);
    } catch (e) {
      return "READ_ERROR";
    }
  }

  // --------------------------------------------------
  // CLEAN DISCONNECT
  // --------------------------------------------------
  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _ssidChar = null;
    _passChar = null;
    _statusChar = null;
    _macChar = null;
  }
}