import '../../../core/network/api_client.dart';
import '../../../core/widgets/stock_status_badge.dart';

class PharmacyMedicine {
  final String name;
  final String? genericName;
  final String? brandName;
  final String? strength;
  final int quantity;
  final StockLevel stockLevel;

  const PharmacyMedicine({
    required this.name,
    required this.quantity,
    required this.stockLevel,
    this.genericName,
    this.brandName,
    this.strength,
  });

  factory PharmacyMedicine.fromJson(Map<String, dynamic> json) {
    final level = switch (json['stockLevel']) {
      'lowStock' => StockLevel.lowStock,
      'outOfStock' => StockLevel.outOfStock,
      _ => StockLevel.inStock,
    };
    return PharmacyMedicine(
      name: json['name'] as String? ?? 'Unknown medicine',
      genericName: json['genericName'] as String?,
      brandName: json['brandName'] as String?,
      strength: json['strength'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      stockLevel: level,
    );
  }
}

class DiscoveredPharmacy {
  final String id;
  final String name;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? operatingHours;
  final String verificationStatus;
  final List<PharmacyMedicine> medicines;

  const DiscoveredPharmacy({
    required this.id,
    required this.name,
    required this.location,
    required this.verificationStatus,
    required this.medicines,
    this.latitude,
    this.longitude,
    this.operatingHours,
  });

  factory DiscoveredPharmacy.fromJson(Map<String, dynamic> json) {
    return DiscoveredPharmacy(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Pharmacy',
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      operatingHours: json['operatingHours'] as String?,
      verificationStatus: json['verificationStatus'] as String? ?? 'pending',
      medicines: (json['medicines'] as List? ?? const [])
          .map((item) =>
              PharmacyMedicine.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  StockLevel get stockLevel {
    if (medicines.any((item) => item.stockLevel == StockLevel.inStock)) {
      return StockLevel.inStock;
    }
    if (medicines.any((item) => item.stockLevel == StockLevel.lowStock)) {
      return StockLevel.lowStock;
    }
    return StockLevel.outOfStock;
  }
}

class PharmacyDiscoveryRepository {
  final ApiClient _api;

  PharmacyDiscoveryRepository({ApiClient? api})
      : _api = api ?? ApiClient.instance;

  Future<List<DiscoveredPharmacy>> search([String query = '']) async {
    final response = await _api.get(
      '/api/v1/discovery/pharmacies',
      query: {
        if (query.trim().isNotEmpty) 'search': query.trim(),
        'limit': '100',
      },
    );
    return (response.data as List)
        .map((item) =>
            DiscoveredPharmacy.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
