import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

import 'home_screen.dart';
import 'create_gas_station_screen.dart';
import 'invitations_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService api = ApiService();
  final AuthService auth = AuthService(ApiService());

  @override
  void initState() {
    super.initState();
    initApp();
  }

  Future<void> initApp() async {
    try {
      final token = await auth.getToken();

      if (token == null) {
        goTo(const LoginScreen());
        return;
      }

      await auth.getMe();

      final stationResponse = await api.fetchStations();
      final inviteResponse = await api.fetchInvitations();

      final stations = stationResponse.items;
      final invites = inviteResponse.items;

      // 1. Already has station → go app
      if (stations.isNotEmpty) {
        goTo(const HomeScreen());
        return;
      }

      // 2. No station but has invites → must handle first
      if (invites.isNotEmpty) {
        goTo(const InvitationsScreen());
        return;
      }

      // 3. New user → create station
      goTo(const CreateGasStationScreen());
    } catch (e) {
      print(e);
      await auth.logout();
      goTo(const LoginScreen());
    }
  }

  void goTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_gas_station,
              size: 80,
              color: Colors.white,
            ),

            const SizedBox(height: 20),

            const Text(
              "Gas Station System",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const CircularProgressIndicator(
              color: Colors.white,
            ),

            const SizedBox(height: 20),

            Text(
              "Loading your workspace...",
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}