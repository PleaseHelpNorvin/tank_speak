import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/company_service.dart';
import '../../services/invitation_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';
import '../auth/login_screen.dart';
import '../landing_screen.dart';
import 'create_company_screen.dart';
import 'main_shell.dart';
import 'invitations_screen.dart';

/// Start-up: restores the stored session and decides where the user goes.
///
/// * no/invalid token          -> landing / sign-in
/// * administrator account     -> sign-in with an explanation
/// * belongs to a company      -> companies
/// * no company, invitations   -> invitations
/// * no company, no invitation -> create a company
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _auth = AuthService.instance;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);

    try {
      final result = await _auth.restore();
      if (!mounted) return;

      switch (result) {
        case SessionRestore.signedOut:
          _goTo(const LandingScreen());
          return;
        case SessionRestore.adminBlocked:
          _goTo(LoginScreen(notice: _auth.takeSessionEndedMessage()));
          return;
        case SessionRestore.signedIn:
          await _routeSignedInUser();
          return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<void> _routeSignedInUser() async {
    final me = _auth.me!;
    final companies = await CompanyService().fetchCompanies(size: 1);
    if (!mounted) return;

    if (companies.total > 0 || companies.items.isNotEmpty) {
      _goTo(MainShell(me: me));
      return;
    }

    final invites = await InvitationService().fetchReceived(size: 1);
    if (!mounted) return;

    if (invites.items.isNotEmpty) {
      _goTo(InvitationsScreen(me: me, isOnboarding: true));
    } else {
      _goTo(CreateCompanyScreen(me: me, isOnboarding: true));
    }
  }

  void _goTo(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _signOut() async {
    await _auth.logout();
    if (!mounted) return;
    _goTo(const LandingScreen());
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      body: SafeArea(
        child: error == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(size: 84),
                    const SizedBox(height: 20),
                    Text('TankSpeak', style: context.text.headlineMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Loading your workspace…',
                      style: context.text.bodyMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(child: ErrorView(error: error, onRetry: _start)),
                  if (error is ApiException &&
                      error.kind != ApiErrorKind.configuration)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: TextButton(
                        onPressed: _signOut,
                        child: const Text('Sign out'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
