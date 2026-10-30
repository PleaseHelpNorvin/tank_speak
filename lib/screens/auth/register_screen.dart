import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService auth = AuthService.instance;

  final TextEditingController username = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  String? errorText;

  @override
  void dispose() {
    username.dispose();
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    if (email.text.trim().isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty ||
        username.text.trim().isEmpty ||
        name.text.trim().isEmpty) {
      setState(() => errorText = "Please fill in all fields.");
      return;
    }

    if (password.text != confirmPassword.text) {
      setState(() => errorText = "Passwords do not match.");
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      await auth.register(
        username: username.text,
        name: name.text,
        email: email.text,
        password: password.text,
      );
      if (!mounted) return;
      showSuccess(context, "Account created. You can now sign in.");
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => errorText = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? onToggle,
    List<String>? autofill,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        autocorrect: false,
        autofillHints: autofill,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onToggle == null
              ? null
              : IconButton(
                  icon: Icon(obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: onToggle,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Create your account",
                      style: context.text.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    "Join a station with an invitation, or create your own company.",
                    style: context.text.bodyLarge
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  if (errorText != null) ...[
                    InfoBanner(
                      message: errorText!,
                      icon: Icons.error_outline,
                      color: context.status.danger,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _field(name, "Full name", Icons.badge_outlined,
                      autofill: const [AutofillHints.name]),
                  _field(username, "Username", Icons.person_outline,
                      autofill: const [AutofillHints.newUsername]),
                  _field(email, "Email", Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      autofill: const [AutofillHints.email]),
                  _field(password, "Password", Icons.lock_outline,
                      obscure: obscurePassword,
                      autofill: const [AutofillHints.newPassword],
                      onToggle: () =>
                          setState(() => obscurePassword = !obscurePassword)),
                  _field(confirmPassword, "Confirm password",
                      Icons.lock_reset_outlined,
                      obscure: obscureConfirm,
                      onToggle: () =>
                          setState(() => obscureConfirm = !obscureConfirm)),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: isLoading ? null : handleRegister,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text("Create account"),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("I already have an account"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
