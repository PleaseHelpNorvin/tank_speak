import 'package:flutter/material.dart';

class CreateGasStationScreen extends StatefulWidget {
  const CreateGasStationScreen({super.key});

  @override
  State<CreateGasStationScreen> createState() =>
      _CreateGasStationScreenState();
}

class _CreateGasStationScreenState extends State<CreateGasStationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final ownerName = TextEditingController();
  final ownerContact = TextEditingController();

  final stationName = TextEditingController();
  final address = TextEditingController();
  final businessHours = TextEditingController();

  final managerName = TextEditingController();
  final managerContact = TextEditingController();

  bool isLoading = false;

  void submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gas Station Created!")),
      );

      Navigator.pop(context);
    });
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
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// 🔥 HEADER CARD
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
                        "Register a new fuel station with owner, manager, and location details",
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

              /// 👤 OWNER
              sectionTitle("OWNER INFORMATION"),
              buildInput(
                label: "Owner Name",
                controller: ownerName,
                icon: Icons.person,
              ),
              buildInput(
                label: "Owner Contact",
                controller: ownerContact,
                icon: Icons.phone,
              ),

              /// ⛽ STATION
              sectionTitle("STATION DETAILS"),
              buildInput(
                label: "Station Name",
                controller: stationName,
                icon: Icons.store,
              ),
              buildInput(
                label: "Address",
                controller: address,
                icon: Icons.location_on,
              ),
              buildInput(
                label: "Business Hours",
                controller: businessHours,
                icon: Icons.access_time,
              ),

              /// 👨‍💼 MANAGER
              sectionTitle("AREA MANAGER"),
              buildInput(
                label: "Manager Name",
                controller: managerName,
                icon: Icons.badge,
              ),
              buildInput(
                label: "Manager Contact",
                controller: managerContact,
                icon: Icons.phone_android,
              ),

              const SizedBox(height: 25),

              /// 🚀 SUBMIT BUTTON
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
                      ? const CircularProgressIndicator(
                    color: Colors.black,
                  )
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