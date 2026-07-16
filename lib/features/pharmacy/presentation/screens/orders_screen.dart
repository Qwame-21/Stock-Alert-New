import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PurchaseOrder {
  final String id;
  final String supplier;
  final String date;
  final String status; // 'Pending' | 'Delivered' | 'Cancelled'
  final String items;

  const PurchaseOrder(this.id, this.supplier, this.date, this.status, this.items);
}

class Supplier {
  final String name;
  final String contact;
  final String history;

  const Supplier(this.name, this.contact, this.history);
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<PurchaseOrder> _orders = [
    const PurchaseOrder('ORD-902', 'Standard Wholesales Ltd', '12 July 2026', 'Pending', 'Amoxicillin x200, Ibuprofen x100'),
    const PurchaseOrder('ORD-893', 'Standard Wholesales Ltd', '10 July 2026', 'Delivered', 'Paracetamol x500'),
    const PurchaseOrder('ORD-881', 'MedLink Distributors', '05 July 2026', 'Delivered', 'Cough Syrup x150'),
    const PurchaseOrder('ORD-862', 'Apex Pharmaceuticals', '01 July 2026', 'Cancelled', 'Amoxicillin x100'),
  ];

  final List<Supplier> _suppliers = [
    const Supplier('Standard Wholesales Ltd', '+233 24 123 9999', 'Last order: 12 July 2026 (Pending)'),
    const Supplier('MedLink Distributors', '+233 20 888 7777', 'Last order: 05 July 2026 (Delivered)'),
    const Supplier('Apex Pharmaceuticals', '+233 30 222 3333', 'Last order: 01 July 2026 (Cancelled)'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Suppliers & Orders', style: AppTextStyles.subheading),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Orders'),
            Tab(text: 'Suppliers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(),
          _buildSuppliersList(),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final Map<String, List<PurchaseOrder>> grouped = {
      'Pending': _orders.where((o) => o.status == 'Pending').toList(),
      'Delivered': _orders.where((o) => o.status == 'Delivered').toList(),
      'Cancelled': _orders.where((o) => o.status == 'Cancelled').toList(),
    };

    return ListView(
      padding: const EdgeInsets.all(20),
      children: grouped.keys.map((status) {
        final list = grouped[status]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Text(
                status.toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                ),
              ),
            ),
            ...list.map((order) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.hairline),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ID: ${order.id}', style: AppTextStyles.subheading),
                          Text(order.date, style: AppTextStyles.label),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(order.supplier, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                      Text(order.items, style: AppTextStyles.body),
                    ],
                  ),
                )),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSuppliersList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sup = _suppliers[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sup.name, style: AppTextStyles.subheading),
              Text('Contact: ${sup.contact}', style: AppTextStyles.body),
              Text(sup.history, style: AppTextStyles.body.copyWith(fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reorder request submitted to ${sup.name}')),
                    );
                  },
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Reorder Last Shipment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.statusWarning;
      case 'Delivered':
        return AppColors.statusGood;
      case 'Cancelled':
        return AppColors.statusBad;
      default:
        return AppColors.textSecondary;
    }
  }
}
