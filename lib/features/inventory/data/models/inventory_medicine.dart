import '../../../../core/widgets/stock_status_badge.dart';

class InventoryMedicine {
  final String id;
  final String name;
  final String expiry;
  final StockLevel level;
  final int quantity;
  final int version;
  final String barcode;
  final String batchNumber;
  final String genericName;
  final String brandName;
  final String strength;
  final String dosageForm;
  final String manufacturer;
  final int reorderLevel;
  final double? unitPrice;
  final String currency;

  const InventoryMedicine({
    required this.id,
    required this.name,
    required this.expiry,
    required this.level,
    this.quantity = 0,
    this.version = 1,
    this.barcode = '',
    this.batchNumber = '',
    this.genericName = '',
    this.brandName = '',
    this.strength = '',
    this.dosageForm = '',
    this.manufacturer = '',
    this.reorderLevel = 0,
    this.unitPrice,
    this.currency = 'GHS',
  });

  DateTime? get expiryDate => DateTime.tryParse(expiry);

  int? get daysUntilExpiry {
    final date = expiryDate;
    if (date == null) return null;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return date.difference(start).inDays;
  }

  bool get isExpired => daysUntilExpiry != null && daysUntilExpiry! < 0;
  bool get isExpiringSoon =>
      daysUntilExpiry != null &&
      daysUntilExpiry! >= 0 &&
      daysUntilExpiry! <= 90;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expiry': expiry,
      'level': level.name,
      'quantity': quantity,
      'version': version,
      'barcode': barcode,
      'batchNumber': batchNumber,
      'genericName': genericName,
      'brandName': brandName,
      'strength': strength,
      'dosageForm': dosageForm,
      'manufacturer': manufacturer,
      'reorderLevel': reorderLevel,
      'unitPrice': unitPrice,
      'currency': currency,
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
      barcode: json['barcode'] as String? ?? '',
      batchNumber: json['batchNumber'] as String? ?? '',
      genericName: json['genericName'] as String? ?? '',
      brandName: json['brandName'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
      dosageForm: json['dosageForm'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      reorderLevel: json['reorderLevel'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'GHS',
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
      barcode: medicine['barcode'] as String? ?? '',
      batchNumber: json['batch_number'] as String? ?? '',
      genericName: medicine['generic_name'] as String? ?? '',
      brandName: medicine['brand_name'] as String? ?? '',
      strength: medicine['strength'] as String? ?? '',
      dosageForm: medicine['dosage_form'] as String? ?? '',
      manufacturer: medicine['manufacturer'] as String? ?? '',
      reorderLevel: reorderLevel,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'GHS',
      level: quantity <= 0
          ? StockLevel.outOfStock
          : quantity <= reorderLevel
              ? StockLevel.lowStock
              : StockLevel.inStock,
    );
  }
}
