import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditSensorNameScreen extends StatefulWidget {
  final String deviceId;
  final String sensorKey;
  final String currentLabel;

  const EditSensorNameScreen({
    super.key,
    required this.deviceId,
    required this.sensorKey,
    required this.currentLabel,
  });

  @override
  State<EditSensorNameScreen> createState() => _EditSensorNameScreenState();
}

class _EditSensorNameScreenState extends State<EditSensorNameScreen> {
  final ApiService api = ApiService();

  late TextEditingController controller;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.currentLabel);
  }

  Future<void> save() async {
    setState(() => saving = true);

    try {
      await api.saveChannelMapping(
        deviceId: widget.deviceId,
        key: widget.sensorKey,
        label: controller.text.trim(),
        unit: null,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Edit Sensor Name"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Sensor Label",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: saving ? null : save,
              child: saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}