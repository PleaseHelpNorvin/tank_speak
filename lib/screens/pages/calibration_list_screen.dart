import 'package:flutter/material.dart';

import '../../models/calibration_profile.dart';
import '../../models/me_response.dart';
import '../../services/calibration_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';
import 'calibration_list.dart';

/// Lists the calibration (lookup) profiles available for tank channels.
/// Read-only: profiles are maintained in the web administration portal.
class CalibrationListScreen extends StatefulWidget {
  final MeResponse me;

  const CalibrationListScreen({super.key, required this.me});

  @override
  State<CalibrationListScreen> createState() => _CalibrationListScreenState();
}

class _CalibrationListScreenState extends State<CalibrationListScreen> {
  final CalibrationService _calibration = CalibrationService();

  static const int pageSize = 20;

  bool isLoading = true;
  Object? error;
  List<CalibrationProfile> profiles = [];
  int currentPage = 1;
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
      final result =
          await _calibration.fetchProfiles(page: page, size: pageSize);
      if (!mounted) return;
      setState(() {
        profiles = result.items;
        currentPage = result.page;
        total = result.total;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lookup Tables"),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : () => loadProfiles(page: currentPage),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (isLoading && profiles.isEmpty) return const LoadingView();
    if (error != null && profiles.isEmpty) {
      return ErrorView(
          error: error!, onRetry: () => loadProfiles(page: currentPage));
    }
    if (profiles.isEmpty) {
      return const EmptyView(
        icon: Icons.table_chart,
        title: 'No lookup tables yet',
        message: 'Lookup tables are created by TankSpeak in the web portal.',
      );
    }

    return Column(
      children: [
        PaginationBar(
          currentPage: currentPage,
          total: total,
          pageSize: pageSize,
          onPrev: () => loadProfiles(page: currentPage - 1),
          onNext: () => loadProfiles(page: currentPage + 1),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => loadProfiles(page: currentPage),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final item = profiles[index];
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 10),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CalibrationLookupTableScreen(profileId: item.id),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const IconTile(Icons.table_chart_outlined),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(item.name, style: context.text.titleSmall),
                      ),
                      Icon(Icons.chevron_right,
                          color: context.colors.onSurfaceVariant),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
