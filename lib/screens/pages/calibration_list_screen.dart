import 'package:flutter/material.dart';
import 'package:tank_speak/screens/pages/create_calibration_profile_screen.dart';
import '../../models/me_response.dart';
import '../../services/api_service.dart';
import '../../models/calibration_profile.dart';
import '../../widgets/pagination_bar.dart';
import 'calibration_list.dart';

class CalibrationListScreen extends StatefulWidget {
  final MeResponse me;
  const CalibrationListScreen({super.key, required this.me});

  @override
  State<CalibrationListScreen> createState() => _CalibrationListScreenState();
}

class _CalibrationListScreenState extends State<CalibrationListScreen> {
  final ApiService api = ApiService();

  bool isLoading = true;
  String? error;

  List<CalibrationProfile> profiles = [];

  int currentPage = 1;
  int pageSize = 10;
  int total = 0;

  @override
  void initState() {
    super.initState();
    loadProfiles();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: const Text("Calibration Profiles"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => loadProfiles(page: currentPage),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateCalibrationProfileScreen(me: widget.me),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CalibrationLookupTableScreen(
                                  profileId: item.id,
                                ),
                          ),
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