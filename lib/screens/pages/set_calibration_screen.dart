import 'package:flutter/material.dart';

import '../../models/calibration_profile.dart';
import '../../models/me_response.dart';
import '../../services/calibration_service.dart';
import '../../services/device_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';
import 'calibration_list.dart';

/// Assigns a lookup table to one device channel through
/// `POST /api/device-channel/{device_id}/channel-calibration`.
/// Pops with the assigned profile id.
class SetCalibrationScreen extends StatefulWidget {
  final MeResponse me;
  final int deviceId;
  final int? activeCalibProfileId;
  final int stationId;
  final String channelKey;

  const SetCalibrationScreen({
    super.key,
    required this.me,
    required this.deviceId,
    required this.activeCalibProfileId,
    required this.stationId,
    required this.channelKey,
  });

  @override
  State<SetCalibrationScreen> createState() => _SetCalibrationScreenState();
}

class _SetCalibrationScreenState extends State<SetCalibrationScreen> {
  final CalibrationService _calibration = CalibrationService();
  final DeviceService _devices = DeviceService();

  static const int pageSize = 20;

  CalibrationProfile? activeProfile;
  bool loadingActiveProfile = true;

  bool isLoading = true;
  bool saving = false;
  Object? error;

  List<CalibrationProfile> profiles = [];
  int currentPage = 1;
  int total = 0;

  @override
  void initState() {
    super.initState();
    loadActiveProfile();
    loadProfiles();
  }

  Future<void> loadActiveProfile() async {
    final id = widget.activeCalibProfileId;
    if (id == null) {
      setState(() => loadingActiveProfile = false);
      return;
    }

    try {
      final result = await _calibration.getProfileSummary(id);
      if (!mounted) return;
      setState(() {
        activeProfile = result;
        loadingActiveProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
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

  Future<void> confirmSetCalibration(CalibrationProfile profile) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.table_chart_outlined),
          title: const Text("Use this lookup table?"),
          content: Text(
            "Use \"${profile.name}\" for channel ${widget.channelKey}? "
            "Volumes for this channel will be calculated with it.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Use it"),
            ),
          ],
        );
      },
    );

    if (result != true || !mounted) return;

    setState(() => saving = true);
    try {
      await _devices.setChannelCalibration(
        deviceId: widget.deviceId,
        channelKey: widget.channelKey,
        calibrationProfileId: profile.id,
      );
      if (!mounted) return;
      showSuccess(context, "Lookup table updated");
      Navigator.pop(context, profile.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lookup for ${widget.channelKey}"),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : () => loadProfiles(page: currentPage),
          ),
        ],
      ),
      body: Stack(
        children: [
          _body(),
          if (saving)
            Container(
              color: Colors.black26,
              child: const LoadingView(message: 'Saving...'),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (isLoading && profiles.isEmpty) return const LoadingView();
    if (error != null && profiles.isEmpty) {
      return ErrorView(
          error: error!, onRetry: () => loadProfiles(page: currentPage));
    }

    final activeId = activeProfile?.id ?? widget.activeCalibProfileId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: loadingActiveProfile
              ? const LinearProgressIndicator()
              : AppCard(
                  margin: EdgeInsets.zero,
                  color: context.colors.primaryContainer,
                  borderColor: Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        activeProfile != null
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: context.colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Current lookup table",
                                style: context.text.labelMedium?.copyWith(
                                    color: context.colors.onPrimaryContainer)),
                            const SizedBox(height: 2),
                            Text(
                              activeProfile?.name ??
                                  "None — raw sensor values are shown",
                              style: context.text.titleSmall?.copyWith(
                                  color: context.colors.onPrimaryContainer),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
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
            child: profiles.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyView(
                      icon: Icons.table_chart_outlined,
                      title: 'No lookup tables available',
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final item = profiles[index];
                      final isActive = item.id == activeId;
                      return AppCard(
                        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                        margin: const EdgeInsets.only(bottom: 10),
                        borderColor:
                            isActive ? context.colors.primary : null,
                        onTap:
                            isActive ? null : () => confirmSetCalibration(item),
                        child: Row(
                          children: [
                            const IconTile(Icons.science_outlined, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(item.name,
                                  style: context.text.titleSmall),
                            ),
                            if (isActive)
                              StatusPill(
                                  label: 'In use',
                                  color: context.colors.primary,
                                  icon: Icons.check),
                            IconButton(
                              tooltip: 'View table',
                              icon: const Icon(Icons.visibility_outlined),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CalibrationLookupTableScreen(
                                            profileId: item.id),
                                  ),
                                );
                              },
                            ),
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
