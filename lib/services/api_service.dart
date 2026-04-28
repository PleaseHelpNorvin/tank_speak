import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company.dart';
import '../models/gas_station.dart';
import '../models/auth_response.dart';
import '../models/me_response.dart';
import '../models/paginated_response.dart';
import '../models/invitation.dart';
import 'mock_data.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.45:3123/api";

  // =========================
  // 🔐 HEADERS (CORE FIX)
  // =========================
  Future<Map<String, String>> _headers({bool auth = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (auth && token != null)
        "Authorization": "Bearer $token",
    };
  }

  // =========================
  // 🧪 MOCK (temporary)
  // =========================
  // Future<List<GasStation>> fetchStationsMock() async {
  //   await Future.delayed(const Duration(seconds: 1));
  //   return MockData.getStations();
  // }

  Future<CreateCompanyResponse> createCompany({
    required String name,
    required String address,
    required String phone,
    required String businessHours,
    required String extendedBusinessHours,
  }) async {
    final url = Uri.parse("$baseUrl/company/c/create");

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode({
        "name": name,
        "address": address,
        "phone": phone,
        "business_hours": businessHours,
        "ex_business_hour": extendedBusinessHours,
      }),
    );


    if (response.statusCode == 200 || response.statusCode == 201) {
      return CreateCompanyResponse.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception("Failed to create company: ${response.body}");
  }


  Future<PaginatedResponse<Company>> fetchCompanies({int page = 1}) async {
    final url = Uri.parse("$baseUrl/companies?page=$page&size=10");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      return PaginatedResponse<Company>.fromJson(
        body,
            (e) => Company.fromJson(e),
        "companies",
      );
    }

    throw Exception("Failed to fetch companies: ${response.body}");
  }


  Future<CompanyDetailResponse> getCompanyById(int id) async {
    final url = Uri.parse("$baseUrl/company/$id");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return CompanyDetailResponse.fromJson(body);
    }

    throw Exception("Failed to fetch company: ${response.body}");
  }

  // =========================
  // STATIONS
  // =========================

  Future<CreateGasStationResponse> createGasStation(
      Map<String, dynamic> data,
      ) async {
    final url = Uri.parse("$baseUrl/station/create");

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CreateGasStationResponse.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception("Error: ${response.body}");
  }

  Future<PaginatedResponse<GasStation>> fetchStations({int page = 1}) async {
    final url = Uri.parse("$baseUrl/stations?page=$page");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      return PaginatedResponse<GasStation>.fromJson(
        body,
            (e) => GasStation.fromJson(e),
        "stations",
      );
    }

    throw Exception("Failed to fetch stations: ${response.body}");
  }

  Future<StationDetailResponse> getStationById(int id) async {
    final url = Uri.parse("$baseUrl/stations/g/$id");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return StationDetailResponse.fromJson(body);
    }

    throw Exception("Failed to fetch station: ${response.body}");
  }


  // =========================
  // 🔐 AUTH
  // =========================
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: await _headers(),
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

  Future<bool> register({
    required String username,
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/register");

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        "username": username,
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    throw Exception("Register failed: ${response.body}");
  }

  // =========================
  // 🤝 INVITATIONS
  // =========================
  Future<PaginatedResponse<ReceivedInvitation>> fetchInvitations() async {
    final url = Uri.parse("$baseUrl/invitations");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      return PaginatedResponse<ReceivedInvitation>.fromJson(
        body,
            (e) => ReceivedInvitation.fromJson(e),
        "recieved_invitations",
      );
    }

    throw Exception("Failed to fetch invitations: ${response.body}");
  }

  Future<Invitation> searchInvitation(String code) async {
    final url = Uri.parse("$baseUrl/invitations/search/$code");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Invitation.fromJson(data);
    }

    throw Exception("Invitation not found: ${response.body}");
  }

  Future<bool> sendInvite({
    required String code,
    required String role,
    required int stationId,
  }) async {
    final url = Uri.parse("$baseUrl/invite");

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode({
        "code": code,
        "role": role,
        "station_id": stationId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    throw Exception("Failed to send invite: ${response.body}");
  }



  Future<void> acceptInvitation(int id) async {
    final url = Uri.parse("$baseUrl/invite/$id/accept");

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to accept invitation: ${response.body}");
    }
  }

  Future<void> deleteInvitation(int id) async {
    final url = Uri.parse("$baseUrl/invite/$id");

    final response = await http.delete(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete invitation: ${response.body}");
    }
  }

  Future<MeResponse> getMe() async {
    final url = Uri.parse("$baseUrl/me");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MeResponse.fromJson(data);
    }

    throw Exception("Failed to get user: ${response.body}");
  }

  // =========================
  // 📟 DEVICE
  // =========================
  Future<bool> registerDevice({
    required String deviceId,
    required String ssid,
  }) async {
    final url = Uri.parse("$baseUrl/device/register");

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
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