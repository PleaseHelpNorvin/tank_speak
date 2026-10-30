import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/calibration_profile.dart';
import '../../services/calibration_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';

/// Read-only view of a calibration (lookup) table.
///
/// Calibration profiles are global and shared by all customers, so editing
/// rows, importing Excel files and deleting profiles is done by TankSpeak
/// administrators in the web portal, not in the mobile app.
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
  final CalibrationService _calibration = CalibrationService();

  bool isLoading = true;
  Object? error;
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
      final result = await _calibration.getProfileTable(widget.profileId);
      if (!mounted) return;
      setState(() {
        response = result;
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
        title: Text(response?.profile.name ?? "Calibration Table"),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : loadData,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (isLoading && response == null) return const LoadingView();
    if (error != null && response == null) {
      return ErrorView(error: error!, onRetry: loadData);
    }

    final rows = response!.calibrations;
    if (rows.isEmpty) {
      return const EmptyView(
        icon: Icons.table_rows,
        title: 'This lookup table has no rows',
        message: 'Rows are managed in the TankSpeak web portal.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: InfoBanner(
            message: '${rows.length} rows • level → volume in liters. '
                'The server uses the row whose level is closest to the '
                'sensor reading.',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingTextStyle: context.text.labelLarge
                    ?.copyWith(color: context.colors.primary),
                dataTextStyle: context.text.bodyMedium,
                columns: const [
                  DataColumn(label: Text("Level"), numeric: true),
                  DataColumn(label: Text("Dipstick (L)"), numeric: true),
                  DataColumn(label: Text("Volume (L)"), numeric: true),
                  DataColumn(label: Text("Actual (L)"), numeric: true),
                ],
                rows: rows
                    .map((e) => DataRow(cells: [
                          DataCell(Text(Fmt.number(e.level, decimals: 2))),
                          DataCell(
                              Text(Fmt.number(e.dipstickLiters, decimals: 2))),
                          DataCell(
                              Text(Fmt.number(e.volumeLiters, decimals: 2))),
                          DataCell(
                              Text(Fmt.number(e.actualLiters, decimals: 2))),
                        ]))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
