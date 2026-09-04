import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calibration_profile.dart';
import '../models/company.dart';
import '../models/gas_station.dart';
import '../models/auth_response.dart';
import '../models/me_response.dart';
import '../models/paginated_response.dart';
import '../models/invitation.dart';
import '../models/tank.dart';
import 'mock_data.dart';

class ApiService {
  static const String baseUrl = "https://129.121.115.28/api";


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

  Future<CreateCompanyResponse> createCompany(
      Map<String, dynamic> data,) async {
    final url = Uri.parse("$baseUrl/company/create");

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CreateCompanyResponse.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception("Failed to create company: ${response.body}");
  }


  Future<PaginatedResponse<Company>> fetchCompanies({int page = 1}) async {
    final url = Uri.parse("$baseUrl/company?page=$page&size=10");

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
    final url = Uri.parse("$baseUrl/company/c/$id");

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

  Future<CreateGasStationResponse> createGasStation(int companyId,
      Map<String, dynamic> data,) async {
    final url = Uri.parse(
      "$baseUrl/station/c/$companyId/station-create",
    );

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
    final url = Uri.parse("$baseUrl/station/g/$id");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    // =========================
    // DEBUG RESPONSE
    // =========================
    print("STATUS CODE: ${response.statusCode}");
    print("RAW RESPONSE:");
    print(response.body);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      // Optional pretty print
      print("DECODED JSON:");
      print(body);

      return StationDetailResponse.fromJson(body);
    }

    throw Exception("Failed to fetch station: ${response.body}");
  }

  Future<List<DeviceReading>> getDeviceReadings({
    required String deviceId,
    required String sensorPin,
    int limit = 50,
    String range = "all",
  }) async {
    final url = Uri.parse(
      "$baseUrl/device/$deviceId/$sensorPin/readings"
          "?limit=$limit&range=$range",
    );
    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return DeviceReading.listFromJson(
        data,
      );
    }

    throw Exception("Failed to get readings: ${response.body}");
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
    final url = Uri.parse("$baseUrl/invite");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      return PaginatedResponse<ReceivedInvitation>.fromJson(
        body,
            (e) => ReceivedInvitation.fromJson(e),
        "received_invitations",
      );
    }

    throw Exception("Failed to fetch invitations: ${response.body}");
  }

  Future<Invitation> searchInvitation(String code) async {
    final url = Uri.parse("$baseUrl/invite/search/$code");

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
    required int companyId,
  }) async {
    final url = Uri.parse("$baseUrl/invite");

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode({
        "code": code,
        "role": role,
        "station_id": stationId,
        "company_id": companyId,
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
  Future<RegisterDeviceResponse> registerDevice({
    required String deviceId,
    required int stationId,
  }) async {
    final url = Uri.parse("$baseUrl/device/register");

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode({
        "key": deviceId,
        "station_id": stationId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return RegisterDeviceResponse.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception("Failed to register device: ${response.body}");
  }

  Future<PaginatedResponse<CalibrationProfile>> fetchCalibrationProfiles({
    int page = 1,
    int size = 10,
    String? name,
  }) async {
    final uri = Uri.parse("$baseUrl/calibration/profiles").replace(
      queryParameters: {
        "page": page.toString(),
        "size": size.toString(),
        if (name != null && name.isNotEmpty) "name": name,
      },
    );

    final response = await http.get(
      uri,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      return PaginatedResponse<CalibrationProfile>.fromJson(
        body,
            (e) => CalibrationProfile.fromJson(e),
        "profiles", // 👈 matches backend key
      );
    }

    throw Exception("Failed to fetch calibration profiles: ${response.body}");
  }


  Future<CreateCalibrationProfileResponse> createCalibrationProfile({
    required String name,
  }) async {
    final url = Uri.parse("$baseUrl/calibration/profile-create?name=$name");

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return CreateCalibrationProfileResponse.fromJson(data);
    }

    throw Exception("Failed to create calibration profile: ${response.body}");
  }


  Future<CalibrationProfileDetailResponse>
  getCalibrationProfileById(int id) async {

    final url = Uri.parse(
      "$baseUrl/calibration/profile/$id",
    );

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      return CalibrationProfileDetailResponse
          .fromJson(body);
    }

    throw Exception(
      "Failed to fetch calibration profile: ${response.body}",
    );
  }

  Future<void> addCalibrationRow({
    required int profileId,
    required double level,
    required double dipstickLiters,
    required double volumeLiters,
  }) async {

    final url = Uri.parse(
      "$baseUrl/calibration/add-row"
          "?device_calibration_profile_id=$profileId"
          "&level=$level"
          "&dipstick_liters=$dipstickLiters"
          "&volume_liters=$volumeLiters",
    );

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {

      throw Exception(
        "Failed to add row: ${response.body}",
      );
    }
  }

  Future<void> updateCalibrationRow({
    required int id,
    required double level,
    required double dipstickLiters,
    required double volumeLiters,
  }) async {

    final url = Uri.parse(
      "$baseUrl/calibration/$id"
          "?level=$level"
          "&dipstick_liters=$dipstickLiters"
          "&volume_liters=$volumeLiters",
    );

    final response = await http.put(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update calibration row: ${response.body}");
    }
  }

  Future<void> deleteCalibrationRow(int id) async {

    final url = Uri.parse("$baseUrl/calibration/$id");

    final response = await http.delete(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete calibration row: ${response.body}");
    }
  }

  Future<void> uploadCalibrationExcel({
    required int profileId,
    required String filePath,
  }) async {

    final uri = Uri.parse(
      "$baseUrl/calibration/upload-excel",
    );

    final request = http.MultipartRequest("POST", uri);

    // auth header
    final headers = await _headers(auth: true);
    request.headers.addAll(headers);

    // form field (int)
    request.fields['device_calibration_profile_id'] =
        profileId.toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
      ),
    );

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception("Upload failed: $responseBody");
    }
  }


  Future<void> saveChannelMapping({
    required String deviceId,
    required String key,
    required String label,
    String? unit,
  }) async {
    final url = Uri.parse(
      "$baseUrl/device/$deviceId/channel-mapping",
    );

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode({
        "key": key,
        "label": label,
        "unit": unit,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed: ${response.body}");
    }
  }

  Future<CalibrationProfile> getActiveCalibrationProfileById(int id) async {
    final url = Uri.parse("$baseUrl/device-calibration-profile/$id");

    final response = await http.get(
      url,
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return CalibrationProfile.fromJson(data);
    }

    throw Exception("Failed to fetch calibration profile: ${response.body}");
  }

  Future<void> setChannelCalibration({
    required int deviceId,
    required String key,
    required int calibrationProfileId,
  }) async {
    final url = Uri.parse(
      "$baseUrl/device/$deviceId/channel-calibration",
    );

    final response = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode({
        "key": key,
        "calibration_profile_id": calibrationProfileId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to set calibration: ${response.body}");
    }
  }
}

