import 'package:flutter/material.dart';
import 'package:tank_speak/models/me_response.dart';
import 'package:tank_speak/screens/pages/splash_screen.dart';
import '../pages/profile_screen.dart';
import '../pages/home_screen.dart';
import '../../services/api_service.dart';

class CreateGasStationScreen extends StatefulWidget {
  final MeResponse me;
  const CreateGasStationScreen({super.key, required this.me});

  @override
  State<CreateGasStationScreen> createState() =>
      _CreateGasStationScreenState();
}

class _CreateGasStationScreenState extends State<CreateGasStationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  final name = TextEditingController();
  final address = TextEditingController();
  final businessHours = TextEditingController();
  final exBusinessHours = TextEditingController();
  final phone = TextEditingController();

  bool isLoading = false;

  void submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final data = {
        "name": name.text,
        "address": address.text,
        "business_hours": businessHours.text,
        "ex_business_hour": exBusinessHours.text,
        "phone": phone.text,
      };

      await api.createGasStation(data);

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gas Station Created!")),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
      );
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget buildInput({
    required String label,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        validator: (value) =>
        value == null || value.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.white70)
              : null,
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: const Text("Create Gas Station"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  ProfileScreen(me: widget.me)),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_gas_station,
                        color: Colors.orange, size: 30),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Create a new gas station",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// STATION DETAILS
              sectionTitle("STATION DETAILS"),

              buildInput(
                label: "Station Name",
                controller: name,
                icon: Icons.store,
              ),

              buildInput(
                label: "Address",
                controller: address,
                icon: Icons.location_on,
              ),

              buildInput(
                label: "Phone",
                controller: phone,
                icon: Icons.phone,
              ),

              buildInput(
                label: "Business Hours",
                controller: businessHours,
                icon: Icons.access_time,
              ),

              buildInput(
                label: "Extra Business Hours",
                controller: exBusinessHours,
                icon: Icons.access_time_filled,
              ),

              const SizedBox(height: 25),

              /// SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                    "Create Gas Station",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}