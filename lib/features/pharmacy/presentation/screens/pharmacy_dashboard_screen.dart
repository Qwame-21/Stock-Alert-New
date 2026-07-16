import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class PharmacyDashboardScreen extends StatelessWidget {
  final int inventoryCount;
  final int expiringSoonCount;
  final int pendingOrdersCount;

  const PharmacyDashboardScreen({
    super.key,
    required this.inventoryCount,
    required this.expiringSoonCount,
    required this.pendingOrdersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Summary", style: AppTextStyles.heading),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go('/pharmacy/inventory'),
                      child: _MetricCard(
                          label: 'Inventory',
                          value: '$inventoryCount',
                          unit: 'Medicines'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go('/pharmacy/inventory'),
                      child: _MetricCard(
                          label: 'Expiring Soon',
                          value: '$expiringSoonCount',
                          unit: 'Medicines'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go('/pharmacy/orders'),
                      child: _MetricCard(
                          label: 'Pending Orders',
                          value: '$pendingOrdersCount',
                          unit: 'Orders'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text('Quick Actions', style: AppTextStyles.subheading),
              SizedBox(height: 12),
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
                ],
              ),
              SizedBox(height: 24),
              Text('Recent Alerts', style: AppTextStyles.subheading),
              SizedBox(height: 10),
              InkWell(
                onTap: () {
                  context.push(
                    '/pharmacy/inventory/detail?name=Amoxicillin%20500mg&expiry=2026-10-15',
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
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amoxicillin 500mg', style: AppTextStyles.subheading),
                            Text('Expires in 12 days', style: AppTextStyles.body),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricCard({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.heading.copyWith(fontSize: 22)),
          Text(unit, style: AppTextStyles.label),
        ],
      ),
    );
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
            Icon(icon, color: AppColors.textPrimary, size: 22),
            SizedBox(height: 8),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}

