import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StockLevel { inStock, lowStock, outOfStock }

extension StockLevelLabel on StockLevel {
  String get label {
    switch (this) {
      case StockLevel.inStock:
        return 'In Stock';
      case StockLevel.lowStock:
        return 'Low Stock';
      case StockLevel.outOfStock:
        return 'Out of Stock';
    }
  }

  Color get color {
    switch (this) {
      case StockLevel.inStock:
        return AppColors.statusGood;
      case StockLevel.lowStock:
        return AppColors.statusWarning;
      case StockLevel.outOfStock:
        return AppColors.statusBad;
    }
  }
}

/// Tinted badge, never a solid fill - light background, darker text,
/// same pattern used for every status indicator in the app.
class StockStatusBadge extends StatelessWidget {
  final StockLevel level;

  const StockStatusBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level.label,
        style: AppTextStyles.label.copyWith(
          color: level.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
