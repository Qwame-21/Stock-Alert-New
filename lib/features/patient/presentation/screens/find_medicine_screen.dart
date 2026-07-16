import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stock_status_badge.dart';

class SearchMedicineItem {
  final String name;
  final String pharmacy;
  final StockLevel level;
  final String? alternativeName;
  final String? alternativePharmacy;

  const SearchMedicineItem({
    required this.name,
    required this.pharmacy,
    required this.level,
    this.alternativeName,
    this.alternativePharmacy,
  });
}

class FindMedicineScreen extends StatefulWidget {
  const FindMedicineScreen({super.key});

  @override
  State<FindMedicineScreen> createState() => _FindMedicineScreenState();
}

class _FindMedicineScreenState extends State<FindMedicineScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const List<SearchMedicineItem> _allMeds = [
    SearchMedicineItem(
      name: 'Amoxicillin 500mg',
      pharmacy: 'Green Pharmacy',
      level: StockLevel.inStock,
    ),
    SearchMedicineItem(
      name: 'Paracetamol 500mg',
      pharmacy: 'MediCare Pharmacy',
      level: StockLevel.lowStock,
    ),
    SearchMedicineItem(
      name: 'Cough Syrup 100ml',
      pharmacy: 'HealthPlus Pharmacy',
      level: StockLevel.lowStock,
    ),
    SearchMedicineItem(
      name: 'Ibuprofen 400mg',
      pharmacy: 'Green Pharmacy',
      level: StockLevel.inStock,
    ),
    SearchMedicineItem(
      name: 'Artemether/Lumefantrine',
      pharmacy: 'City Care Pharmacy',
      level: StockLevel.outOfStock,
      alternativeName: 'Coartem 20/120mg',
      alternativePharmacy: 'MediCare Pharmacy',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allMeds.where((m) {
      return m.name.toLowerCase().contains(_query.toLowerCase()) ||
          m.pharmacy.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            FocusScope.of(context).unfocus();
            context.go('/patient/home');
          },
        ),
        title: Text('Find Medicine', style: AppTextStyles.subheading),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: AppTextStyles.subheading,
                onChanged: (val) => setState(() => _query = val),
                decoration: InputDecoration(
                  hintText: 'Search medicine or pharmacy...',
                  hintStyle: AppTextStyles.body,
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No medicines found matching search.', style: AppTextStyles.body),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isOut = item.level == StockLevel.outOfStock;

                      return InkWell(
                        onTap: () {
                          // Opens Locator tab with specific pharmacy
                          context.go('/patient/nearby', extra: item.pharmacy);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.hairline),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: AppTextStyles.subheading),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.storefront_outlined,
                                                size: 14, color: AppColors.textSecondary),
                                            SizedBox(width: 4),
                                            Text(item.pharmacy, style: AppTextStyles.body),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  StockStatusBadge(level: item.level),
                                ],
                              ),
                              if (isOut && item.alternativeName != null) ...[
                                const Divider(height: 20, color: AppColors.hairline),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusWarning.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline,
                                          size: 16, color: AppColors.statusWarning),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Alternative: ${item.alternativeName} is available at ${item.alternativePharmacy}',
                                          style: AppTextStyles.label.copyWith(
                                            color: AppColors.statusWarning,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      context.go('/patient/nearby', extra: isOut ? item.alternativePharmacy : item.pharmacy);
                                    },
                                    icon: const Icon(Icons.near_me, size: 14),
                                    label: Text(
                                      isOut ? 'Locate Alternative' : 'Locate Pharmacy',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accent,
                                      side: const BorderSide(color: AppColors.accent),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
