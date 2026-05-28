import 'package:flutter/material.dart';
import '../../models/me_response.dart';
import '../../services/api_service.dart';

class CreateCalibrationProfileScreen extends StatefulWidget {
  final MeResponse me;
  const CreateCalibrationProfileScreen({super.key, required this.me});

  @override
  State<CreateCalibrationProfileScreen> createState() =>
      _CreateCalibrationProfileScreenState();
}

class _CreateCalibrationProfileScreenState
    extends State<CreateCalibrationProfileScreen> {
  final ApiService api = ApiService();
  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;

  Future<void> createProfile() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name is required")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await api.createCalibrationProfile(
        name: name,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      Navigator.pop(context, true); // return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Create Calibration Profile"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Profile Name",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: isLoading ? null : createProfile,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}