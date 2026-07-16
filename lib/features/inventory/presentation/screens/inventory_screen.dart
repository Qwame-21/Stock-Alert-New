import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stock_status_badge.dart';
import '../../data/models/inventory_medicine.dart';
import '../controllers/inventory_cubit.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  StockLevel? _filter;

  @override
  void initState() {
    super.initState();
    // Lazy load when screen is first navigated to
    context.read<InventoryCubit>().loadInventory();
  }

  List<InventoryMedicine> _getFiltered(List<InventoryMedicine> medicines) {
    if (_filter == null) return medicines;
    return medicines.where((m) => m.level == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Inventory', style: AppTextStyles.subheading),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search medicine',
                  hintStyle: AppTextStyles.body,
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                SizedBox(width: 8),
                _FilterChip(label: 'In Stock', selected: _filter == StockLevel.inStock, onTap: () => setState(() => _filter = StockLevel.inStock)),
                SizedBox(width: 8),
                _FilterChip(label: 'Low Stock', selected: _filter == StockLevel.lowStock, onTap: () => setState(() => _filter = StockLevel.lowStock)),
                SizedBox(width: 8),
                _FilterChip(label: 'Out of Stock', selected: _filter == StockLevel.outOfStock, onTap: () => setState(() => _filter = StockLevel.outOfStock)),
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<InventoryCubit, InventoryState>(
              builder: (context, state) {
                if (state.isLoading && state.medicines.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filtered = _getFiltered(state.medicines);
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final medicine = filtered[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline),
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                      ),
                      child: InkWell(
                        onTap: () {
                          context.push(
                            '/pharmacy/inventory/detail?name=${Uri.encodeComponent(medicine.name)}&expiry=${Uri.encodeComponent(medicine.expiry)}',
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(medicine.name, style: AppTextStyles.subheading),
                                    Text('Expiry ${medicine.expiry}', style: AppTextStyles.body),
                                  ],
                                ),
                              ),
                              StockStatusBadge(level: medicine.level),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          border: Border.all(color: selected ? AppColors.accent : AppColors.hairline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

