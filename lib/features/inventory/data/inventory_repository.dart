import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_db_service.dart';
import '../../../core/sync/sync_manager.dart';
import '../../onboarding/data/profile_repository.dart';
import 'models/inventory_medicine.dart';

class InventoryRepository {
  final ApiClient _api;
  final LocalDbService _db;
  final ProfileRepository _profiles;

  InventoryRepository({
    ApiClient? api,
    LocalDbService? db,
    ProfileRepository? profiles,
  })  : _api = api ?? ApiClient.instance,
        _db = db ?? LocalDbService(),
        _profiles = profiles ?? ProfileRepository();

  Future<List<InventoryMedicine>> load() async {
    final cached =
        (await _db.getMedicines()).map(InventoryMedicine.fromJson).toList();
    if (!ApiConfig.remoteInventoryEnabled) return cached;
    try {
      final profile = await _profiles.getMe();
      final pharmacyId = profile['pharmacy_id'] as String?;
      if (pharmacyId == null || pharmacyId.isEmpty) return cached;
      final response = await _api.get('/api/v1/inventory', query: {
        'pharmacyId': pharmacyId,
        'includeOutOfStock': 'true',
      });
      final items = (response.data as List)
          .map((item) =>
              InventoryMedicine.fromApi(Map<String, dynamic>.from(item as Map)))
          .toList();
      for (final item in items) {
        await _db.insertMedicine(item.toJson());
      }
      return items;
    } catch (_) {
      return cached;
    }
  }

  Future<InventoryMedicine> add(InventoryMedicine medicine) async {
    await _db.insertMedicine(medicine.toJson());
    if (!ApiConfig.remoteInventoryEnabled) return medicine;
    final mutationId = const Uuid().v4();
    try {
      final profile = await _profiles.getMe();
      final pharmacyId = profile['pharmacy_id'] as String?;
      if (pharmacyId == null || pharmacyId.isEmpty) return medicine;
      final payload = {
        'pharmacyId': pharmacyId,
        'medicine': {'name': medicine.name},
        'quantity': medicine.quantity,
        'expiryDate': medicine.expiry.isEmpty ? null : medicine.expiry,
      };
      final response = await _api.post('/api/v1/inventory', body: {
        'mutationId': mutationId,
        ...payload,
      });
      final saved = InventoryMedicine.fromApi(
        Map<String, dynamic>.from(response.data as Map),
      );
      await _db.insertMedicine(saved.toJson());
      return saved;
    } catch (_) {
      final profile =
          await _profiles.getMe().catchError((_) => <String, dynamic>{});
      final pharmacyId = profile['pharmacy_id'] as String?;
      await _db.enqueueSyncMutation({
        'mutationId': mutationId,
        'entityType': 'inventory',
        'operation': 'create',
        'entityId': null,
        'payload': {
          'pharmacyId': pharmacyId,
          'medicine': {'name': medicine.name},
          'quantity': medicine.quantity,
          'expiryDate': medicine.expiry.isEmpty ? null : medicine.expiry,
        },
      });
      if (ApiConfig.backgroundSyncEnabled) {
        unawaited(SyncManager().attemptSync().catchError((_) {}));
      }
      return medicine;
    }
  }
}
