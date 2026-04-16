import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/gas_station.dart';
import '../models/auth_response.dart';
import 'mock_data.dart';

class ApiService {
  static const String baseUrl = "http://159.89.230.35/api";

  // 🔹 MOCK (for now)
  Future<List<GasStation>> fetchStations() async {
    await Future.delayed(Duration(seconds: 1));
    return MockData.getStations();
  }

  // 🔹 LOGIN
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AuthResponse.fromJson(data);
    }

    throw Exception("Login failed: ${response.body}");
  }

  // 🔹 REGISTER
  Future<bool> register({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/register");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    throw Exception("Register failed: ${response.body}");
  }

  // 🔹 DEVICE REGISTER
  Future<bool> registerDevice({
    required String deviceId,
    required String ssid,
  }) async {
    final url = Uri.parse("$baseUrl/device/register");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "device_id": deviceId,
        "ssid": ssid,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    throw Exception("Failed to register device: ${response.body}");
  }
}