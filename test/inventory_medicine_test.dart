import 'package:flutter_test/flutter_test.dart';
import 'package:stockalert/core/widgets/stock_status_badge.dart';
import 'package:stockalert/features/inventory/data/models/inventory_medicine.dart';

void main() {
  test('preserves batch and barcode metadata in the local cache', () {
    const medicine = InventoryMedicine(
      id: 'inventory-1',
      name: 'Amoxicillin 500mg',
      expiry: '2030-10-15',
      level: StockLevel.inStock,
      quantity: 100,
      barcode: '0123456789012',
      batchNumber: 'AMX-2030-10',
      genericName: 'Amoxicillin',
      brandName: 'Example Brand',
      strength: '500mg',
      dosageForm: 'Capsule',
      manufacturer: 'Example Pharma',
      reorderLevel: 20,
      unitPrice: 1.25,
    );

    final restored = InventoryMedicine.fromJson(medicine.toJson());

    expect(restored.barcode, medicine.barcode);
    expect(restored.batchNumber, medicine.batchNumber);
    expect(restored.quantity, 100);
    expect(restored.reorderLevel, 20);
    expect(restored.unitPrice, 1.25);
  });

  test('maps complete API inventory records', () {
    final medicine = InventoryMedicine.fromApi({
      'id': 'inventory-2',
      'batch_number': 'PCM-42',
      'quantity': 5,
      'reorder_level': 10,
      'expiry_date': '2031-01-01',
      'unit_price': 3.5,
      'currency': 'GHS',
      'version': 2,
      'medicines': {
        'canonical_name': 'Paracetamol 500mg',
        'generic_name': 'Paracetamol',
        'brand_name': null,
        'strength': '500mg',
        'dosage_form': 'Tablet',
        'barcode': '9876543210123',
        'manufacturer': 'Community Labs',
      },
    });

    expect(medicine.level, StockLevel.lowStock);
    expect(medicine.batchNumber, 'PCM-42');
    expect(medicine.barcode, '9876543210123');
    expect(medicine.version, 2);
  });

  test('identifies expired batches', () {
    const medicine = InventoryMedicine(
      id: 'inventory-3',
      name: 'Expired medicine',
      expiry: '2000-01-01',
      level: StockLevel.inStock,
    );

    expect(medicine.isExpired, isTrue);
    expect(medicine.isExpiringSoon, isFalse);
  });
}
