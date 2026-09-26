import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../core/currency.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.loadDashboard});
  final Future<Map<String, dynamic>> Function()? loadDashboard;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _period = 0;
  late Future<Map<String, dynamic>> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = _loadDashboard();
  }

  Future<Map<String, dynamic>> _loadDashboard() =>
      widget.loadDashboard?.call() ?? apiClient.dashboard();

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Scaffold(
                body: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Unable to load your dashboard.'),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () =>
                      setState(() => _dashboard = _loadDashboard()),
                  child: const Text('Try again'))
            ])));
          }
          Future<void> logout() async {
            await apiClient.logout();
            if (context.mounted) {
              context.go('/sign-in');
            }
          }

          final data = snapshot.data!;
          final user = data['user'] as Map<String, dynamic>? ?? const {};
          return LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final mobile = constraints.maxWidth < 600;
            return Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              // Keep the drawer in the tree at every breakpoint. Removing an
              // open Drawer during a resize can leave stale framework state.
              drawer: Drawer(child: _Sidebar(onLogout: logout, user: user)),
              body: Row(children: [
                if (!compact)
                  SizedBox(
                      width: 240,
                      child: _Sidebar(onLogout: logout, user: user)),
                Expanded(
                  child: Column(children: [
                    _DashboardHeader(showMenu: compact),
                    Expanded(child: _content(data, mobile: mobile)),
                  ]),
                ),
              ]),
            );
          });
        },
      );

  Widget _content(Map<String, dynamic> data, {required bool mobile}) {
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: EdgeInsets.all(mobile ? 16 : 28),
        sliver: SliverList.list(children: [
          const _HeroBanner(),
          const SizedBox(height: 44),
          _SectionHeader(title: 'Overview', trailing: _MonthFilter()),
          const SizedBox(height: 22),
          _OverviewCards(data: data),
          const SizedBox(height: 42),
          _SectionHeader(
              title: 'Recent shipment',
              trailing: _SmallButton(
                  label: 'See All', onTap: () => context.go('/shipments'))),
          const SizedBox(height: 24),
          _GrowthChart(
              values: (data['monthlyGrowth'] as List<dynamic>? ?? const [])
                  .map((value) => (value as num).toDouble())
                  .toList(),
              period: _period,
              onPeriodChanged: (value) => setState(() => _period = value)),
          const SizedBox(height: 12),
          if ((data['recentShipments'] as List<dynamic>? ?? const []).isEmpty)
            const _DashboardEmptyShipments()
          else
            for (final shipment
                in (data['recentShipments'] as List<dynamic>? ?? const [])
                    .take(3)) ...[
              _ShipmentCard(
                  shipment: shipment as Map<String, dynamic>,
                  onViewMore: () => _showShipmentDetails(context, shipment)),
              const SizedBox(height: 12),
            ],
        ]),
      ),
    ]);
  }
}

class _DashboardEmptyShipments extends StatelessWidget {
  const _DashboardEmptyShipments();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8)),
        child: const Column(children: [
          Icon(Icons.local_shipping_outlined,
              size: 42, color: Color(0xFF9AA3B5)),
          SizedBox(height: 14),
          Text('No shipments yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Your recent shipments will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF737373))),
        ]),
      );
}

Future<void> _showShipmentDetails(
    BuildContext context, Map<String, dynamic> shipment) {
  final rawStatus = shipment['status']?.toString() ?? '';
  final status = rawStatus
      .toLowerCase()
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join('-');
  final statusBackground = switch (rawStatus) {
    'DELAYED' => const Color(0xFFC8F7FA),
    'DELIVERED' || 'PAID' => const Color(0xFFDDF8D8),
    _ => const Color(0xFFFFE2CB),
  };
  final statusForeground = switch (rawStatus) {
    'DELAYED' => const Color(0xFF003337),
    'DELIVERED' || 'PAID' => const Color(0xFF176112),
    _ => const Color(0xFFCB854B),
  };

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: .48),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Expanded(
                      child: Text('Order details',
                          style: TextStyle(
                              color: Color(0xFF171717),
                              fontSize: 24,
                              fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF525252)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    shipment['trackingId']?.toString() ?? '',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 32,
                    runSpacing: 26,
                    children: [
                      SizedBox(
                          width: 270,
                          child: _Detail(
                              label: 'Sender',
                              value: shipment['sender']?.toString() ?? '')),
                      SizedBox(
                          width: 270,
                          child: _Detail(
                              label: 'Receiver',
                              value: shipment['receiver']?.toString() ?? '')),
                      SizedBox(
                          width: 270,
                          child: _LocationDetail(
                              label: 'Pick Up From',
                              value: shipment['pickupLocation']?.toString() ??
                                  '')),
                      SizedBox(
                          width: 270,
                          child: _LocationDetail(
                              label: 'Delivery To',
                              value: shipment['deliveryLocation']?.toString() ??
                                  '')),
                      SizedBox(
                          width: 270,
                          child: _Detail(
                              label: 'Amount',
                              value: formatNaira(shipment['amount']))),
                      SizedBox(
                        width: 270,
                        child: _StatusDetail(
                            status: status,
                            background: statusBackground,
                            foreground: statusForeground),
                      ),
                      SizedBox(
                        width: 270,
                        child: _ProcessingTime(
                            hours: shipment['processingHours'] ?? 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 96,
                      child: _OrderButton('Close',
                          filled: true,
                          onTap: () => Navigator.of(dialogContext).pop()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.showMenu});
  final bool showMenu;

  @override
  Widget build(BuildContext context) => Container(
        height: 88,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: showMenu ? 12 : 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          if (showMenu) ...[
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite & Earn',
                    textAlign: TextAlign.left,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                  'Keep track of your addresses, location updates. Edit, Delete, Update and see all your saved addresses',
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
                ),
              ],
            ),
          ),
        ]),
      );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.onLogout, required this.user});
  final VoidCallback onLogout;
  final Map<String, dynamic> user;
  static const items = [
    ('Dashboard', 'assets/layout-dashboard.svg'),
    ('Shipments', 'assets/ship.svg'),
    ('Our Services', 'assets/globe.svg'),
    ('Notifications', 'assets/bell.svg'),
    ('Wallet', 'assets/credit-card.svg'),
    ('My Addresses', 'assets/locate-fixed.svg'),
    ('Invite & Earn', 'assets/badge-dollar-sign.svg'),
    ('Help Center', 'assets/hand-helping.svg'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          color: Colors.white,
          foregroundDecoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: Column(children: [
            Container(
              height: 88,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
            ),
            Expanded(child: _SidebarBody(onLogout: onLogout, user: user)),
          ]),
        ),
      );
}

class _SidebarBody extends StatelessWidget {
  const _SidebarBody({required this.onLogout, required this.user});
  final VoidCallback onLogout;
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    const visibleItems = _Sidebar.items;
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
        sliver: SliverList.builder(
          itemCount: visibleItems.length,
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NavItem(
                label: item.$1,
                icon: item.$2,
                selected: item.$1 == 'Dashboard',
                onTap: item.$1 == 'Dashboard'
                    ? () => context.go('/dashboard')
                    : item.$1 == 'Shipments'
                        ? () => context.go('/shipments')
                        : null,
              ),
            );
          },
        ),
      ),
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Row(children: [
              _ProfileAvatar(url: user['profileImageUrl']?.toString()),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    '${user['firstName'] ?? ''}\n${user['lastName'] ?? ''}',
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(height: 1.6, color: Color(0xFF626262))),
              ),
            ]),
            const SizedBox(height: 26),
            InkWell(
              onTap: onLogout,
              child: Row(children: [
                SvgPicture.asset('assets/log-out.svg', width: 24),
                const SizedBox(width: 10),
                const Text('Logout')
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.trim().isNotEmpty;
    return CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFFEDEFFC),
      backgroundImage: hasImage ? NetworkImage(url!) : null,
      child: hasImage
          ? null
          : const Icon(Icons.person_outline, color: AppColors.primary),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.label,
      required this.icon,
      required this.selected,
      this.onTap});
  final String label, icon;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
              color: selected ? AppColors.primaryDark : Colors.transparent,
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            SvgPicture.asset(icon,
                width: 22,
                colorFilter: selected
                    ? const ColorFilter.mode(Color(0xFFEBFFE2), BlendMode.srcIn)
                    : null),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF626262),
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w400)),
            ),
          ]),
        ),
      );
}

class _HeroBanner extends StatefulWidget {
  const _HeroBanner();

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  static const messages = [
    'KEEP UP WITH YOUR\nBUSINESS NEEDS',
    'SHIP SMARTER TO\nOVER 300 COUNTRIES',
    'TRACK EVERY DELIVERY\nWITH CONFIDENCE',
  ];
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % messages.length,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 267,
          child: Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.07),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0xFF262A48)),
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          Color(0xFF262A48), BlendMode.multiply),
                      child: Image.asset('assets/banner-background.jpg',
                          fit: BoxFit.cover),
                    ),
                    PageView.builder(
                      controller: _controller,
                      itemCount: messages.length,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.fromLTRB(36, 24, 20, 30),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(messages[index],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      height: 1.1,
                                      fontWeight: FontWeight.w800)),
                            ),
                            if (constraints.maxWidth > 560)
                              SizedBox(
                                width: (constraints.maxWidth * .36)
                                    .clamp(180.0, 360.0),
                                child: Image.asset(
                                    'assets/earth-boxes-cardboard-texture 1.png',
                                    fit: BoxFit.contain),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                messages.length,
                (index) => GestureDetector(
                  onTap: () => _controller.animateToPage(index,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _page
                          ? AppColors.primaryDark
                          : const Color(0xFFD9D9D9),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});
  final String title;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 12),
        trailing,
      ]);
}

class _MonthFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 128,
      height: 34,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(8)),
        child: const Row(children: [
          Expanded(
            child: Text('This Month',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Color(0xFF737373),
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w500)),
          ),
          SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF737373)),
        ]),
      ));
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final metrics = data['metrics'] as Map<String, dynamic>? ?? const {};
        final narrow = constraints.maxWidth < 980;
        final cards = [
          _BalanceCard(balance: data['balance']?.toString() ?? '0.00'),
          _MetricCard(
              label: 'Total Shipment',
              value: '${metrics['totalShipments'] ?? 0}',
              iconAsset: 'assets/Truck.svg',
              tint: const Color(0xFFF4E3C4)),
          _MetricCard(
              label: 'Total Exports',
              value: '${metrics['totalExports'] ?? 0}',
              iconAsset: 'assets/ArrowUp.svg',
              tint: const Color(0xFFD9FFD7)),
          _MetricCard(
              label: 'Total Import',
              value: '${metrics['totalImports'] ?? 0}',
              iconAsset: 'assets/ArrowDown.svg',
              tint: const Color(0xFFD7FDFF)),
        ];
        if (narrow) {
          return Column(children: [
            for (final card in cards)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                      width: double.infinity, height: 163, child: card))
          ]);
        }
        return SizedBox(
          height: 163,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(flex: 448, child: cards[0]),
            for (var i = 1; i < cards.length; i++) ...[
              const SizedBox(width: 20),
              Expanded(flex: 211, child: cards[i]),
            ],
          ]),
        );
      });
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final String balance;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFF5A65AB),
            borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your Balance',
              style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w300)),
          const SizedBox(height: 8),
          Text(formatNaira(balance),
              style: const TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 24,
                  height: 1,
                  letterSpacing: -0.48,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: const Text('Fund Wallet',
                style: TextStyle(
                    color: Color(0xFF5A65AB),
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.iconAsset,
      required this.tint});
  final String label, value;
  final String iconAsset;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: SvgPicture.asset(iconAsset, width: 24, height: 24)),
            const SizedBox(width: 10),
            Flexible(
                child: Text(label,
                    style: const TextStyle(
                        color: Color(0xFF525252),
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w400)))
          ]),
          const Spacer(),
          Row(children: [
            Text(value,
                style: const TextStyle(
                    color: Color(0xFF353535),
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Text('↑ 90%',
                style: TextStyle(
                    color: Color(0xFF188D13),
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w500))
          ]),
          const Spacer(),
          const Text.rich(TextSpan(children: [
            TextSpan(
                text: 'Vs last month: ',
                style: TextStyle(
                    fontSize: 8,
                    height: 2,
                    letterSpacing: 0.032,
                    color: Color(0xFF8F8F8F),
                    fontWeight: FontWeight.w400)),
            TextSpan(
                text: '4',
                style: TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    letterSpacing: 0.055,
                    color: Color(0xFF525252),
                    fontWeight: FontWeight.w500)),
          ])),
        ]),
      );
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart(
      {required this.values,
      required this.period,
      required this.onPeriodChanged});
  final List<double> values;
  final int period;
  final ValueChanged<int> onPeriodChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return Container(
            height: compact ? 420 : 374,
            padding: EdgeInsets.fromLTRB(
                compact ? 12 : 20, 16, compact ? 12 : 20, 16),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              if (compact) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _ChartTitle(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: _PeriodSelector(
                      selected: period,
                      onChanged: onPeriodChanged,
                      expand: true),
                ),
              ] else
                SizedBox(
                  height: 40,
                  child: Row(children: [
                    const _ChartTitle(),
                    const Spacer(),
                    _PeriodSelector(
                        selected: period, onChanged: onPeriodChanged),
                  ]),
                ),
              const SizedBox(height: 12),
              Expanded(
                  child: CustomPaint(
                      size: Size.infinite, painter: _ChartPainter(values))),
            ]),
          );
        },
      );
}

class _ChartTitle extends StatelessWidget {
  const _ChartTitle();

  @override
  Widget build(BuildContext context) => const Text('Company Growth',
      style: TextStyle(
          color: Color(0xFF243047),
          fontSize: 18,
          height: 1,
          fontWeight: FontWeight.w700));
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector(
      {required this.selected, required this.onChanged, this.expand = false});
  final int selected;
  final ValueChanged<int> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) => Container(
        width: expand ? null : 272,
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: const Color(0xFFF4F5F8),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: List.generate(3, (index) {
            final active = selected == index;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: active
                          ? const [
                              BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 1))
                            ]
                          : null),
                  child: Text(const ['Year', 'Month', 'Week'][index],
                      style: TextStyle(
                          color: active
                              ? const Color(0xFF243047)
                              : const Color(0xFF7D8799),
                          fontSize: 12,
                          height: 1,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400)),
                ),
              ),
            );
          }),
        ),
      );
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter(this.rawValues);
  final List<double> rawValues;
  static const illustrativeValues = <double>[
    280,
    320,
    300,
    360,
    330,
    440,
    320,
    490,
    380,
    630,
    120,
    980,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const left = 50.0;
    const right = 2.0;
    const top = 8.0;
    const bottom = 24.0;
    final plot =
        Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    final hasGrowthData = _hasMeaningfulGrowthData(rawValues);
    final values = hasGrowthData ? rawValues : illustrativeValues;
    if (values.length < 2) return;
    final maximum = values.reduce((left, right) => left > right ? left : right);
    final chartMaximum = hasGrowthData
        ? ((maximum / 5).ceil().clamp(1, 1000000) * 5).toDouble()
        : 1000.0;
    final grid = Paint()
      ..color = const Color(0xFFE8EBF1)
      ..strokeWidth = 1;
    for (var i = 0; i <= 5; i++) {
      final y = plot.top + plot.height * i / 5;
      for (double x = plot.left; x < plot.right; x += 7) {
        canvas.drawLine(
            Offset(x, y), Offset((x + 3).clamp(x, plot.right), y), grid);
      }
      final labelValue = chartMaximum - (chartMaximum * i / 5);
      _paintLabel(canvas, _formatAxisValue(labelValue), Offset(0, y - 6), 40,
          TextAlign.right);
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] / chartMaximum).clamp(0.0, 1.0);
      points.add(Offset(plot.left + plot.width * i / (values.length - 1),
          plot.bottom - plot.height * normalized));
      _paintLabel(canvas, '${i + 1}',
          Offset(points.last.dx - 12, plot.bottom + 9), 24, TextAlign.center);
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final dx = (next.dx - current.dx) * .46;
      path.cubicTo(
          current.dx + dx, current.dy, next.dx - dx, next.dy, next.dx, next.dy);
    }

    final fill = Path.from(path)
      ..lineTo(points.last.dx, plot.bottom)
      ..lineTo(points.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x225A65AB), Color(0x005A65AB)])
              .createShader(plot));
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  void _paintLabel(Canvas canvas, String text, Offset offset, double width,
      TextAlign align) {
    final painter = TextPainter(
        text: TextSpan(
            text: text,
            style: const TextStyle(
                color: Color(0xFFA2AEC2), fontSize: 10, height: 1.2)),
        textDirection: TextDirection.ltr,
        textAlign: align)
      ..layout(minWidth: width, maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.rawValues != rawValues;
}

bool _hasMeaningfulGrowthData(List<double> values) {
  if (values.length < 2) return false;
  var minimum = values.first;
  var maximum = values.first;
  for (final value in values.skip(1)) {
    if (value < minimum) minimum = value;
    if (value > maximum) maximum = value;
  }
  return maximum > 0 && maximum - minimum >= 2;
}

String _formatAxisValue(double value) {
  final rounded = value.round();
  return rounded >= 1000
      ? rounded.toString().replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (_) => ',',
          )
      : '$rounded';
}

class _ShipmentCard extends StatefulWidget {
  const _ShipmentCard({required this.shipment, required this.onViewMore});
  final Map<String, dynamic> shipment;
  final VoidCallback onViewMore;

  @override
  State<_ShipmentCard> createState() => _ShipmentCardState();
}

class _ShipmentCardState extends State<_ShipmentCard> {
  bool _expanded = true;

  Map<String, dynamic> get shipment => widget.shipment;

  String get status => (shipment['status'] ?? '')
      .toString()
      .toLowerCase()
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join('-');

  Color get statusColor => switch (shipment['status']) {
        'DELAYED' => const Color(0xFFC8F7FA),
        'DELIVERED' || 'PAID' => const Color(0xFFDDF8D8),
        _ => const Color(0xFFFFE2CB),
      };

  Color get statusTextColor => switch (shipment['status']) {
        'DELAYED' => const Color(0xFF003337),
        'DELIVERED' || 'PAID' => const Color(0xFF176112),
        _ => const Color(0xFFCB854B),
      };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          return AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 20, 20),
                  child: compact
                      ? Column(children: [
                          Row(children: [
                            Expanded(
                                child: _Detail(
                                    label: 'Tracking ID',
                                    value: shipment['trackingId']?.toString() ??
                                        '',
                                    accent: true)),
                            _CollapseButton(
                                expanded: _expanded,
                                onTap: () =>
                                    setState(() => _expanded = !_expanded)),
                          ]),
                          const SizedBox(height: 18),
                          Row(children: [
                            Expanded(
                                child: _Detail(
                                    label: 'Sender',
                                    value:
                                        shipment['sender']?.toString() ?? '')),
                            const SizedBox(width: 18),
                            Expanded(
                                child: _Detail(
                                    label: 'Receiver',
                                    value: shipment['receiver']?.toString() ??
                                        '')),
                          ]),
                        ])
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              SizedBox(
                                  width: 190,
                                  child: _Detail(
                                      label: 'Tracking ID',
                                      value:
                                          shipment['trackingId']?.toString() ??
                                              '',
                                      accent: true)),
                              const SizedBox(width: 28),
                              SizedBox(
                                  width: 145,
                                  child: _Detail(
                                      label: 'Sender',
                                      value: shipment['sender']?.toString() ??
                                          '')),
                              const SizedBox(width: 28),
                              SizedBox(
                                  width: 145,
                                  child: _Detail(
                                      label: 'Receiver',
                                      value: shipment['receiver']?.toString() ??
                                          '')),
                              const Spacer(),
                              _CollapseButton(
                                  expanded: _expanded,
                                  onTap: () =>
                                      setState(() => _expanded = !_expanded)),
                            ]),
                ),
                if (_expanded) ...[
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 22),
                    child: compact
                        ? Wrap(runSpacing: 20, children: [
                            SizedBox(
                                width: constraints.maxWidth / 2 - 32,
                                child: _LocationDetail(
                                    label: 'Pick Up From',
                                    value: shipment['pickupLocation']
                                            ?.toString() ??
                                        '')),
                            SizedBox(
                                width: constraints.maxWidth / 2 - 32,
                                child: _LocationDetail(
                                    label: 'Delivery To',
                                    value: shipment['deliveryLocation']
                                            ?.toString() ??
                                        '')),
                            SizedBox(
                                width: constraints.maxWidth / 2 - 32,
                                child: _Detail(
                                    label: 'Amount',
                                    value: formatNaira(shipment['amount']))),
                            SizedBox(
                                width: constraints.maxWidth / 2 - 32,
                                child: _StatusDetail(
                                    status: status,
                                    background: statusColor,
                                    foreground: statusTextColor)),
                          ])
                        : Row(children: [
                            Expanded(
                                flex: 280,
                                child: _LocationDetail(
                                    label: 'Pick Up From',
                                    value: shipment['pickupLocation']
                                            ?.toString() ??
                                        '')),
                            Expanded(
                                flex: 275,
                                child: _LocationDetail(
                                    label: 'Delivery To',
                                    value: shipment['deliveryLocation']
                                            ?.toString() ??
                                        '')),
                            Expanded(
                                flex: 225,
                                child: _Detail(
                                    label: 'Amount',
                                    value: formatNaira(shipment['amount']))),
                            _StatusDetail(
                                status: status,
                                background: statusColor,
                                foreground: statusTextColor),
                          ]),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                _ProcessingTime(
                                    hours: shipment['processingHours'] ?? 0),
                                const SizedBox(height: 18),
                                Row(children: [
                                  Expanded(
                                      child: _OrderButton('View More',
                                          onTap: widget.onViewMore)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: _OrderButton(
                                          shipment['status'] == 'DELAYED'
                                              ? 'Pay Now'
                                              : 'Paid',
                                          filled:
                                              shipment['status'] == 'DELAYED',
                                          disabled:
                                              shipment['status'] != 'DELAYED')),
                                ]),
                              ])
                        : Row(children: [
                            _ProcessingTime(
                                hours: shipment['processingHours'] ?? 0),
                            const Spacer(),
                            SizedBox(
                                width: 104,
                                child: _OrderButton('View More',
                                    onTap: widget.onViewMore)),
                            const SizedBox(width: 8),
                            SizedBox(
                                width: 90,
                                child: _OrderButton(
                                    shipment['status'] == 'DELAYED'
                                        ? 'Pay Now'
                                        : 'Paid',
                                    filled: shipment['status'] == 'DELAYED',
                                    disabled: shipment['status'] != 'DELAYED')),
                          ]),
                  ),
                ],
              ]),
            ),
          );
        },
      );
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label, value;
  final bool accent;
  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, height: 1, color: Color(0xFF808080))),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: accent
                        ? const Color(0xFF5A65AB)
                        : const Color(0xFF3A3A3A),
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w400)),
          ]);
}

class _LocationDetail extends StatelessWidget {
  const _LocationDetail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, height: 1, color: Color(0xFF808080))),
          const SizedBox(height: 8),
          Row(children: [
            Image.asset('assets/twemoji_flag-nigeria.png',
                width: 16, height: 16, fit: BoxFit.contain),
            const SizedBox(width: 8),
            Flexible(
                child: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 14,
                        height: 1,
                        fontWeight: FontWeight.w400))),
          ]),
        ],
      );
}

class _StatusDetail extends StatelessWidget {
  const _StatusDetail(
      {required this.status,
      required this.background,
      required this.foreground});
  final String status;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Status',
              style:
                  TextStyle(fontSize: 12, height: 1, color: Color(0xFF808080))),
          const SizedBox(height: 8),
          Container(
            width: 73,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: background, borderRadius: BorderRadius.circular(8)),
            child: Text(status,
                style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      );
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedRotation(
            turns: expanded ? 0 : .5,
            duration: const Duration(milliseconds: 180),
            child:
                SvgPicture.asset('assets/CaretUp.svg', width: 24, height: 24),
          ),
        ),
      );
}

class _ProcessingTime extends StatelessWidget {
  const _ProcessingTime({required this.hours});
  final dynamic hours;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Processing time',
              style:
                  TextStyle(fontSize: 12, height: 1, color: Color(0xFF808080))),
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            SvgPicture.asset('assets/Timer.svg', width: 20, height: 20),
            const SizedBox(width: 8),
            Text('$hours hours',
                style: const TextStyle(
                    color: Color(0xFF3A3A3A), fontSize: 14, height: 1)),
          ]),
        ],
      );
}

class _OrderButton extends StatelessWidget {
  const _OrderButton(this.label,
      {this.filled = false, this.disabled = false, this.onTap});
  final String label;
  final bool filled;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: disabled
                  ? const Color(0xFFEFEDED)
                  : filled
                      ? const Color(0xFF32385E)
                      : const Color(0xFFFEFEFE),
              border: disabled || filled
                  ? null
                  : Border.all(color: const Color(0xFF262A48)),
              borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              maxLines: 1,
              style: TextStyle(
                  color: disabled
                      ? const Color(0xFF808080)
                      : filled
                          ? Colors.white
                          : const Color(0xFF262A48),
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w600)),
        ),
      );
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF737373),
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w500)),
        ),
      );
}
