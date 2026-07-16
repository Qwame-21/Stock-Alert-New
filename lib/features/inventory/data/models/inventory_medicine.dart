import '../../../../core/widgets/stock_status_badge.dart';

class InventoryMedicine {
  final String id;
  final String name;
  final String expiry;
  final StockLevel level;
  final int quantity;
  final int version;

  const InventoryMedicine({
    required this.id,
    required this.name,
    required this.expiry,
    required this.level,
    this.quantity = 0,
    this.version = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expiry': expiry,
      'level': level.name,
      'quantity': quantity,
      'version': version,
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
      quantity: json['quantity'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
    );
  }

  factory InventoryMedicine.fromApi(Map<String, dynamic> json) {
    final medicine =
        Map<String, dynamic>.from(json['medicines'] as Map? ?? const {});
    final quantity = json['quantity'] as int? ?? 0;
    final reorderLevel = json['reorder_level'] as int? ?? 0;
    return InventoryMedicine(
      id: json['id'] as String,
      name: medicine['canonical_name'] as String? ?? 'Unknown medicine',
      expiry: json['expiry_date'] as String? ?? '',
      quantity: quantity,
      version: json['version'] as int? ?? 1,
      level: quantity <= 0
          ? StockLevel.outOfStock
          : quantity <= reorderLevel
              ? StockLevel.lowStock
              : StockLevel.inStock,
    );
  }
}
