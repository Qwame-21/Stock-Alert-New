import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../data/models/inventory_medicine.dart';
import '../../data/inventory_seed_data.dart';

class InventoryState {
  final List<InventoryMedicine> medicines;
  final bool isLoading;

  const InventoryState({
    this.medicines = const [],
    this.isLoading = false,
  });

  InventoryState copyWith({
    List<InventoryMedicine>? medicines,
    bool? isLoading,
  }) {
    return InventoryState(
      medicines: medicines ?? this.medicines,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class InventoryCubit extends Cubit<InventoryState> {
  final LocalDbService _db;
  bool _isLoaded = false;

  InventoryCubit()
      : _db = LocalDbService(),
        super(const InventoryState());

  /// Loads data lazily upon first request.
  Future<void> loadInventory() async {
    if (_isLoaded) return;
    
    emit(state.copyWith(isLoading: true));
    final records = await _db.getMedicines();
    
    if (records.isEmpty) {
      // Seed data if DB is empty
      for (final med in sampleMedicines) {
        await _db.insertMedicine(med.toJson());
      }
      emit(state.copyWith(medicines: sampleMedicines, isLoading: false));
    } else {
      final meds = records.map((r) => InventoryMedicine.fromJson(r)).toList();
      emit(state.copyWith(medicines: meds, isLoading: false));
    }
    _isLoaded = true;
  }

  Future<void> addMedicine(InventoryMedicine medicine) async {
    await _db.insertMedicine(medicine.toJson());
    final current = List<InventoryMedicine>.from(state.medicines);
    
    // Replace if exists, else add
    final idx = current.indexWhere((m) => m.id == medicine.id);
    if (idx >= 0) {
      current[idx] = medicine;
    } else {
      current.add(medicine);
    }
    
    emit(state.copyWith(medicines: current));
  }
}
