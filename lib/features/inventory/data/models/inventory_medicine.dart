import '../../../../core/widgets/stock_status_badge.dart';

class InventoryMedicine {
  final String id;
  final String name;
  final String expiry;
  final StockLevel level;

  const InventoryMedicine({
    required this.id,
    required this.name,
    required this.expiry,
    required this.level,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expiry': expiry,
      'level': level.name,
    };
  }

  factory InventoryMedicine.fromJson(Map<String, dynamic> json) {
    return InventoryMedicine(
      id: json['id'] as String,
      name: json['name'] as String,
      expiry: json['expiry'] as String,
      level: StockLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => StockLevel.inStock,
      ),
    );
  }
}
