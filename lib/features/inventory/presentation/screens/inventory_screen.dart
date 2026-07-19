import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
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
  String _expiryFilter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Lazy load when screen is first navigated to
    context.read<InventoryCubit>().loadInventory();
  }

  List<InventoryMedicine> _getFiltered(List<InventoryMedicine> medicines) {
    final query = _search.trim().toLowerCase();
    final filtered = medicines.where((medicine) {
      if (_filter != null && medicine.level != _filter) return false;
      if (_expiryFilter == 'expired' && !medicine.isExpired) return false;
      if (_expiryFilter == 'soon' && !medicine.isExpiringSoon) return false;
      if (query.isNotEmpty &&
          !medicine.name.toLowerCase().contains(query) &&
          !medicine.barcode.toLowerCase().contains(query) &&
          !medicine.batchNumber.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
    filtered.sort((a, b) {
      if (a.expiry.isEmpty) return 1;
      if (b.expiry.isEmpty) return -1;
      return a.expiry.compareTo(b.expiry);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/pharmacy/dashboard')),
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
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: 'Search medicine',
                  hintStyle: AppTextStyles.body,
                  border: InputBorder.none,
                  icon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
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
                _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null)),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'In Stock',
                    selected: _filter == StockLevel.inStock,
                    onTap: () => setState(() => _filter = StockLevel.inStock)),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Low Stock',
                    selected: _filter == StockLevel.lowStock,
                    onTap: () => setState(() => _filter = StockLevel.lowStock)),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Out of Stock',
                    selected: _filter == StockLevel.outOfStock,
                    onTap: () =>
                        setState(() => _filter = StockLevel.outOfStock)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                    label: 'All expiries',
                    selected: _expiryFilter == 'all',
                    onTap: () => setState(() => _expiryFilter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Expiring in 90 days',
                    selected: _expiryFilter == 'soon',
                    onTap: () => setState(() => _expiryFilter = 'soon')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Expired',
                    selected: _expiryFilter == 'expired',
                    onTap: () => setState(() => _expiryFilter = 'expired')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<InventoryCubit, InventoryState>(
              builder: (context, state) {
                if (state.isLoading && state.medicines.isEmpty) {
                  return const SkeletonList(
                    itemCount: 6,
                    showHeader: false,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                  );
                }
                final filtered = _getFiltered(state.medicines);
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(medicine.name,
                                        style: AppTextStyles.subheading),
                                    Text(
                                      medicine.expiry.isEmpty
                                          ? 'No expiry recorded'
                                          : 'Expiry ${medicine.expiry} • Batch ${medicine.batchNumber.isEmpty ? 'not recorded' : medicine.batchNumber}',
                                      style: AppTextStyles.body,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${medicine.quantity} units${medicine.barcode.isEmpty ? '' : ' • ${medicine.barcode}'}',
                                      style: AppTextStyles.label,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  StockStatusBadge(level: medicine.level),
                                  if (medicine.isExpired ||
                                      medicine.isExpiringSoon) ...[
                                    const SizedBox(height: 6),
                                    _ExpiryBadge(medicine: medicine),
                                  ],
                                ],
                              ),
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
  }
}

class _ExpiryBadge extends StatelessWidget {
  final InventoryMedicine medicine;
  const _ExpiryBadge({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final expired = medicine.isExpired;
    final days = medicine.daysUntilExpiry;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (expired ? AppColors.statusBad : AppColors.statusWarning)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        expired ? 'Expired' : '${days ?? 0}d left',
        style: AppTextStyles.label.copyWith(
          color: expired ? AppColors.statusBad : AppColors.statusWarning,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.hairline),
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
