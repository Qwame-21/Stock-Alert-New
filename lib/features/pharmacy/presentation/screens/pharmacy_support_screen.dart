import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class PharmacySupportScreen extends StatelessWidget {
  const PharmacySupportScreen({super.key});
  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This contact option is unavailable.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/pharmacy/more')),
            title: const Text('Support & Helpdesk')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Pharmacy operations support', style: AppTextStyles.heading),
          Text(
              'Help with inventory synchronization, barcode scanning, supplier orders, receiving stock, reports, staff access and payment settlement.',
              style: AppTextStyles.body),
          const SizedBox(height: 18),
          Card(
              child: Column(children: [
            ListTile(
                leading:
                    const Icon(Icons.email_outlined, color: AppColors.accent),
                title: const Text('Email pharmacy support'),
                subtitle: const Text('pharmacy-support@stockalert.app'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                    context,
                    Uri(
                        scheme: 'mailto',
                        path: 'pharmacy-support@stockalert.app',
                        queryParameters: {
                          'subject': 'Pharmacy workspace support'
                        }))),
          ])),
          const SizedBox(height: 18),
          const ExpansionTile(
              title: Text('Inventory is not synchronizing'),
              children: [
                Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Check connectivity, then reopen Inventory and use refresh. Locally queued changes remain available until synchronization succeeds.'))
              ]),
          const ExpansionTile(
              title: Text('Receiving supplier stock'),
              children: [
                Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Open Suppliers & Orders, select an open order, then record the received quantity, batch number and expiry date.'))
              ]),
          const ExpansionTile(
              title: Text('Urgent medicine or patient issue'),
              children: [
                Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'StockAlert is not an emergency service. Follow your pharmacy’s clinical escalation procedures and contact local emergency services when required.'))
              ]),
        ]),
      );
}
