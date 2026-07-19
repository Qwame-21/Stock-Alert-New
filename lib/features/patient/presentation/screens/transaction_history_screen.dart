import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/storage/local_db_service.dart';
import '../../../../core/theme/app_theme.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<dynamic>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = _load();
  }

  Future<List<dynamic>> _load() async {
    final raw = await LocalDbService().read('transaction_history');
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List<dynamic> ? decoded : const [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> _refresh() async {
    setState(() => _transactions = _load());
    await _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction history')),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _transactions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              );
            }
            final items = snapshot.data ?? const [];
            return RefreshIndicator(
              onRefresh: _refresh,
              child: items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 120),
                        const Icon(Icons.receipt_long_outlined, size: 64),
                        const SizedBox(height: 16),
                        Text('No transactions yet',
                            style: AppTextStyles.heading,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(
                          'Completed pharmacy and consultation payments will appear here.',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final map = item is Map
                            ? Map<String, dynamic>.from(item)
                            : <String, dynamic>{'description': '$item'};
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.payments_outlined),
                          ),
                          title: Text(map['description']?.toString() ??
                              map['reference']?.toString() ??
                              'Payment'),
                          subtitle:
                              Text(map['status']?.toString() ?? 'Completed'),
                          trailing: map['amount'] == null
                              ? null
                              : Text('GHS ${map['amount']}'),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}
