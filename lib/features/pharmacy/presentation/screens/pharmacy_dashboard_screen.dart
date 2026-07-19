import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/account_menu_button.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../../inventory/presentation/controllers/inventory_cubit.dart';
import '../../../inventory/data/models/inventory_medicine.dart';
import '../../data/orders_repository.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() =>
      _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  int? _livePendingOrders;
  final Set<String> _visibleActions = {
    'Scan Medicine',
    'Verify Patient',
    'Inventory',
    'Suppliers',
    'Reports'
  };
  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().loadInventory();
    _loadActionPreferences();
    OrdersRepository().orders().then((orders) {
      if (mounted) {
        setState(() => _livePendingOrders = orders
            .where((order) => !['received', 'cancelled'].contains(order.status))
            .length);
      }
    }).catchError((_) {});
  }

  Future<void> _loadActionPreferences() async {
    final raw = await LocalDbService().read('pharmacy_quick_actions');
    if (raw == null || !mounted) return;
    final saved = (jsonDecode(raw) as List).cast<String>();
    setState(() {
      _visibleActions
        ..clear()
        ..addAll(saved);
    });
  }

  void _searchInventory(InventoryState state) {
    showSearch<void>(
      context: context,
      delegate: _InventorySearchDelegate(
        state,
        onSelected: (medicine) => context.push(
          '/pharmacy/inventory/detail?name=${Uri.encodeComponent(medicine.name)}&expiry=${Uri.encodeComponent(medicine.expiry)}',
        ),
      ),
    );
  }

  Future<void> _customizeActions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customize quick actions', style: AppTextStyles.heading),
                  Text('Choose the shortcuts shown on your dashboard.',
                      style: AppTextStyles.body),
                  ...[
                    'Scan Medicine',
                    'Verify Patient',
                    'Inventory',
                    'Suppliers',
                    'Reports'
                  ].map((label) => CheckboxListTile(
                        value: _visibleActions.contains(label),
                        title: Text(label),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setSheetState(() => setState(() =>
                            value == true
                                ? _visibleActions.add(label)
                                : _visibleActions.remove(label))),
                      )),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: () async {
                            await LocalDbService().write(
                                'pharmacy_quick_actions',
                                jsonEncode(_visibleActions.toList()));
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Save shortcuts'))),
                ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        final inventoryCount = state.medicines.length;
        final expiringSoon = state.medicines
            .where((medicine) => medicine.isExpiringSoon || medicine.isExpired)
            .toList()
          ..sort((a, b) => a.expiry.compareTo(b.expiry));
        final expiringSoonCount = expiringSoon.length;
        final recentAlert = expiringSoon.isEmpty ? null : expiringSoon.first;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text("Today's Summary",
                            style: AppTextStyles.heading),
                      ),
                      IconButton(
                        tooltip: 'Search inventory',
                        onPressed: () => _searchInventory(state),
                        icon: const Icon(Icons.search, color: AppColors.accent),
                      ),
                      const AccountMenuButton(
                        roleLabel: 'Pharmacy',
                        profileRoute: '/pharmacy/more',
                        openDirectly: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(
                    inventory: inventoryCount,
                    expiring: expiringSoonCount,
                    pending: _livePendingOrders ?? 0,
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                        child: Text('Quick Actions',
                            style: AppTextStyles.subheading)),
                    TextButton.icon(
                        onPressed: _customizeActions,
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Customize')),
                  ]),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                    children: [
                      _QuickAction(
                        icon: Icons.qr_code_scanner_outlined,
                        label: 'Scan Medicine',
                        onTap: () => context.push('/pharmacy/scan'),
                      ),
                      _QuickAction(
                        icon: Icons.badge_outlined,
                        label: 'Verify Patient',
                        onTap: () => context.push('/identity/scan'),
                      ),
                      _QuickAction(
                        icon: Icons.inventory_2_outlined,
                        label: 'Inventory',
                        onTap: () => context.push('/pharmacy/inventory'),
                      ),
                      _QuickAction(
                        icon: Icons.local_shipping_outlined,
                        label: 'Suppliers',
                        onTap: () => context.push('/pharmacy/orders'),
                      ),
                      _QuickAction(
                        icon: Icons.insert_chart_outlined,
                        label: 'Reports',
                        onTap: () => context.push('/pharmacy/reports'),
                      ),
                    ]
                        .where(
                            (action) => _visibleActions.contains(action.label))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Recent Alerts', style: AppTextStyles.subheading),
                  const SizedBox(height: 10),
                  if (recentAlert == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline),
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                      ),
                      child: Text('No expiry alerts right now.',
                          style: AppTextStyles.body),
                    )
                  else
                    InkWell(
                      onTap: () {
                        context.push(
                          '/pharmacy/inventory/detail?name=${Uri.encodeComponent(recentAlert.name)}&expiry=${Uri.encodeComponent(recentAlert.expiry)}',
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.hairline),
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_outlined,
                                color: AppColors.statusWarning, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(recentAlert.name,
                                      style: AppTextStyles.subheading),
                                  Text(
                                    recentAlert.isExpired
                                        ? 'Expired batch ${recentAlert.batchNumber}'
                                        : 'Expires in ${recentAlert.daysUntilExpiry} days',
                                    style: AppTextStyles.body,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (idx) {
              switch (idx) {
                case 0:
                  context.go('/pharmacy/dashboard');
                  break;
                case 1:
                  context.go('/pharmacy/inventory');
                  break;
                case 2:
                  context.go('/pharmacy/scan');
                  break;
                case 3:
                  context.go('/pharmacy/orders');
                  break;
                case 4:
                  context.go('/pharmacy/more');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard'),
              NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Inventory'),
              NavigationDestination(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: Icon(Icons.qr_code_scanner),
                  label: 'Scan'),
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Orders'),
              NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  selectedIcon: Icon(Icons.more_horiz),
                  label: 'More'),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.inventory, required this.expiring, required this.pending});
  final int inventory, expiring, pending;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          _item(
              'Inventory', inventory, () => context.go('/pharmacy/inventory')),
          const SizedBox(height: 50, child: VerticalDivider()),
          _item('Expiring soon', expiring,
              () => context.go('/pharmacy/inventory')),
          const SizedBox(height: 50, child: VerticalDivider()),
          _item(
              'Pending orders', pending, () => context.go('/pharmacy/orders')),
        ]),
      );
  Widget _item(String label, int value, VoidCallback onTap) => Expanded(
      child: InkWell(
          onTap: onTap,
          child: Column(children: [
            Text('$value',
                style: AppTextStyles.heading
                    .copyWith(fontSize: 22, color: AppColors.accent)),
            Text(label,
                style: AppTextStyles.label, textAlign: TextAlign.center),
          ])));
}

class _InventorySearchDelegate extends SearchDelegate<void> {
  _InventorySearchDelegate(this.state, {required this.onSelected});
  final InventoryState state;
  final ValueChanged<InventoryMedicine> onSelected;
  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))
      ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back));
  @override
  Widget buildSuggestions(BuildContext context) => _results(context);
  @override
  Widget buildResults(BuildContext context) => _results(context);
  Widget _results(BuildContext context) {
    final term = query.trim().toLowerCase();
    final matches = state.medicines
        .where((m) =>
            term.isEmpty ||
            m.name.toLowerCase().contains(term) ||
            m.genericName.toLowerCase().contains(term) ||
            m.barcode.contains(term))
        .toList();
    if (matches.isEmpty) {
      return const Center(child: Text('No inventory matches found.'));
    }
    return ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final m = matches[index];
          return ListTile(
              leading: const Icon(Icons.medication_outlined,
                  color: AppColors.accent),
              title: Text(m.name),
              subtitle: Text('${m.quantity} units • ${m.batchNumber}'),
              onTap: () {
                close(context, null);
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => onSelected(m));
              });
        });
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}
