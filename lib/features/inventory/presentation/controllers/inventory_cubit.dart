import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/inventory_repository.dart';
import '../../data/models/inventory_medicine.dart';

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
  final InventoryRepository _repository;
  bool _isLoaded = false;

  InventoryCubit()
      : _repository = InventoryRepository(),
        super(const InventoryState());

  /// Loads data lazily upon first request.
  Future<void> loadInventory() async {
    if (_isLoaded) return;

    emit(state.copyWith(isLoading: true));
    final medicines = await _repository.load();
    emit(state.copyWith(medicines: medicines, isLoading: false));
    _isLoaded = true;
  }

  Future<void> addMedicine(InventoryMedicine medicine) async {
    final saved = await _repository.add(medicine);
    final current = List<InventoryMedicine>.from(state.medicines);

    // Replace if exists, else add
    final idx = current.indexWhere((m) => m.id == medicine.id);
    if (idx >= 0) {
      current[idx] = saved;
    } else {
      current.add(saved);
    }

    emit(state.copyWith(medicines: current));
  }
}
