import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../data/models/appointment.dart';

class BookingsState {
  final List<Appointment> appointments;
  final bool isLoading;

  const BookingsState({
    this.appointments = const [],
    this.isLoading = false,
  });

  BookingsState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
  }) {
    return BookingsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BookingsCubit extends Cubit<BookingsState> {
  final LocalDbService _db;
  bool _isLoaded = false;

  BookingsCubit()
      : _db = LocalDbService(),
        super(const BookingsState());

  /// Loads data lazily upon first request.
  Future<void> loadBookings() async {
    if (_isLoaded) return;

    emit(state.copyWith(isLoading: true));
    final records = await _db.getBookings();

    if (records.isEmpty) {
      // Seed data if DB is empty
      final seedAppt = Appointment(
        id: 'BKG-101',
        doctorName: 'Dr. Emmanuel Boateng',
        specialty: 'General Practitioner',
        date: '15/07/2026',
        time: '10:30 AM',
      );
      await _db.insertBooking(seedAppt.toJson());
      emit(state.copyWith(appointments: [seedAppt], isLoading: false));
    } else {
      final appts = records.map((r) => Appointment.fromJson(r)).toList();
      emit(state.copyWith(appointments: appts, isLoading: false));
    }
    _isLoaded = true;
  }

  Future<void> addBooking(Appointment appointment) async {
    await _db.insertBooking(appointment.toJson());
    final current = List<Appointment>.from(state.appointments);
    current.add(appointment);
    emit(state.copyWith(appointments: current));
  }

  Future<void> removeBooking(String id) async {
    await _db.deleteBooking(id);
    final current = List<Appointment>.from(state.appointments);
    current.removeWhere((appt) => appt.id == id);
    emit(state.copyWith(appointments: current));
  }
}
