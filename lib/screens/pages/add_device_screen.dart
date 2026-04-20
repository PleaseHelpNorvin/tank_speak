import 'package:flutter/material.dart';
import 'package:tank_speak/models/gas_station.dart';
import 'package:tank_speak/models/tank.dart';
import '../pages/profile_screen.dart';
import '../../services/api_service.dart';

class AddDeviceScreen extends StatefulWidget {
  final GasStation station;
  List<Device> devices;
  final int maxDevicesPerStation;

  AddDeviceScreen({super.key,required this.station, required this.devices, required this.maxDevicesPerStation,
  });

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  bool isLoading = false;
  bool isLoadingDevices = true;

  /// DEVICE IDS (will be loaded from mock)
  List<String> deviceIds = [];

  /// DYNAMIC DEVICE LIST
  List<Map<String, dynamic>> devices = [
    {
      "id": null,
      "radius": TextEditingController(),
      "length": TextEditingController(),
    }
  ];

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  /// 🔹 MOCK API
  Future<List<String>> getAvailableDevicesMock() async {
    await Future.delayed(const Duration(seconds: 1));
    return ["18", "19", "20", "21", "22"];
  }

  void loadDevices() async {
    final data = await getAvailableDevicesMock();

    setState(() {
      deviceIds = data;
      isLoadingDevices = false;
    });
  }

  void addRow() {
    if (devices.length >= widget.maxDevicesPerStation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You can only add up to $widget.maxDevicesPerStation devices per station"),
        ),
      );
      return;
    }

    setState(() {
      devices.add({
        "id": null,
        "radius": TextEditingController(),
        "length": TextEditingController(),
      });
    });
  }

  void removeRow(int index) {
    if (devices.length == 1) return;
    setState(() {
      devices.removeAt(index);
    });
  }

  /// 🔹 BUILD PAYLOAD
  String buildPayload() {
    List<String> formatted = [];

    for (var d in devices) {
      final id = d["id"];
      final radius = d["radius"].text;
      final length = d["length"].text;

      if (id != null && radius.isNotEmpty && length.isNotEmpty) {
        formatted.add("$id-$radius-$length");
      }
    }

    return formatted.join(",");
  }

  /// 🔹 SUBMIT (MOCK SAVE)
  void submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = buildPayload();

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all device fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      print("Payload: $payload");

      /// simulate API save
      await Future.delayed(const Duration(seconds: 1));

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Devices Added!")),
      );

      Navigator.pop(context);
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
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      validator: (value) =>
      value == null || value.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget deviceRow(int index) {
    final device = devices[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                "Device ${index + 1}",
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => removeRow(index),
                icon: const Icon(Icons.delete, color: Colors.red),
              )
            ],
          ),

          const SizedBox(height: 10),

          /// 🔹 DROPDOWN WITH LOADING
          isLoadingDevices
              ? const Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(),
          )
              : DropdownButtonFormField<String>(
            value: device["id"],
            dropdownColor: const Color(0xFF0F2027),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Device ID",
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: deviceIds.map((id) {
              return DropdownMenuItem(
                value: id,
                child: Text(id),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                device["id"] = value;
              });
            },
            validator: (value) =>
            value == null ? "Select Device ID" : null,
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: buildInput(
                  label: "Radius",
                  controller: device["radius"],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildInput(
                  label: "Length",
                  controller: device["length"],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: Text("Add Devices for ${widget.station.name}"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        actions: [

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
                    Icon(Icons.devices, color: Colors.orange, size: 30),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Add multiple tank sensors",
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

              /// DEVICE LIST
              ...List.generate(devices.length, (index) {
                return deviceRow(index);
              }),

              /// ADD BUTTON
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: devices.length >= widget.maxDevicesPerStation ? null : addRow,
                  icon: const Icon(Icons.add, color: Colors.orange),
                  label: Text(
                    devices.length >= widget.maxDevicesPerStation
                        ? "Max devices reached"
                        : "Add Another Device",
                    style: TextStyle(
                      color: devices.length >= widget.maxDevicesPerStation
                          ? Colors.grey
                          : Colors.orange,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// SUBMIT
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
                    "Save Devices",
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