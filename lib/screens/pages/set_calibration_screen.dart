import 'package:flutter/material.dart';
import 'package:tank_speak/screens/pages/create_calibration_profile_screen.dart';
import '../../models/me_response.dart';
import '../../services/api_service.dart';
import '../../models/calibration_profile.dart';
import '../../widgets/pagination_bar.dart';
import 'calibration_list.dart';

class SetCalibrationScreen extends StatefulWidget {
  final MeResponse me;
  final int? activeCalibProfileId;
  final int stationId;
  const SetCalibrationScreen({super.key, required this.me, required this.activeCalibProfileId, required this.stationId});


  @override
  State<SetCalibrationScreen> createState() => _SetCalibrationScreenState();
}

class _SetCalibrationScreenState extends State<SetCalibrationScreen> {
  final ApiService api = ApiService();

  CalibrationProfile? activeProfile;
  bool loadingActiveProfile = true;

  bool isLoading = true;
  String? error;

  List<CalibrationProfile> profiles = [];

  int currentPage = 1;
  int pageSize = 10;
  int total = 0;

  int? activeCalibProfileId;

  @override
  void initState() {
    super.initState();

    activeCalibProfileId = widget.activeCalibProfileId;

    loadActiveProfile();
    loadProfiles();
  }

  Future<void> loadActiveProfile() async {
    if (activeCalibProfileId == null) {
      setState(() => loadingActiveProfile = false);
      return;
    }

    try {
      final result = await api.getActiveCalibrationProfileById(
        activeCalibProfileId!,
      );

      setState(() {
        activeProfile = result;
        loadingActiveProfile = false;
      });
    } catch (e) {
      setState(() {
        activeProfile = null;
        loadingActiveProfile = false;
      });
    }
  }

  Future<void> loadProfiles({int page = 1}) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await api.fetchCalibrationProfiles(
        page: page,
        size: pageSize,
      );

      setState(() {
        profiles = result.items;
        currentPage = result.page;
        total = result.total;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> setCalibrationProfile({
    required int deviceId,
    required String key,
    required int profileId,
  }) async {
    try {
      await api.setChannelCalibration(
        deviceId: deviceId,
        key: key,
        calibrationProfileId: profileId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Calibration updated successfully")),
      );

      // 🔥 UPDATE STATE FIRST
      setState(() {
        activeCalibProfileId = profileId;
        loadingActiveProfile = true;
      });

      // 🔥 RELOAD FROM API (this is the real truth)
      await loadActiveProfile();

      // 🔥 RETURN RESULT TO PARENT SCREEN
      Navigator.pop(context, profileId);

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  CalibrationProfile? getActiveProfile() {
    if (widget.activeCalibProfileId == null) return null;

    try {
      return profiles.firstWhere(
            (p) => p.id == widget.activeCalibProfileId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> confirmSetCalibration({
    required int deviceId,
    required String key,
    required int profileId,
    required String profileName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2C34),
          title: const Text(
            "Confirm Calibration",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Set \"$profileName\" as calibration profile for channel $key?",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await setCalibrationProfile(
        deviceId: deviceId,
        key: key,
        profileId: profileId,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: const Text("Set Look up "),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => loadProfiles(page: currentPage),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.orange,
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (_) => CreateCalibrationProfileScreen(me: widget.me),
      //       ),
      //     );
      //   },
      //   child: const Icon(Icons.add),
      // ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Text(
          error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      )
          : Column(
        children: [

          if (loadingActiveProfile)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            )
          else if (activeProfile != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.orange),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Active Calibration Profile",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeProfile!.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "ID: ${activeProfile!.id}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "No active calibration profile",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          // ================= PAGINATION BAR =================
          PaginationBar(
            currentPage: currentPage,
            total: total,
            pageSize: pageSize,
            onPrev: () {
              if (currentPage > 1) {
                loadProfiles(page: currentPage - 1);
              }
            },
            onNext: () {
              final maxPage = (total / pageSize).ceil();
              if (currentPage < maxPage) {
                loadProfiles(page: currentPage + 1);
              }
            },
          ),

          // ================= LIST =================
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await loadProfiles(page: currentPage);
              },
              child: profiles.isEmpty
                  ? const Center(
                child: Text(
                  "No calibration profiles found",
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final item = profiles[index];

                  return GestureDetector(
                      onTap: () {
                        confirmSetCalibration(
                          deviceId: widget.me.id,
                          key: "A0",
                          profileId: item.id,
                          profileName: item.name,
                        );


                      },

                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.science,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ID: ${item.id}",
                                    style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      )
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}