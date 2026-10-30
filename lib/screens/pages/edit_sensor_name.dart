import 'package:flutter/material.dart';

import '../../services/device_service.dart';
import '../../widgets/state_views.dart';

/// Returned to the caller after a successful save.
class ChannelLabelResult {
  const ChannelLabelResult({required this.label, this.unit});

  final String label;
  final String? unit;
}

/// Renames a device channel (and sets its unit) through
/// `POST /api/device-channel/{device_id}/channel-mapping`. Owner/manager
/// only; the backend returns 403 otherwise.
class EditSensorNameScreen extends StatefulWidget {
  final int deviceId;
  final String sensorKey;
  final String currentLabel;
  final String? currentUnit;

  const EditSensorNameScreen({
    super.key,
    required this.deviceId,
    required this.sensorKey,
    required this.currentLabel,
    this.currentUnit,
  });

  @override
  State<EditSensorNameScreen> createState() => _EditSensorNameScreenState();
}

class _EditSensorNameScreenState extends State<EditSensorNameScreen> {
  final DeviceService _devices = DeviceService();

  late final TextEditingController controller;
  late final TextEditingController unitController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.currentLabel == widget.sensorKey ? '' : widget.currentLabel,
    );
    unitController = TextEditingController(text: widget.currentUnit ?? '');
  }

  @override
  void dispose() {
    controller.dispose();
    unitController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final label = controller.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await _devices.saveChannelMapping(
        deviceId: widget.deviceId,
        channelKey: widget.sensorKey,
        label: label,
        unit: unitController.text,
      );

      if (!mounted) return;
      showSuccess(context, 'Channel saved');
      final unit = unitController.text.trim();
      Navigator.pop(
        context,
        ChannelLabelResult(label: label, unit: unit.isEmpty ? null : unit),
      );
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rename ${widget.sensorKey}")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Tank name",
                helperText: 'For example "Diesel tank 1"',
                prefixIcon: Icon(Icons.propane_tank_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: "Raw value unit (optional)",
                helperText: 'Shown for uncalibrated values, e.g. "cm". '
                    'Calibrated values are always in liters.',
                helperMaxLines: 2,
                prefixIcon: Icon(Icons.straighten),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: saving ? null : save,
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
