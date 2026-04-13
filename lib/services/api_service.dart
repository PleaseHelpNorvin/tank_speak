import 'dart:async';
import '../models/gas_station.dart';
import 'mock_data.dart';

class ApiService {
  Future<List<GasStation>> fetchStations() async {
    await Future.delayed(Duration(seconds: 1)); // simulate API
    return MockData.getStations();
  }
}