import '../../../../core/widgets/stock_status_badge.dart';
import 'models/inventory_medicine.dart';

const List<InventoryMedicine> sampleMedicines = [
  InventoryMedicine(
      id: 'MED-101',
      name: 'Amoxicillin 500mg',
      expiry: '2026-10-15',
      level: StockLevel.inStock),
  InventoryMedicine(
      id: 'MED-102',
      name: 'Paracetamol 500mg',
      expiry: '2027-02-28',
      level: StockLevel.lowStock),
  InventoryMedicine(
      id: 'MED-103',
      name: 'Cough Syrup 100ml',
      expiry: '2025-11-30',
      level: StockLevel.lowStock),
  InventoryMedicine(
      id: 'MED-104',
      name: 'Ibuprofen 400mg',
      expiry: '2026-12-01',
      level: StockLevel.inStock),
  InventoryMedicine(
      id: 'MED-105',
      name: 'Cetirizine 10mg',
      expiry: '2026-02-20',
      level: StockLevel.outOfStock),
];
