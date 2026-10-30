import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/connectivity.dart';
import '../../models/gas_station.dart';
import '../../models/invitation.dart';
import '../../models/me_response.dart';
import '../../models/member.dart';
import '../../models/tank.dart';
import '../../services/access.dart';
import '../../services/invitation_service.dart';
import '../../services/station_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/auto_refresh.dart';
import '../../widgets/state_views.dart';
import 'ble_provision_screen.dart';
import 'calibration_list_screen.dart';
import 'device_detail_screen.dart';
import 'tank_detail_screen.dart';

/// Station overview: info, subscription, people, devices with connectivity
/// and the latest calibrated tank readings. Refreshes automatically.
class StationDetailScreen extends StatefulWidget {
  final GasStation station;
  final MeResponse me;

  /// Company owners manage every station of their company.
  final bool isCompanyOwner;

  const StationDetailScreen({
    super.key,
    required this.station,
    required this.me,
    this.isCompanyOwner = false,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen>
    with AutoRefreshMixin<StationDetailScreen> {
  final StationService _stations = StationService();

  StationDetailResponse? station;
  bool isLoading = true;
  Object? error;
  DateTime? lastUpdated;


  @override
  void initState() {
    super.initState();
    loadStation();
    startAutoRefresh();
  }

  @override
  Future<void> onAutoRefresh() => loadStation(silent: true);

  bool _inFlight = false;

  Future<void> loadStation({bool silent = false}) async {
    if (_inFlight) return;
    _inFlight = true;
    if (!silent) {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    try {
      final result =
          await _stations.getStationWithDeviceStatus(widget.station.id);
      if (!mounted) return;
      setState(() {
        station = result;
        error = null;
        isLoading = false;
        lastUpdated = DateTime.now().toUtc();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e;
        isLoading = false;
      });
    } finally {
      _inFlight = false;
    }
  }

  StationRole get role => stationRoleFor(
        widget.me,
        widget.station.id,
        detail: station,
        isCompanyOwner: widget.isCompanyOwner,
      );

  @override
  Widget build(BuildContext context) {
    final data = station;

    return Scaffold(
      appBar: AppBar(
        title: Text(data?.station.name ?? widget.station.name),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : () => loadStation(),
          ),
        ],
      ),
      body: _buildBody(data),
    );
  }

  Widget _buildBody(StationDetailResponse? data) {
    if (data == null) {
      if (error != null) {
        return ErrorView(error: error!, onRetry: () => loadStation());
      }
      return const LoadingView();
    }

    final canManage = role.canManageStation;

    return RefreshIndicator(
      onRefresh: () => loadStation(silent: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (error != null) ...[
            InfoBanner(
              icon: Icons.cloud_off_outlined,
              color: context.status.warning,
              message: 'Could not refresh: ${error.toString()}\n'
                  'Showing data loaded ${Fmt.ago(lastUpdated)}.',
            ),
            const SizedBox(height: 12),
          ],
          _heroCard(data),
          const SizedBox(height: 12),
          _actions(data, canManage),

          SectionTitle(
            'Tanks',
            trailing: Text(
              lastUpdated == null ? '' : 'Updated ${Fmt.time(lastUpdated)}',
              style: context.text.labelSmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
          if (data.devices.isEmpty)
            AppCard(
              child: EmptyView(
                icon: Icons.sensors_off_outlined,
                title: 'No devices yet',
                message: canManage
                    ? 'Use "Add device" to provision a Norvi controller '
                        'over Bluetooth and register it here.'
                    : 'No devices are registered to this station yet.',
              ),
            ),
          ...data.devices.map((d) => _deviceSection(data, d)),

          const SectionTitle('Station details'),
          AppCard(child: _infoSection(data)),

          SectionTitle('People',
              trailing: Text(
                '${(data.owner == null ? 0 : 1) + data.members.length}',
                style: context.text.labelLarge
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              )),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _peopleSection(data),
          ),
        ],
      ),
    );
  }

  Widget _heroCard(StationDetailResponse data) {
    final s = data.station;
    final sub = data.subscription;

    final Widget subscriptionPill;
    if (sub == null) {
      subscriptionPill = StatusPill(
          label: 'No subscription',
          color: context.status.neutral,
          icon: Icons.card_membership_outlined);
    } else if (sub.isExpired) {
      subscriptionPill = StatusPill(
          label: 'Expired ${Fmt.date(sub.expiresAt)}',
          color: context.status.danger,
          icon: Icons.card_membership_outlined);
    } else {
      subscriptionPill = StatusPill(
          label: 'Active until ${Fmt.date(sub.expiresAt)}',
          color: context.status.success,
          icon: Icons.card_membership_outlined);
    }

    final alerts = data.devices
        .expand((d) => d.channels)
        .where((c) =>
            c.status == ChannelStatus.dryAlert ||
            c.status == ChannelStatus.refillAlert)
        .length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(Icons.local_gas_station_outlined, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: context.text.titleLarge),
                    if (s.address.isNotEmpty)
                      Text(s.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RolePill(role),
              subscriptionPill,
              StatusPill(
                label: '${data.devices.length} '
                    '${data.devices.length == 1 ? 'device' : 'devices'}',
                color: context.colors.primary,
                icon: Icons.memory,
              ),
              if (alerts > 0)
                StatusPill(
                  label: '$alerts ${alerts == 1 ? 'alert' : 'alerts'}',
                  color: context.status.danger,
                  icon: Icons.warning_amber_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(StationDetailResponse data, bool canManage) {
    final lookups = OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CalibrationListScreen(me: widget.me),
          ),
        );
      },
      icon: const Icon(Icons.table_chart_outlined),
      label: const Text("Lookup tables"),
    );

    if (!canManage) return lookups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BleProvisionScreen(station: data.station),
                    ),
                  );
                  if (mounted) loadStation(silent: true);
                },
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text("Add device"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: () => _openInviteSheet(context, data.station),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text("Invite"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        lookups,
      ],
    );
  }

  Widget _infoSection(StationDetailResponse data) {
    final s = data.station;
    return Column(
      children: [
        InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: s.address),
        InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: s.phone),
        InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Hours',
            value: s.businessHours),
        if (s.extendedBusinessHours != null)
          InfoRow(
              icon: Icons.more_time,
              label: 'Extended',
              value: s.extendedBusinessHours!),
        InfoRow(
            icon: Icons.manage_accounts_outlined,
            label: 'Manager',
            value: data.manager?.displayName ?? 'None'),
      ],
    );
  }

  Widget _peopleSection(StationDetailResponse data) {
    final rows = <Widget>[
      if (data.owner != null)
        _personTile(data.owner!.displayName, StationRole.owner,
            isMe: data.owner!.id == widget.me.id),
      ...data.members.map((m) => _personTile(
            m.person.displayName,
            m.role,
            rawRole: m.rawRole,
            isMe: m.person.id == widget.me.id,
          )),
    ];
    if (rows.isEmpty) {
      return const ListTile(title: Text('No people listed'));
    }
    return Column(children: rows);
  }

  Widget _personTile(String name, StationRole? role,
      {String? rawRole, bool isMe = false}) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colors.primaryContainer,
        foregroundColor: context.colors.onPrimaryContainer,
        child: Text(initial),
      ),
      title: Text(isMe ? '$name (you)' : name),
      trailing: role != null
          ? RolePill(role)
          : StatusPill(
              label: rawRole ?? 'Unknown', color: context.status.neutral),
    );
  }

  Widget _deviceSection(StationDetailResponse data, StationDevice item) {
    final device = item.device;
    final connectivity = DeviceConnectivity.evaluate(
      isActive: device.isActive,
      lastSeen: device.lastSeen,
      lastPayloadAt: item.payloadCreatedAt,
    );
    final live = connectivity.readingsAreLive;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(Brand.radiusSmall),
            onTap: () => _openDevice(data, item),
            child: Row(
              children: [
                IconTile(Icons.memory,
                    color: connectivityColor(context, connectivity.state)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall),
                      Text(
                        connectivity.lastContact == null
                            ? device.deviceKey
                            : 'Last contact ${Fmt.ago(connectivity.lastContact)}',
                        style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                ConnectivityBadge(connectivity),
                Icon(Icons.chevron_right,
                    color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
          if (!live) ...[
            const SizedBox(height: 12),
            InfoBanner(
              message: connectivity.summary,
              icon: Icons.info_outline,
              color: connectivityColor(context, connectivity.state),
            ),
          ],
          const SizedBox(height: 14),
          if (item.channels.isEmpty)
            Text('No sensor readings received yet.',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant))
          else
            LayoutBuilder(builder: (context, constraints) {
              const gap = 10.0;
              final columns = constraints.maxWidth >= 520 ? 3 : 2;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: item.channels
                    .map((c) => SizedBox(
                          width: width,
                          child: _tankTile(data, item, c, live),
                        ))
                    .toList(),
              );
            }),
          if (item.payloadCreatedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Reading time ${Fmt.dateTime(item.payloadCreatedAt)}',
              style: context.text.labelSmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tankTile(StationDetailResponse data, StationDevice item,
      ChannelReading channel, bool live) {
    final color = channelStatusColor(context, channel.status);
    final valueText = channel.value != null
        ? Fmt.number(channel.value)
        : (channel.rawValue?.toString() ?? '—');
    final unit = channel.value != null ? channel.displayUnit : null;
    final faded = context.colors.onSurfaceVariant;

    return Material(
      color: context.colors.surfaceContainerHigh.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TankDetailScreen(
                me: widget.me,
                device: item.device,
                channelKey: channel.key,
                channelLabel: channel.label,
                channelUnit: channel.unit,
                activeCalibProfileId: channel.calibrationProfileId,
                stationId: data.station.id,
                canManage: role.canManageStation,
                lastPayloadAt: item.payloadCreatedAt,
              ),
            ),
          );
          if (mounted) loadStation(silent: true);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.propane_tank_outlined,
                      size: 18, color: live ? context.colors.primary : faded),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(channel.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelLarge),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: valueText,
                      style: context.text.headlineSmall?.copyWith(
                        color: live ? context.colors.onSurface : faded,
                      ),
                    ),
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: context.text.bodyMedium?.copyWith(color: faded),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              StatusPill(label: channel.status.label, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _openDevice(StationDetailResponse data, StationDevice item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(
          me: widget.me,
          stationDevice: item,
          stationId: data.station.id,
          canManage: role.canManageStation,
        ),
      ),
    );
  }

  void _openInviteSheet(BuildContext context, GasStation station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InviteSheet(station: station),
    );
  }
}

/// Look up a user by invite code and invite them as manager or member.
class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.station});

  final GasStation station;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final InvitationService _invites = InvitationService();
  final TextEditingController _code = TextEditingController();

  InviteCodeLookup? _found;
  bool _searching = false;
  bool _sending = false;
  bool _sent = false;
  String? _message;
  bool _messageIsError = false;
  StationRole _role = StationRole.member;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _searching = true;
      _found = null;
      _sent = false;
      _message = null;
    });

    try {
      final result = await _invites.lookupInviteCode(code);
      if (!mounted) return;
      setState(() {
        _found = result;
        if (result == null) {
          _message = 'No user has this invite code.';
          _messageIsError = true;
        } else if (result.alreadyInvitedByMe) {
          _message = 'You have already invited this person'
              '${result.invitedToCompanyName == null ? '' : ' to ${result.invitedToCompanyName}'}. '
              'Inviting them to another station is still possible.';
          _messageIsError = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.toString();
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _send() async {
    final found = _found;
    if (found == null) return;

    setState(() {
      _sending = true;
      _message = null;
    });

    try {
      final message = await _invites.sendInvitation(
        code: found.inviteCode,
        role: _role,
        stationId: widget.station.id,
        companyId: widget.station.companyId,
      );
      if (!mounted) return;
      setState(() {
        _sent = true;
        _message = message;
        _messageIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.toString();
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final found = _found;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Invite to ${widget.station.name}",
                style: context.text.titleLarge),
            const SizedBox(height: 4),
            Text(
              "Ask the person for the invite code shown on their Profile.",
              style: context.text.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _code,
              textInputAction: TextInputAction.search,
              onChanged: (_) {
                if (_found != null || _message != null) {
                  setState(() {
                    _found = null;
                    _sent = false;
                    _message = null;
                  });
                }
              },
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: "Invite code",
                prefixIcon: const Icon(Icons.qr_code_2),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Find person',
                        icon: const Icon(Icons.search),
                        onPressed: _search,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Role', style: context.text.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<StationRole>(
              showSelectedIcon: false,
              segments: InvitationService.invitableRoles
                  .map((r) => ButtonSegment<StationRole>(
                        value: r,
                        label: Text(r.label),
                        icon: Icon(r == StationRole.manager
                            ? Icons.manage_accounts_outlined
                            : Icons.person_outline),
                      ))
                  .toList(),
              selected: {_role},
              onSelectionChanged: _sent
                  ? null
                  : (selection) => setState(() => _role = selection.first),
            ),
            const SizedBox(height: 8),
            Text(
              'A station can have one manager. Managers can invite people and '
              'manage devices; members can view the station.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            if (found != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.colors.primaryContainer,
                    foregroundColor: context.colors.onPrimaryContainer,
                    child: Text(
                        found.name.isEmpty ? '?' : found.name[0].toUpperCase()),
                  ),
                  title: Text(found.name),
                  subtitle: Text(found.email),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: (_sent || _sending) ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_sent ? Icons.check : Icons.send_outlined),
                label: Text(_sent
                    ? 'Invitation sent'
                    : 'Invite as ${_role.label.toLowerCase()}'),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              InfoBanner(
                message: _message!,
                icon: _messageIsError ? Icons.error_outline : Icons.info_outline,
                color: _messageIsError
                    ? context.status.danger
                    : (_sent ? context.status.success : context.status.info),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
