import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvisionService {
  BluetoothDevice? _device;

  BluetoothCharacteristic? _ssidChar;
  BluetoothCharacteristic? _passChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _deviceChar;

  final Guid ssidUuid =
  Guid("90d294fb-a79e-4ae2-8919-98f61c9a844c");

  final Guid passUuid =
  Guid("344e7c6a-b54c-4687-b84e-d057502b521f");

  final Guid statusUuid =
  Guid("70c26fb4-e385-451f-be8b-94badf41983a");

  final Guid deviceUuid =
  Guid("12345678-1234-1234-1234-123456789abc");

  // --------------------------------------------------
  // CONNECT + DISCOVER
  // --------------------------------------------------
  Future<void> connect(ScanResult result) async {
    _device = result.device;

    await _device!.connect();

    List<BluetoothService> services =
    await _device!.discoverServices();

    for (var service in services) {
      for (var c in service.characteristics) {
        if (c.uuid == ssidUuid) _ssidChar = c;
        if (c.uuid == passUuid) _passChar = c;
        if (c.uuid == statusUuid) _statusChar = c;
        if (c.uuid == deviceUuid) _deviceChar = c;
        if (c.uuid == deviceUuid) _deviceChar = c;
      }
    }

    // IMPORTANT: enable notifications
    if (_statusChar != null) {
      await _statusChar!.setNotifyValue(true);
    }
  }

  // --------------------------------------------------
  // SEND SSID
  // --------------------------------------------------
  Future<void> sendSsid(String ssid) async {
    if (_ssidChar == null) {
      throw Exception("SSID characteristic not found");
    }

    await _ssidChar!.write(
      utf8.encode(ssid),
      withoutResponse: false,
    );
  }

  // --------------------------------------------------
  // SEND PASSWORD
  // --------------------------------------------------
  Future<void> sendPassword(String password) async {
    if (_passChar == null) {
      throw Exception("Password characteristic not found");
    }

    await _passChar!.write(
      utf8.encode(password),
      withoutResponse: false,
    );
  }

  // --------------------------------------------------
  // LIVE STATUS STREAM (FIXED FOR uint8_t 0/1)
  // --------------------------------------------------
  Stream<bool> listenStatus() {
    if (_statusChar == null) {
      throw Exception("Status characteristic not found");
    }

    return _statusChar!.lastValueStream.map((value) {
      if (value.isEmpty) return false;

      // ESP32 sends 1 byte:
      // 1 = connected
      // 0 = failed
      return value[0] == 1;
    });
  }

  Stream<String> listenDeviceId() {
    if (_deviceChar == null) {
      throw Exception("Device char not found");
    }

    return _deviceChar!.lastValueStream.map((value) {
      return String.fromCharCodes(value);
    });
  }

  Future<String> readDeviceId() async {
    if (_deviceChar == null) {
      throw Exception("Device char not found");
    }

    final value = await _deviceChar!.read();
    return String.fromCharCodes(value);
  }

  // --------------------------------------------------
  // OPTIONAL: RAW STATUS (DEBUG ONLY)
  // --------------------------------------------------
  Stream<List<int>> listenRawStatus() {
    if (_statusChar == null) {
      throw Exception("Status characteristic not found");
    }

    return _statusChar!.lastValueStream;
  }

  // --------------------------------------------------
  // DISCONNECT
  // --------------------------------------------------
  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;

    _ssidChar = null;
    _passChar = null;
    _statusChar = null;
  }
}