import 'package:uuid/uuid.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_db_service.dart';
import 'models/appointment.dart';

class BookingsRepository {
  final ApiClient _api;
  final LocalDbService _db;

  BookingsRepository({ApiClient? api, LocalDbService? db})
      : _api = api ?? ApiClient.instance,
        _db = db ?? LocalDbService();

  Future<List<Appointment>> load() async {
    final cached = (await _db.getBookings()).map(Appointment.fromJson).toList();
    if (!ApiConfig.remoteBookingsEnabled) return cached;
    try {
      final response = await _api.get('/api/v1/bookings');
      final items = (response.data as List)
          .map((item) =>
              Appointment.fromApi(Map<String, dynamic>.from(item as Map)))
          .toList();
      for (final item in items) {
        await _db.insertBooking(item.toJson());
      }
      return items;
    } catch (_) {
      return cached;
    }
  }

  Future<Appointment> add(Appointment appointment) async {
    await _db.insertBooking(appointment.toJson());
    if (!ApiConfig.remoteBookingsEnabled) return appointment;
    final scheduledAt = _scheduledAt(appointment);
    if (!scheduledAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      await _db.deleteBooking(appointment.id);
      throw StateError(
        'Choose an appointment time at least five minutes in the future.',
      );
    }
    final mutationId = const Uuid().v4();
    final payload = {
      'providerId': appointment.providerId,
      'providerName': appointment.doctorName,
      'specialty': appointment.specialty,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      'notes': appointment.notes,
    };
    try {
      final response = await _api.post('/api/v1/bookings', body: {
        'mutationId': mutationId,
        ...payload,
      });
      final saved =
          Appointment.fromApi(Map<String, dynamic>.from(response.data as Map));
      await _db.deleteBooking(appointment.id);
      await _db.insertBooking(saved.toJson());
      return saved;
    } catch (error) {
      await _db.deleteBooking(appointment.id);
      rethrow;
    }
  }

  Future<void> cancel(Appointment appointment) async {
    if (!ApiConfig.remoteBookingsEnabled) {
      await _db.deleteBooking(appointment.id);
      return;
    }
    final mutationId = const Uuid().v4();
    final payload = {
      'expectedVersion': appointment.version,
      'reason': 'Cancelled by patient',
    };
    try {
      await _api.delete('/api/v1/bookings/${appointment.id}', body: {
        'mutationId': mutationId,
        ...payload,
      });
    } catch (_) {
      rethrow;
    }
    await _db.deleteBooking(appointment.id);
  }

  DateTime _scheduledAt(Appointment appointment) {
    final dateParts = appointment.date.split('/');
    final timeParts = appointment.time.split(RegExp(r'[: ]'));
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final meridiem = timeParts[2].toUpperCase();
    if (meridiem == 'PM' && hour != 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
      hour,
      minute,
    );
  }
}
