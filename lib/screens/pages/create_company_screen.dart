import 'package:flutter/material.dart';

import '../../models/me_response.dart';
import '../../services/company_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';
import 'invitations_screen.dart';
import 'profile_screen.dart';
import 'splash_screen.dart';

/// `POST /api/company/create`. The creating user becomes the company owner.
class CreateCompanyScreen extends StatefulWidget {
  final MeResponse me;

  /// True when shown at start-up to a user without any company.
  final bool isOnboarding;

  const CreateCompanyScreen({
    super.key,
    required this.me,
    this.isOnboarding = false,
  });

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final CompanyService _companies = CompanyService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController businessHoursController = TextEditingController();
  final TextEditingController extendedHoursController = TextEditingController();

  bool isLoading = false;

  Future<void> createCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await _companies.createCompany(
        name: nameController.text,
        address: addressController.text,
        phone: phoneController.text,
        businessHours: businessHoursController.text,
        extendedBusinessHours: extendedHoursController.text,
      );

      if (!mounted) return;
      showSuccess(context, response.message);

      if (widget.isOnboarding) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool required = true,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: required ? label : '$label (optional)',
          prefixIcon: icon == null ? null : Icon(icon),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    businessHoursController.dispose();
    extendedHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New company"),
        automaticallyImplyLeading: !widget.isOnboarding,
        actions: [
          if (widget.isOnboarding) ...[
            IconButton(
              tooltip: 'Invitations',
              icon: const Icon(Icons.mail_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => InvitationsScreen(
                          me: widget.me, isOnboarding: true)),
                );
              },
            ),
            IconButton(
              tooltip: 'Profile',
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProfileScreen(me: widget.me)),
                );
              },
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isOnboarding) ...[
                  const InfoBanner(
                    message: "You don't belong to a company yet. Create one "
                        "to become its owner, or open Invitations if someone "
                        "invited you to their station.",
                  ),
                  const SizedBox(height: 20),
                ],
                Text('Company details', style: context.text.titleMedium),
                const SizedBox(height: 4),
                Text('You will be the owner of this company.',
                    style: context.text.bodyMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
                const SizedBox(height: 20),
                inputField("Company name", nameController,
                    icon: Icons.apartment_outlined),
                inputField("Address", addressController,
                    maxLines: 2, icon: Icons.location_on_outlined),
                inputField("Phone", phoneController,
                    type: TextInputType.phone, icon: Icons.phone_outlined),
                inputField("Business hours", businessHoursController,
                    icon: Icons.schedule_outlined),
                inputField("Extended business hours", extendedHoursController,
                    required: false, icon: Icons.more_time),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: isLoading ? null : createCompany,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text("Create company"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
