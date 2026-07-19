import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This support option is unavailable on this device.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help & Support')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('How can we help?', style: AppTextStyles.heading),
          Text(
              'Get help with your account, medicine searches, bookings, payments, privacy and pharmacy orders.',
              style: AppTextStyles.body),
          const SizedBox(height: 18),
          Card(
              child: Column(children: [
            ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email support'),
                subtitle: const Text('support@stockalert.app'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                    context,
                    Uri(
                        scheme: 'mailto',
                        path: 'support@stockalert.app',
                        queryParameters: {
                          'subject': 'StockAlert support request'
                        }))),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(Icons.call_outlined),
                title: const Text('Call support'),
                subtitle: const Text('Monday–Saturday, 8:00 AM–6:00 PM'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _open(context, Uri(scheme: 'tel', path: '+233000000000'))),
          ])),
          const SizedBox(height: 18),
          Text('Frequently asked questions', style: AppTextStyles.subheading),
          const ExpansionTile(title: Text('How do payments work?'), children: [
            Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'Card and mobile-money payments are completed in secure Paystack checkout. StockAlert does not store your card details.'))
          ]),
          const ExpansionTile(
              title: Text('Who can view my digital identity?'),
              children: [
                Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Only an authenticated pharmacy or consultation provider can request the fields you enabled in Digital identity privacy.'))
              ]),
          const ExpansionTile(
              title: Text('What if I need urgent help?'),
              children: [
                Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'StockAlert is not an emergency service. Contact local emergency services or a trusted contact for urgent assistance.'))
              ]),
        ]),
      );
}
