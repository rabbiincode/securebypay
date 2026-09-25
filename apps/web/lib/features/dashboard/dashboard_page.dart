import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _period = 0;
  late Future<Map<String, dynamic>> _dashboard;

  @override
  void initState() { super.initState(); _dashboard = apiClient.dashboard(); }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (snapshot.hasError) return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Unable to load your dashboard.'), const SizedBox(height: 12), ElevatedButton(onPressed: () => setState(() => _dashboard = apiClient.dashboard()), child: const Text('Try again'))])));
          final logout = () async { await apiClient.logout(); if (context.mounted) context.go('/sign-in'); };
          return Scaffold(
            drawer: MediaQuery.sizeOf(context).width < 900 ? Drawer(child: _Sidebar(onLogout: logout)) : null,
            body: Row(children: [
              if (MediaQuery.sizeOf(context).width >= 900) SizedBox(width: 240, child: _Sidebar(onLogout: logout)),
              Expanded(child: _content(snapshot.data!)),
            ]),
          );
        },
      );

  Widget _content(Map<String, dynamic> data) => CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titleSpacing: 28,
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Invite & Earn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 3),
            Text('Keep track of your addresses, location updates and all your saved addresses', style: TextStyle(fontSize: 12, color: Color(0xFF777777))),
          ]),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(28),
          sliver: SliverList.list(children: [
            const _HeroBanner(),
            const SizedBox(height: 44),
            _SectionHeader(title: 'Overview', trailing: _MonthFilter()),
            const SizedBox(height: 22),
            _OverviewCards(data: data),
            const SizedBox(height: 42),
            const _SectionHeader(title: 'Recent shipment', trailing: _SmallButton('See All')),
            const SizedBox(height: 24),
            _GrowthChart(period: _period, onPeriodChanged: (value) => setState(() => _period = value)),
            const SizedBox(height: 12),
            const _ShipmentCard(status: 'In-Transit', statusColor: Color(0xFFFFE2CB), action: 'Paid'),
            const SizedBox(height: 12),
            const _ShipmentCard(status: 'Delayed', statusColor: Color(0xFFC8F7FA), action: 'Pay Now'),
            const SizedBox(height: 12),
            const _ShipmentCard(status: 'Delivered', statusColor: Color(0xFFDDF8D8), action: 'Paid'),
          ]),
        ),
      ]);
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.onLogout});
  final VoidCallback onLogout;
  static const items = [
    ('Dashboard', 'assets/layout-dashboard.svg'), ('Shipments', 'assets/ship.svg'), ('Our Services', 'assets/globe.svg'),
    ('Notifications', 'assets/bell.svg'), ('Wallet', 'assets/credit-card.svg'), ('My Addresses', 'assets/locate-fixed.svg'),
    ('Invite & Earn', 'assets/badge-dollar-sign.svg'), ('Help Center', 'assets/hand-helping.svg'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 38, 28, 28),
          child: Column(children: [
            for (var i = 0; i < items.length; i++) ...[
              _NavItem(label: items[i].$1, icon: items[i].$2, selected: i == 0),
              const SizedBox(height: 10),
            ],
            const Spacer(),
            const Row(children: [
              CircleAvatar(radius: 23, backgroundImage: AssetImage('assets/Ellipse.png')),
              SizedBox(width: 10),
              Text('Firstname\nLastname', style: TextStyle(height: 1.6, color: Color(0xFF626262))),
            ]),
            const SizedBox(height: 26),
            InkWell(
              onTap: onLogout,
              child: Row(children: [SvgPicture.asset('assets/log-out.svg', width: 24), const SizedBox(width: 10), const Text('Logout')]),
            ),
          ]),
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.icon, required this.selected});
  final String label, icon;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(color: selected ? AppColors.primaryDark : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          SvgPicture.asset(icon, width: 22, colorFilter: selected ? const ColorFilter.mode(Color(0xFFEBFFE2), BlendMode.srcIn) : null),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF626262), fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
        ]),
      );
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();
  @override
  Widget build(BuildContext context) => Container(
        height: 245,
        padding: const EdgeInsets.symmetric(horizontal: 36),
        decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(5)),
        child: Row(children: [
          const Expanded(child: Text('KEEP UP WITH YOUR\nBUSINESS NEEDS', style: TextStyle(color: Colors.white, fontSize: 36, height: 1.1, fontWeight: FontWeight.w800))),
          if (MediaQuery.sizeOf(context).width > 650) Image.asset('assets/earth-boxes-cardboard-texture 1.png', fit: BoxFit.contain),
        ]),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});
  final String title;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium), trailing,
      ]);
}

class _MonthFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
        child: const Row(children: [Text('This Month'), SizedBox(width: 8), Icon(Icons.keyboard_arrow_down, size: 18)]),
      );
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final metrics = data['metrics'] as Map<String, dynamic>? ?? const {};
        final narrow = constraints.maxWidth < 760;
        final cards = [
          _BalanceCard(balance: data['balance']?.toString() ?? '0.00'),
          _MetricCard(label: 'Total Shipment', value: '${metrics['totalShipments'] ?? 0}', icon: Icons.local_shipping_outlined, color: const Color(0xFFC98810), tint: const Color(0xFFFFEAC4)),
          _MetricCard(label: 'Total Exports', value: '${metrics['totalExports'] ?? 0}', icon: Icons.arrow_upward, color: const Color(0xFF11C308), tint: const Color(0xFFD6FFD4)),
          _MetricCard(label: 'Total Import', value: '${metrics['totalImports'] ?? 0}', icon: Icons.arrow_downward, color: const Color(0xFF049FA7), tint: const Color(0xFFD1F8FA)),
        ];
        if (narrow) return Column(children: [for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: 12), child: SizedBox(width: double.infinity, child: card))]);
        return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var i = 0; i < cards.length; i++) Expanded(flex: i == 0 ? 2 : 1, child: Padding(padding: EdgeInsets.only(right: i == cards.length - 1 ? 0 : 16), child: cards[i]))]);
      });
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final String balance;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your Balance', style: TextStyle(color: Color(0xFFD5D9F5))), const SizedBox(height: 10),
          Text('₦$balance', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)), const SizedBox(height: 24),
          const _SmallButton('Fund Wallet'),
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color, required this.tint});
  final String label, value;
  final IconData icon;
  final Color color, tint;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE6E6E6))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [CircleAvatar(backgroundColor: tint, child: Icon(icon, color: color)), const SizedBox(width: 10), Flexible(child: Text(label, style: const TextStyle(color: Color(0xFF777777))))]),
          const SizedBox(height: 18), Row(children: [Text(value, style: const TextStyle(fontSize: 26)), const SizedBox(width: 8), const Text('↑ 90%', style: TextStyle(color: AppColors.success))]),
          const SizedBox(height: 10), const Text('Vs last month: 4', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
        ]),
      );
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.period, required this.onPeriodChanged});
  final int period;
  final ValueChanged<int> onPeriodChanged;
  @override
  Widget build(BuildContext context) => Container(
        height: 350,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Row(children: [
            const Text('Company Growth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('Year')), ButtonSegment(value: 1, label: Text('Month')), ButtonSegment(value: 2, label: Text('Week'))], selected: {period}, onSelectionChanged: (value) => onPeriodChanged(value.first), showSelectedIcon: false),
          ]),
          const SizedBox(height: 18),
          Expanded(child: CustomPaint(size: Size.infinite, painter: _ChartPainter())),
        ]),
      );
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFFE8EBF1)..strokeWidth = 1;
    for (var i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset.zero.translate(0, y), Offset(size.width, y), grid);
    }
    final values = [0.72, .62, .66, .50, .58, .32, .58, .25, .48, .12, .80, .02];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(size.width * i / (values.length - 1), size.height * values[i]);
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, Paint()..color = AppColors.primary..strokeWidth = 2.2..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.status, required this.statusColor, required this.action});
  final String status, action;
  final Color statusColor;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Wrap(spacing: 80, runSpacing: 18, children: const [
            _Detail(label: 'Tracking ID', value: 'MAF-100-234-291', accent: true), _Detail(label: 'Sender', value: 'Bunmi Tanny'), _Detail(label: 'Receiver', value: 'Mercy'),
          ]),
          const Divider(height: 36),
          Wrap(spacing: 80, runSpacing: 18, children: [
            const _Detail(label: 'Pick Up From', value: '🇳🇬  Lagos, Nigeria'), const _Detail(label: 'Delivery To', value: '🇳🇬  Oyo Nigeria'), const _Detail(label: 'Amount', value: '₦3000'),
            _Detail(label: 'Status', value: status, background: statusColor),
          ]),
          const Divider(height: 36),
          Row(children: [const Icon(Icons.timer_outlined), const SizedBox(width: 8), const Text('10 hours'), const Spacer(), const _SmallButton('View More'), const SizedBox(width: 10), _SmallButton(action, filled: action == 'Pay Now')]),
        ]),
      );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value, this.accent = false, this.background});
  final String label, value;
  final bool accent;
  final Color? background;
  @override
  Widget build(BuildContext context) => SizedBox(width: 180, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))), const SizedBox(height: 7),
        Container(padding: background == null ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: background == null ? null : BoxDecoration(color: background, borderRadius: BorderRadius.circular(7)), child: Text(value, style: TextStyle(color: accent ? AppColors.primary : AppColors.text))),
      ]));
}

class _SmallButton extends StatelessWidget {
  const _SmallButton(this.label, {this.filled = false});
  final String label;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(color: filled ? AppColors.primaryDark : Colors.white, border: Border.all(color: filled ? AppColors.primaryDark : AppColors.border), borderRadius: BorderRadius.circular(7)),
        child: Text(label, style: TextStyle(color: filled ? Colors.white : AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
