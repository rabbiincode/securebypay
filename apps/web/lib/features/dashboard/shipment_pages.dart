import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/currency.dart';
import '../../core/theme.dart';

class ShipmentsPage extends StatelessWidget {
  const ShipmentsPage({super.key});

  @override
  Widget build(BuildContext context) => _DashboardDataPage(
        title: 'Shipments',
        builder: (data) {
          final shipments =
              data['recentShipments'] as List<dynamic>? ?? const [];
          return ListView.separated(
            padding: const EdgeInsets.all(28),
            itemCount: shipments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final shipment = shipments[index] as Map<String, dynamic>;
              return Card(
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDEFFC),
                    child: Icon(Icons.local_shipping_outlined,
                        color: AppColors.primary),
                  ),
                  title: Text(shipment['trackingId']?.toString() ?? ''),
                  subtitle: Text(
                      '${shipment['pickupLocation']} → ${shipment['deliveryLocation']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/shipments/${shipment['id']}'),
                ),
              );
            },
          );
        },
      );
}

class ShipmentDetailPage extends StatelessWidget {
  const ShipmentDetailPage({required this.shipmentId, super.key});
  final String shipmentId;

  @override
  Widget build(BuildContext context) => _DashboardDataPage(
        title: 'Shipment details',
        builder: (data) {
          final shipments =
              data['recentShipments'] as List<dynamic>? ?? const [];
          final shipment = shipments
              .cast<Map<String, dynamic>>()
              .where(
                (item) => item['id'] == shipmentId,
              )
              .firstOrNull;
          if (shipment == null) {
            return const Center(child: Text('Shipment not found.'));
          }
          final rows = <(String, String)>[
            ('Tracking ID', shipment['trackingId'].toString()),
            ('Sender', shipment['sender'].toString()),
            ('Receiver', shipment['receiver'].toString()),
            ('Pick up from', shipment['pickupLocation'].toString()),
            ('Delivery to', shipment['deliveryLocation'].toString()),
            ('Amount', formatNaira(shipment['amount'])),
            ('Status', shipment['status'].toString().replaceAll('_', ' ')),
            ('Processing time', '${shipment['processingHours']} hours'),
          ];
          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Wrap(
                  spacing: 32,
                  runSpacing: 28,
                  children: [
                    for (final row in rows)
                      SizedBox(
                        width: 240,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.$1,
                                style: const TextStyle(
                                    color: Color(0xFF999999), fontSize: 12)),
                            const SizedBox(height: 8),
                            Text(row.$2,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

class _DashboardDataPage extends StatefulWidget {
  const _DashboardDataPage({required this.title, required this.builder});
  final String title;
  final Widget Function(Map<String, dynamic>) builder;

  @override
  State<_DashboardDataPage> createState() => _DashboardDataPageState();
}

class _DashboardDataPageState extends State<_DashboardDataPage> {
  late final Future<Map<String, dynamic>> data = apiClient.dashboard();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(widget.title),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return const Center(child: Text('Unable to load shipments.'));
              }
              return const Center(child: CircularProgressIndicator());
            }
            return widget.builder(snapshot.data!);
          },
        ),
      );
}
