import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';
import '../../models/gas_station.dart';
import '../../models/me_response.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';
import '../landing_screen.dart';

/// The signed-in user's profile (`GET /api/me`) and sign-out.
class ProfileScreen extends StatefulWidget {
  final MeResponse me;

  /// True when shown as a tab of the main shell (no back button).
  final bool inShell;

  const ProfileScreen({super.key, required this.me, this.inShell = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService.instance;
  late MeResponse me = _auth.me ?? widget.me;
  bool refreshing = false;
  bool signingOut = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    try {
      await _auth.refreshProfile();
      if (!mounted) return;
      setState(() => me = _auth.me ?? me);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout),
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use TankSpeak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => signingOut = true);
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerStations = me.ownerStations;
    final managerStations = me.managerStations;
    final initial =
        me.displayName.isEmpty ? '?' : me.displayName[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        automaticallyImplyLeading: !widget.inShell,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: refreshing ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: context.colors.primaryContainer,
                    foregroundColor: context.colors.onPrimaryContainer,
                    child: Text(initial,
                        style: context.text.headlineSmall?.copyWith(
                            color: context.colors.onPrimaryContainer)),
                  ),
                  const SizedBox(height: 12),
                  Text(me.displayName, style: context.text.titleLarge),
                  Text('@${me.username}',
                      style: context.text.bodyMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant)),
                  if (me.email.isNotEmpty)
                    Text(me.email,
                        style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant)),
                ],
              ),
            ),
            AppCard(
              color: context.colors.primaryContainer,
              borderColor: Colors.transparent,
              onTap: () {
                Clipboard.setData(ClipboardData(text: me.inviteCode));
                showSuccess(context, "Invite code copied");
              },
              child: Row(
                children: [
                  Icon(Icons.qr_code_2,
                      size: 32, color: context.colors.onPrimaryContainer),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your invite code',
                            style: context.text.labelMedium?.copyWith(
                                color: context.colors.onPrimaryContainer)),
                        Text(me.inviteCode,
                            style: context.text.headlineSmall?.copyWith(
                                color: context.colors.onPrimaryContainer,
                                letterSpacing: 2)),
                        Text(
                          'Share it so an owner or manager can invite you.',
                          style: context.text.bodySmall?.copyWith(
                              color: context.colors.onPrimaryContainer
                                  .withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.copy, color: context.colors.onPrimaryContainer),
                ],
              ),
            ),
            Row(
              children: [
                _statBox("Stations owned", ownerStations.length.toString(),
                    Icons.workspace_premium_outlined),
                const SizedBox(width: 10),
                _statBox("Stations managed", managerStations.length.toString(),
                    Icons.manage_accounts_outlined),
              ],
            ),
            if (ownerStations.isNotEmpty) ...[
              const SectionTitle("Stations you own"),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: ownerStations.map(_stationTile).toList()),
              ),
            ],
            if (managerStations.isNotEmpty) ...[
              const SectionTitle("Stations you manage"),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child:
                    Column(children: managerStations.map(_stationTile).toList()),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.status.danger,
                side: BorderSide(
                    color: context.status.danger.withValues(alpha: 0.5)),
              ),
              icon: signingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text("Sign out"),
              onPressed: signingOut ? null : logout,
            ),
            const SizedBox(height: 16),
            Text(
              'Server: ${AppConfig.apiBaseUrl}',
              textAlign: TextAlign.center,
              style: context.text.labelSmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stationTile(GasStation s) {
    return ListTile(
      leading: const IconTile(Icons.local_gas_station_outlined, size: 40),
      title: Text(s.name),
      subtitle: Text(
        [s.address, s.businessHours].where((e) => e.isNotEmpty).join(' • '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statBox(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: context.colors.primary),
              const SizedBox(height: 10),
              Text(value, style: context.text.headlineSmall),
              Text(title,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
