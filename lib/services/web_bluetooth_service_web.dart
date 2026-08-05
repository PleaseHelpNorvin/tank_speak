@JS()
library web_bluetooth_service;

import 'dart:js_interop';

/// These map to the functions you created in bluetooth.js

@JS('requestBluetoothDevice')
external JSPromise<JSString> requestBluetoothDevice();

@JS('connectBluetooth')
external JSPromise<JSBoolean> connectBluetooth();

@JS('disconnectBluetooth')
external JSBoolean disconnectBluetooth();

@JS('isConnected')
external JSBoolean isConnected();

class WebBluetoothService {
  static Future<String> requestDevice() async {
    final result = await requestBluetoothDevice().toDart;

    return result.toDart;
  }

  static Future<void> connect() async {
    await connectBluetooth().toDart;
  }

  static void disconnect() {
    disconnectBluetooth();
  }

  static bool connected() {
    return isConnected().toDart;
  }
}