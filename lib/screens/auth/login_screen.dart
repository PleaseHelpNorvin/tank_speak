import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/api_exception.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';
import '../pages/splash_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.notice});

  /// Optional message shown above the form (e.g. "session expired").
  final String? notice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService auth = AuthService.instance;

  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorText;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => errorText = "Please enter your username and password.");
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      await auth.login(username.text, password.text);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorText = (e is ApiException && e.isNetwork)
            ? '${e.message}\nServer: ${AppConfig.apiBaseUrl}'
            : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BrandMark(size: 56),
                  ),
                  const SizedBox(height: 28),
                  Text("Welcome to TankSpeak",
                      style: context.text.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to monitor your fuel system",
                    style: context.text.bodyLarge
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  if (widget.notice != null) ...[
                    InfoBanner(message: widget.notice!),
                    const SizedBox(height: 16),
                  ],
                  if (errorText != null) ...[
                    InfoBanner(
                      message: errorText!,
                      icon: Icons.error_outline,
                      color: context.status.danger,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: username,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: "Username",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: password,
                    obscureText: obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => isLoading ? null : login(),
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip:
                            obscurePassword ? 'Show password' : 'Hide password',
                        icon: Icon(obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: isLoading ? null : login,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text("Sign In"),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?",
                          style: context.text.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text("Create one"),
                      ),
                    ],
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
