import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/bookings_repository.dart';
import '../../data/models/appointment.dart';

class BookingsState {
  final List<Appointment> appointments;
  final bool isLoading;
  final String? error;

  const BookingsState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  BookingsState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BookingsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class BookingsCubit extends Cubit<BookingsState> {
  final BookingsRepository _repository;
  bool _isLoaded = false;

  BookingsCubit()
      : _repository = BookingsRepository(),
        super(const BookingsState());

  /// Loads data lazily upon first request.
  Future<void> loadBookings() async {
    if (_isLoaded) return;

    emit(state.copyWith(isLoading: true));
    try {
      final appointments = await _repository.load();
      emit(state.copyWith(
        appointments: appointments,
        isLoading: false,
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
    _isLoaded = true;
  }

  Future<void> addBooking(Appointment appointment) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final saved = await _repository.add(appointment);
      final current = List<Appointment>.from(state.appointments);
      current.add(saved);
      emit(state.copyWith(
        appointments: current,
        isLoading: false,
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
      rethrow;
    }
  }

  Future<void> removeBooking(String id,
      {required String category, required String reason}) async {
    final current = List<Appointment>.from(state.appointments);
    final appointment = current.firstWhere((item) => item.id == id);
    await _repository.cancel(appointment, category: category, reason: reason);
    final refreshed = await _repository.load();
    emit(state.copyWith(appointments: refreshed));
  }

  Future<void> decideBooking(String id, String status, {String? note}) async {
    final current = List<Appointment>.from(state.appointments);
    final index = current.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final updated = await _repository.decide(
      current[index],
      status: status,
      note: note,
    );
    current[index] = updated;
    emit(state.copyWith(appointments: current, clearError: true));
  }

  Future<void> refresh() async {
    _isLoaded = false;
    await loadBookings();
  }
}
