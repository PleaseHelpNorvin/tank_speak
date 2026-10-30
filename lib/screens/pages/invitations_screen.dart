import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../models/invitation.dart';
import '../../models/me_response.dart';
import '../../services/auth_service.dart';
import '../../services/company_service.dart';
import '../../services/invitation_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';
import 'splash_screen.dart';

/// Received invitations (accept / decline) and invitations the user sent
/// (cancel). The backend keeps accepted invitations and deletes declined or
/// cancelled ones; "Accepted" is shown when the user already has access to
/// the invited station.
class InvitationsScreen extends StatefulWidget {
  final MeResponse me;

  /// True when shown at start-up to a user without a company.
  final bool isOnboarding;

  /// True when shown as a tab of the main shell (no back button).
  final bool inShell;

  const InvitationsScreen({
    super.key,
    required this.me,
    this.isOnboarding = false,
    this.inShell = false,
  });

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final InvitationService _invites = InvitationService();
  final CompanyService _companies = CompanyService();

  List<Invitation> received = [];
  List<Invitation> sent = [];
  Set<int> accessibleStationIds = {};
  final Map<int, String> stationNames = {};
  final Map<int, String> companyNames = {};

  bool isLoading = true;
  Object? error;
  Object? sentError;
  final Set<int> busy = {};
  bool joinedSomething = false;

  @override
  void initState() {
    super.initState();
    loadInvitations();
  }

  Future<void> loadInvitations() async {
    setState(() {
      isLoading = true;
      error = null;
      sentError = null;
    });

    try {
      final receivedPage = await _invites.fetchReceived();

      List<Invitation> sentItems = [];
      Object? sentErr;
      try {
        sentItems = (await _invites.fetchSent()).items;
      } catch (e) {
        sentErr = e;
      }

      await _resolveStations([...receivedPage.items, ...sentItems]);

      if (!mounted) return;
      setState(() {
        received = receivedPage.items;
        sent = sentItems;
        sentError = sentErr;
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

  /// Looks up company/station names and which invited stations the user can
  /// already access. Companies the user is not a member of answer 403.
  Future<void> _resolveStations(List<Invitation> all) async {
    final accessible = <int>{...widget.me.managedStationIds};
    final companyIds = all.map((i) => i.companyId).toSet();

    for (final companyId in companyIds) {
      try {
        final detail = await _companies.getCompany(companyId);
        if (detail == null) continue;
        companyNames[companyId] = detail.company.name;
        for (final s in detail.stations) {
          accessible.add(s.id);
          stationNames[s.id] = s.name;
        }
      } on ApiException catch (e) {
        if (e.isUnauthorized) rethrow;
        // 403/404: not a member of that company yet.
      }
    }
    accessibleStationIds = accessible;
  }

  InvitationStatus statusOf(Invitation invite) =>
      accessibleStationIds.contains(invite.stationId)
          ? InvitationStatus.accepted
          : InvitationStatus.pending;

  Future<void> acceptInvite(Invitation invite) async {
    setState(() => busy.add(invite.id));
    try {
      final message = await _invites.accept(invite.id);
      joinedSomething = true;
      try {
        await AuthService.instance.refreshProfile();
      } catch (_) {}
      if (!mounted) return;
      showSuccess(context, message);
      if (widget.isOnboarding) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
        return;
      }
      await loadInvitations();
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    } finally {
      if (mounted) setState(() => busy.remove(invite.id));
    }
  }

  Future<void> deleteInvite(Invitation invite, {required bool isSent}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(isSent ? Icons.cancel_outlined : Icons.do_not_disturb_on_outlined),
        title: Text(isSent ? 'Cancel invitation?' : 'Decline invitation?'),
        content: Text(
          isSent
              ? 'The invitation will be removed.'
              : 'The invitation will be removed. You will need a new '
                  'invitation to join this station later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.status.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isSent ? 'Cancel invitation' : 'Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => busy.add(invite.id));
    try {
      final message = await _invites.delete(invite.id);
      if (!mounted) return;
      showSuccess(context, message);
      await loadInvitations();
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
    } finally {
      if (mounted) setState(() => busy.remove(invite.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        received.where((i) => statusOf(i) == InvitationStatus.pending).length;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Invitations"),
          automaticallyImplyLeading: !widget.inShell,
          actions: [
            if (widget.isOnboarding && joinedSomething)
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                ),
                child: const Text('Continue'),
              ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: isLoading ? null : loadInvitations,
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Received'),
                    if (pending > 0) ...[
                      const SizedBox(width: 6),
                      Badge(label: Text('$pending')),
                    ],
                  ],
                ),
              ),
              Tab(text: 'Sent (${sent.length})'),
            ],
          ),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (isLoading && received.isEmpty && sent.isEmpty) {
      return const LoadingView();
    }
    if (error != null) {
      return ErrorView(error: error!, onRetry: loadInvitations);
    }

    return TabBarView(
      children: [
        _list(
          received,
          empty: const EmptyView(
            icon: Icons.mark_email_unread_outlined,
            title: 'No invitations yet',
            message: 'Share your invite code (Profile) with a station owner '
                'or manager so they can invite you.',
          ),
          builder: (i) => _receivedCard(i),
        ),
        sentError != null
            ? ErrorView(error: sentError!, onRetry: loadInvitations)
            : _list(
                sent,
                empty: const EmptyView(
                  icon: Icons.outgoing_mail,
                  title: 'No sent invitations',
                  message: 'Invite people from a station you own or manage.',
                ),
                builder: (i) => _sentCard(i),
              ),
      ],
    );
  }

  Widget _list(List<Invitation> items,
      {required Widget empty, required Widget Function(Invitation) builder}) {
    return RefreshIndicator(
      onRefresh: loadInvitations,
      child: items.isEmpty
          ? ListView(children: [const SizedBox(height: 60), empty])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: items.length,
              itemBuilder: (_, index) => builder(items[index]),
            ),
    );
  }

  String _stationName(Invitation invite) =>
      stationNames[invite.stationId] ?? 'Station #${invite.stationId}';

  Widget _header(Invitation invite, InvitationStatus? status) {
    final company = companyNames[invite.companyId];
    return Row(
      children: [
        const IconTile(Icons.local_gas_station_outlined),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_stationName(invite), style: context.text.titleSmall),
              Text(
                [
                  if (company != null) company,
                  invite.roleLabel,
                  Fmt.date(invite.createdAt),
                ].join(' • '),
                style: context.text.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (status == InvitationStatus.accepted)
          StatusPill(
              label: 'Accepted',
              color: context.status.success,
              icon: Icons.check)
        else if (status == InvitationStatus.pending)
          StatusPill(
              label: 'Pending',
              color: context.status.warning,
              icon: Icons.schedule),
      ],
    );
  }

  Widget _message(Invitation invite) {
    if (invite.message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Brand.radiusSmall),
      ),
      child: Text(invite.message, style: context.text.bodyMedium),
    );
  }

  Widget _receivedCard(Invitation invite) {
    final status = statusOf(invite);
    final isBusy = busy.contains(invite.id);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(invite, status),
          _message(invite),
          const SizedBox(height: 14),
          if (isBusy)
            const LinearProgressIndicator()
          else if (status == InvitationStatus.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => deleteInvite(invite, isSent: false),
                    child: const Text("Decline"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                    onPressed: () => acceptInvite(invite),
                    icon: const Icon(Icons.check),
                    label: const Text("Accept"),
                  ),
                ),
              ],
            )
          else
            Text(
              'You already have access to this station.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _sentCard(Invitation invite) {
    final isBusy = busy.contains(invite.id);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(invite, null),
          _message(invite),
          const SizedBox(height: 10),
          if (isBusy)
            const LinearProgressIndicator()
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: context.status.danger),
                onPressed: () => deleteInvite(invite, isSent: true),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel invitation'),
              ),
            ),
        ],
      ),
    );
  }
}
