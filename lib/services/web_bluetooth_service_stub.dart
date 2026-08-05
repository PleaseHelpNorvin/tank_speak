class WebBluetoothService {
  static Future<String> requestDevice() async {
    throw UnsupportedError("Only supported on Flutter Web");
  }

  static Future<void> connect() async {}

  static void disconnect() {}

  static bool connected() => false;
}