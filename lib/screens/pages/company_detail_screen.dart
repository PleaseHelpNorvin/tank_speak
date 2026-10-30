import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/company.dart';
import '../../models/gas_station.dart';
import '../../models/me_response.dart';
import '../../models/member.dart';
import '../../services/access.dart';
import '../../services/company_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/state_views.dart';
import 'create_gas_station_screen.dart';
import 'station_detail_screen.dart';

/// Company information, its stations visible to the user, contacts and
/// members. Only the company owner can add stations (backend rule).
class CompanyDetailScreen extends StatefulWidget {
  final int companyId;
  final MeResponse me;

  const CompanyDetailScreen({
    super.key,
    required this.companyId,
    required this.me,
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  final CompanyService _companies = CompanyService();

  CompanyDetailResponse? detail;
  List<CompanyMember> members = [];
  bool isCompanyOwner = false;
  bool isLoading = true;
  bool notFound = false;
  Object? error;

  @override
  void initState() {
    super.initState();
    loadCompany();
  }

  Future<void> loadCompany() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await _companies.getCompany(widget.companyId);

      List<CompanyMember> memberRows = [];
      try {
        memberRows =
            (await _companies.fetchCompanyMembers(widget.companyId)).items;
      } on ApiException catch (e) {
        if (!(e.isForbidden || e.isNotFound)) rethrow;
      }

      if (!mounted) return;
      setState(() {
        detail = response;
        notFound = response == null;
        members = _uniqueMembers(memberRows);
        isCompanyOwner = memberRows.any(
          (m) => m.userId == widget.me.id && m.role == StationRole.owner,
        );
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

  /// The endpoint returns one row per membership (company + each station);
  /// show each person once with their highest role.
  List<CompanyMember> _uniqueMembers(List<CompanyMember> rows) {
    int rank(StationRole? r) => switch (r) {
          StationRole.owner => 3,
          StationRole.manager => 2,
          StationRole.member => 1,
          null => 0,
        };
    final byUser = <int, CompanyMember>{};
    for (final row in rows) {
      final current = byUser[row.userId];
      if (current == null || rank(row.role) > rank(current.role)) {
        byUser[row.userId] = row;
      }
    }
    final list = byUser.values.toList()
      ..sort((a, b) => rank(b.role).compareTo(rank(a.role)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(detail?.company.name ?? "Company")),
      floatingActionButton: (isCompanyOwner && detail != null)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateGasStationScreen(
                      me: widget.me,
                      companyId: widget.companyId,
                      companyName: detail!.company.name,
                    ),
                  ),
                );
                if (created == true && mounted) loadCompany();
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('New station'),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading && detail == null) return const LoadingView();
    if (error != null && detail == null) {
      return ErrorView(error: error!, onRetry: loadCompany);
    }
    if (notFound || detail == null) {
      return const EmptyView(
        icon: Icons.search_off,
        title: 'Company not found',
        message: 'It may have been removed.',
      );
    }

    final company = detail!.company;
    final stations = detail!.stations;

    return RefreshIndicator(
      onRefresh: loadCompany,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconTile(Icons.apartment_outlined, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(company.name,
                          style: context.text.titleLarge),
                    ),
                    if (isCompanyOwner) const RolePill(StationRole.owner),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 6),
                InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: company.address),
                InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: company.phone),
                InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Hours',
                    value: company.businessHours),
                if (company.extendedBusinessHours != null)
                  InfoRow(
                      icon: Icons.more_time,
                      label: 'Extended',
                      value: company.extendedBusinessHours!),
              ],
            ),
          ),
          SectionTitle('Stations',
              trailing: Text('${stations.length}',
                  style: context.text.labelLarge
                      ?.copyWith(color: context.colors.onSurfaceVariant))),
          if (stations.isEmpty)
            AppCard(
              child: Text(
                isCompanyOwner
                    ? 'No stations yet. Tap "New station" to add one.'
                    : 'You have no stations in this company.',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          ...stations.map(_stationTile),
          if (detail!.contacts.isNotEmpty) ...[
            const SectionTitle('Contacts'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: detail!.contacts.map(_contactTile).toList(),
              ),
            ),
          ],
          if (members.isNotEmpty) ...[
            SectionTitle('People',
                trailing: Text('${members.length}',
                    style: context.text.labelLarge
                        ?.copyWith(color: context.colors.onSurfaceVariant))),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: members.map(_memberTile).toList()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stationTile(GasStation station) {
    final role = stationRoleFor(widget.me, station.id,
        isCompanyOwner: isCompanyOwner);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StationDetailScreen(
              station: station,
              me: widget.me,
              isCompanyOwner: isCompanyOwner,
            ),
          ),
        );
      },
      child: Row(
        children: [
          const IconTile(Icons.local_gas_station_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.name,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  station.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RolePill(role),
          Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _contactTile(ContactPerson contact) {
    final details = [contact.position, contact.phone, contact.email]
        .whereType<String>()
        .join(' • ');
    return ListTile(
      leading: const Icon(Icons.contact_phone_outlined),
      title: Text(contact.name),
      subtitle: details.isEmpty ? null : Text(details),
    );
  }

  Widget _memberTile(CompanyMember member) {
    final isMe = member.userId == widget.me.id;
    final initial =
        member.username.isEmpty ? '?' : member.username[0].toUpperCase();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colors.primaryContainer,
        foregroundColor: context.colors.onPrimaryContainer,
        child: Text(initial),
      ),
      title: Text(isMe ? '${member.username} (you)' : member.username),
      trailing: member.role != null
          ? RolePill(member.role!)
          : StatusPill(label: member.roleLabel, color: context.status.neutral),
    );
  }
}
