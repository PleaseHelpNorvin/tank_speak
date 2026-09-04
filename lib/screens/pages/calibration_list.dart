import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/calibration_profile.dart';
import '../../services/api_service.dart';

class CalibrationLookupTableScreen extends StatefulWidget {
  final int profileId;

  const CalibrationLookupTableScreen({
    super.key,
    required this.profileId,
  });

  @override
  State<CalibrationLookupTableScreen> createState() =>
      _CalibrationLookupTableScreenState();
}

class _CalibrationLookupTableScreenState
    extends State<CalibrationLookupTableScreen> {

  final ApiService api = ApiService();

  bool isLoading = true;
  String? error;

  CalibrationProfileDetailResponse? response;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await api.getCalibrationProfileById(
        widget.profileId,
      );

      setState(() {
        response = result;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // =========================
  // ADD ROW
  // =========================
  Future<void> showAddRowDialog() async {

    final levelController = TextEditingController();
    final dipstickController = TextEditingController();
    final volumeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Calibration Row"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: levelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Level",
                ),
              ),

              TextField(
                controller: dipstickController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Dipstick Liters",
                ),
              ),

              TextField(
                controller: volumeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Volume Liters",
                ),
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  await api.addCalibrationRow(
                    profileId: widget.profileId,
                    level: double.parse(levelController.text),
                    dipstickLiters: double.parse(dipstickController.text),
                    volumeLiters: double.parse(volumeController.text),
                  );

                  Navigator.pop(context);
                  await loadData();

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // DELETE ROW
  // =========================
  Future<void> deleteRow(int id) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Row"),
          content: const Text("Are you sure you want to delete this row?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await api.deleteCalibrationRow(id);
      await loadData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // =========================
  // EDIT ROW (SIMPLE)
  // =========================
  Future<void> editRow(CalibrationEntry e) async {

    final levelController =
    TextEditingController(text: e.level.toString());

    final dipstickController =
    TextEditingController(text: e.dipstickLiters.toString());

    final volumeController =
    TextEditingController(text: e.volumeLiters.toString());

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Calibration Row"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: levelController,
                keyboardType: TextInputType.number,
              ),

              TextField(
                controller: dipstickController,
                keyboardType: TextInputType.number,
              ),

              TextField(
                controller: volumeController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  await api.updateCalibrationRow(
                    id: e.id,
                    level: double.parse(levelController.text),
                    dipstickLiters: double.parse(dipstickController.text),
                    volumeLiters: double.parse(volumeController.text),
                  );

                  Navigator.pop(context);
                  await loadData();

                } catch (err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err.toString())),
                  );
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return;

      final file = result.files.single;

      if (file.path == null) return;

      await api.uploadCalibrationExcel(
        profileId: widget.profileId,
        filePath: file.path!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Excel uploaded successfully"),
        ),
      );

      await loadData();

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        title: Text(
          response?.profile.name ?? "Calibration Table",
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())

          : error != null
          ? Center(
        child: Text(
          error!,
          style: const TextStyle(color: Colors.red),
        ),
      )

          : Column(
        children: [

// ================= BUTTONS =================
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              children: [

                // ================= ADD ROW (PRIMARY ORANGE) =================
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: showAddRowDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Add Row"),

                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),

                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),

                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: uploadExcel,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text("Import Excel"),

                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),

                      foregroundColor: Colors.orange,

                      side: const BorderSide(
                        color: Colors.orange,
                        width: 1.5,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),

                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= HEADER =================
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.all(16),
          //   margin: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.05),
          //     borderRadius: BorderRadius.circular(14),
          //   ),
          //
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //
          //       Text(
          //         response!.profile.name,
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 20,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //
          //       const SizedBox(height: 6),
          //
          //       Text(
          //         "Profile ID: ${response!.profile.id}",
          //         style: TextStyle(
          //           color: Colors.white.withOpacity(0.7),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // ================= TABLE =================
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: SingleChildScrollView(
                child: DataTable(

                  headingTextStyle: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),

                  dataTextStyle: const TextStyle(
                    color: Colors.white,
                  ),

                  columns: const [

                    DataColumn(label: Text("Level")),
                    DataColumn(label: Text("Dipstick")),
                    DataColumn(label: Text("Volume")),
                    DataColumn(label: Text("Actions")),
                  ],

                  rows: response!.calibrations.map((e) {

                    return DataRow(

                      cells: [

                        DataCell(Text(e.level.toString())),

                        DataCell(Text("${e.dipstickLiters ?? 0}")),

                        DataCell(Text("${e.volumeLiters ?? 0}")),

                        DataCell(
                          Row(
                            children: [

                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                onPressed: () => editRow(e),
                              ),

                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => deleteRow(e.id),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}