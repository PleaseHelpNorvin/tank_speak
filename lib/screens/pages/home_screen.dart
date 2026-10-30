import 'package:flutter/material.dart';

import '../../models/company.dart';
import '../../models/gas_station.dart';
import '../../models/me_response.dart';
import '../../models/member.dart';
import '../../services/company_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';
import 'company_detail_screen.dart';
import 'create_company_screen.dart';
import 'station_detail_screen.dart';

/// Overview: greeting, quick stats, the stations the user owns or manages,
/// and every company the user belongs to.
class HomeScreen extends StatefulWidget {
  final MeResponse me;

  /// True when shown as a tab of [MainShell] (no back button).
  final bool inShell;

  const HomeScreen({super.key, required this.me, this.inShell = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CompanyService _companies = CompanyService();

  static const int pageSize = 10;

  List<Company> companies = [];
  bool isLoading = true;
  Object? error;
  int currentPage = 1;
  int total = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData({int page = 1}) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response =
          await _companies.fetchCompanies(page: page, size: pageSize);
      if (!mounted) return;
      setState(() {
        companies = response.items;
        currentPage = response.page;
        total = response.total;
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

  /// Highest role in this company according to `/api/me` (plain member
  /// stations are not listed there).
  StationRole _roleIn(Company company) {
    if (widget.me.ownerStations.any((s) => s.companyId == company.id)) {
      return StationRole.owner;
    }
    if (widget.me.managerStations.any((s) => s.companyId == company.id)) {
      return StationRole.manager;
    }
    return StationRole.member;
  }

  List<GasStation> get _myStations {
    final seen = <int>{};
    return [
      ...widget.me.ownerStations,
      ...widget.me.managerStations,
    ].where((s) => seen.add(s.id)).toList();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final first = widget.me.displayName.split(' ').first;
    return first.isEmpty ? part : '$part, $first';
  }

  Future<void> _createCompany() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateCompanyScreen(me: widget.me)),
    );
    if (created == true && mounted) loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCompany,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('New company'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => loadData(page: currentPage),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header()),
              ..._body(),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final stations = _myStations;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.inShell) ...[
                const BackButton(),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting, style: context.text.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Here is how your stations are doing.',
                      style: context.text.bodyMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const BrandMark(size: 40),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat('Companies', isLoading && companies.isEmpty ? '–' : '$total',
                  Icons.apartment_outlined),
              const SizedBox(width: 10),
              _stat('You own', '${widget.me.ownerStations.length}',
                  Icons.workspace_premium_outlined),
              const SizedBox(width: 10),
              _stat('You manage', '${widget.me.managerStations.length}',
                  Icons.manage_accounts_outlined),
            ],
          ),
          if (stations.isNotEmpty) ...[
            const SectionTitle('Your stations'),
            ...stations.map(_stationTile),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: context.colors.primary),
              const SizedBox(height: 10),
              Text(value, style: context.text.headlineSmall),
              Text(label,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stationTile(GasStation station) {
    final role = widget.me.ownsStation(station.id)
        ? StationRole.owner
        : StationRole.manager;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StationDetailScreen(station: station, me: widget.me),
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
                Text(station.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
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

  List<Widget> _body() {
    if (isLoading && companies.isEmpty) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: LoadingView()),
      ];
    }

    if (error != null && companies.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
              error: error!, onRetry: () => loadData(page: currentPage)),
        ),
      ];
    }

    if (companies.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.apartment_outlined,
            title: 'No companies yet',
            message: 'Create a company, or accept an invitation to join '
                'a station.',
            action: FilledButton.tonalIcon(
              onPressed: _createCompany,
              icon: const Icon(Icons.add),
              label: const Text('Create company'),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.list(
          children: [
            const SectionTitle('Companies'),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoBanner(
                  message: error.toString(),
                  icon: Icons.error_outline,
                  color: context.status.danger,
                ),
              ),
            ...companies.map(_companyCard),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: PaginationBar(
          currentPage: currentPage,
          total: total,
          pageSize: pageSize,
          onPrev: () => loadData(page: currentPage - 1),
          onNext: () => loadData(page: currentPage + 1),
        ),
      ),
    ];
  }

  Widget _companyCard(Company company) {
    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CompanyDetailScreen(companyId: company.id, me: widget.me),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(Icons.apartment_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.name,
                        style: context.text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      company.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RolePill(_roleIn(company)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (company.phone.isNotEmpty)
                _meta(Icons.phone_outlined, company.phone),
              if (company.businessHours.isNotEmpty)
                _meta(Icons.schedule_outlined, company.businessHours),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
        ),
      ],
    );
  }
}
