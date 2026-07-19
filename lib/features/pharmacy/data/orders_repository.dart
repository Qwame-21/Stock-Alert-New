import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../onboarding/data/profile_repository.dart';
import 'order_models.dart';

class OrdersRepository {
  final ApiClient _api;
  final ProfileRepository _profiles;
  OrdersRepository({ApiClient? api, ProfileRepository? profiles})
      : _api = api ?? ApiClient.instance,
        _profiles = profiles ?? ProfileRepository();
  Future<String> _pharmacyId() async {
    final id = (await _profiles.getMe())['pharmacy_id'] as String?;
    if (id == null || id.isEmpty) {
      throw StateError('A pharmacy account is required.');
    }
    return id;
  }

  Future<List<Supplier>> suppliers() async {
    final r = await _api
        .get('/api/v1/suppliers', query: {'pharmacyId': await _pharmacyId()});
    return (r.data as List)
        .map((e) => Supplier.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Supplier> addSupplier(
      {required String name,
      String phone = '',
      String email = '',
      String contactPerson = '',
      String paymentTerms = '',
      int leadTimeDays = 0}) async {
    final r = await _api.post('/api/v1/suppliers', body: {
      'pharmacyId': await _pharmacyId(),
      'name': name,
      'phone': phone,
      'email': email.isEmpty ? null : email,
      'contactPerson': contactPerson,
      'paymentTerms': paymentTerms,
      'leadTimeDays': leadTimeDays
    });
    return Supplier.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<List<PurchaseOrder>> orders() async {
    final r = await _api.get('/api/v1/purchase-orders',
        query: {'pharmacyId': await _pharmacyId()});
    return (r.data as List)
        .map((e) => PurchaseOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> createOrder(
      {required String supplierId,
      required List<Map<String, dynamic>> items,
      DateTime? expectedDate,
      String notes = ''}) async {
    await _api.post('/api/v1/purchase-orders', body: {
      'pharmacyId': await _pharmacyId(),
      'supplierId': supplierId,
      'expectedDeliveryDate': expectedDate?.toIso8601String().split('T').first,
      'notes': notes,
      'items': items
    });
  }

  Future<void> updateStatus(String id, String status) async {
    await _api.patch('/api/v1/purchase-orders/$id', body: {'status': status});
  }

  Future<void> receive(String id, List<Map<String, dynamic>> lines) async {
    await _api.post('/api/v1/purchase-orders/$id/receive', body: {
      'lines': lines
          .map((line) => {...line, 'mutationId': const Uuid().v4()})
          .toList()
    });
  }
}
