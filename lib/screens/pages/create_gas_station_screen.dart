import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/me_response.dart';
import '../../services/station_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';

/// `POST /api/station/c/{company}/station-create` (company owners only).
///
/// The backend requires `subscription_plan_id` but exposes no API to list
/// plans, so the plan number has to be entered (it is shown on the
/// TankSpeak web portal / provided by TankSpeak). See the integration report.
class CreateGasStationScreen extends StatefulWidget {
  final MeResponse me;
  final int companyId;
  final String? companyName;

  const CreateGasStationScreen({
    super.key,
    required this.me,
    required this.companyId,
    this.companyName,
  });

  @override
  State<CreateGasStationScreen> createState() => _CreateGasStationScreenState();
}

class _CreateGasStationScreenState extends State<CreateGasStationScreen> {
  final _formKey = GlobalKey<FormState>();
  final StationService _stations = StationService();

  final name = TextEditingController();
  final address = TextEditingController();
  final businessHours = TextEditingController();
  final exBusinessHours = TextEditingController();
  final phone = TextEditingController();
  final planId = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    businessHours.dispose();
    exBusinessHours.dispose();
    phone.dispose();
    planId.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final result = await _stations.createStation(
        companyId: widget.companyId,
        name: name.text,
        address: address.text,
        phone: phone.text,
        businessHours: businessHours.text,
        extendedBusinessHours: exBusinessHours.text,
        subscriptionPlanId: int.parse(planId.text.trim()),
      );

      if (!mounted) return;
      showSuccess(context, result.message);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildInput({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    bool required = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.next,
        validator: validator ??
            ((String? value) =>
                required && (value == null || value.trim().isEmpty)
                    ? "Required"
                    : null),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon) : null,
          labelText: required ? label : '$label (optional)',
          helperText: helperText,
          helperMaxLines: 3,
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: context.text.titleMedium),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New station")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.companyName != null) ...[
                  Row(
                    children: [
                      const IconTile(Icons.apartment_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(widget.companyName!,
                            style: context.text.titleMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                sectionTitle("Station details"),
                buildInput(
                  label: "Station name",
                  controller: name,
                  icon: Icons.local_gas_station_outlined,
                ),
                buildInput(
                  label: "Address",
                  controller: address,
                  icon: Icons.location_on_outlined,
                ),
                buildInput(
                  label: "Phone",
                  controller: phone,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                buildInput(
                  label: "Business hours",
                  controller: businessHours,
                  icon: Icons.schedule_outlined,
                ),
                buildInput(
                  label: "Extended business hours",
                  controller: exBusinessHours,
                  icon: Icons.more_time,
                  required: false,
                ),
                const SizedBox(height: 8),
                sectionTitle("Subscription"),
                buildInput(
                  label: "Subscription plan number",
                  controller: planId,
                  icon: Icons.card_membership_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  helperText: "Required by the server. Use the plan number "
                      "provided by TankSpeak. The subscription starts when "
                      "the station is created.",
                  validator: (value) {
                    final id = int.tryParse(value?.trim() ?? '');
                    if (id == null || id <= 0) return "Enter a plan number";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isLoading ? null : submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text("Create station"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
