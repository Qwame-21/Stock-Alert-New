import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/config/maps_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stock_status_badge.dart';
import '../../../onboarding/presentation/controllers/registration_cubit.dart';

class NearbyPharmacy {
  final String name;
  final String distanceLabel;
  final bool isOpen;
  final StockLevel level;
  final List<String> previewInventory;

  /// Approximate coordinates used for real map pins.
  /// Defaults to Accra city centre if not provided.
  final double latitude;
  final double longitude;

  const NearbyPharmacy({
    required this.name,
    required this.distanceLabel,
    required this.isOpen,
    required this.level,
    this.previewInventory = const [],
    this.latitude = 5.6037,
    this.longitude = -0.1870,
  });
}

class LocatorScreen extends StatefulWidget {
  final List<NearbyPharmacy> pharmacies;
  final String? highlightPharmacyName;

  const LocatorScreen({
    super.key,
    required this.pharmacies,
    this.highlightPharmacyName,
  });

  @override
  State<LocatorScreen> createState() => _LocatorScreenState();
}

class _LocatorScreenState extends State<LocatorScreen> {
  String? _expandedPharmacy;
  GoogleMapController? _mapController;

  // Default camera — Accra, Ghana
  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(5.6037, -0.1870),
    zoom: 14,
  );

  Set<Marker> get _markers {
    return {
      for (final p in widget.pharmacies)
        Marker(
          markerId: MarkerId(p.name),
          position: LatLng(p.latitude, p.longitude),
          infoWindow: InfoWindow(
            title: p.name,
            snippet: '${p.distanceLabel} · ${p.isOpen ? "Open" : "Closed"}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            p.level == StockLevel.inStock
                ? BitmapDescriptor.hueGreen
                : p.level == StockLevel.lowStock
                    ? BitmapDescriptor.hueOrange
                    : BitmapDescriptor.hueRed,
          ),
          onTap: () => setState(() => _expandedPharmacy = p.name),
        ),
    };
  }

  @override
  void initState() {
    super.initState();
    if (widget.highlightPharmacyName != null) {
      _expandedPharmacy = widget.highlightPharmacyName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            final role = context.read<RegistrationCubit>().state.role;
                            if (role == 'pharmacy') {
                              context.go('/pharmacy/dashboard');
                            } else {
                              context.go('/patient/home');
                            }
                          }
                        },
                      ),
                      Text('Nearby Pharmacies', style: AppTextStyles.subheading),
                    ],
                  ),
                ),
              ),
              // ── Map layer ────────────────────────────────────────────────
              Expanded(
                child: MapsConfig.hasKey
                    ? _RealMap(
                        camera: _defaultCamera,
                        markers: _markers,
                        onMapCreated: (c) => _mapController = c,
                      )
                    : const _MapsUnavailablePlaceholder(),
              ),
            ],
          ),
          // ── Bottom sheet ─────────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.hairline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    for (final pharmacy in widget.pharmacies) ...[
                      _PharmacyRow(
                        pharmacy: pharmacy,
                        isExpanded: _expandedPharmacy == pharmacy.name,
                        onTap: () {
                          setState(() {
                            _expandedPharmacy =
                                _expandedPharmacy == pharmacy.name
                                    ? null
                                    : pharmacy.name;
                          });
                          // Pan real map to selected pharmacy
                          if (MapsConfig.hasKey && _mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(pharmacy.latitude, pharmacy.longitude),
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 12),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Real map widget ───────────────────────────────────────────────────────────

class _RealMap extends StatelessWidget {
  final CameraPosition camera;
  final Set<Marker> markers;
  final void Function(GoogleMapController) onMapCreated;

  const _RealMap({
    required this.camera,
    required this.markers,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: camera,
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      onMapCreated: onMapCreated,
    );
  }
}

class _MapsUnavailablePlaceholder extends StatelessWidget {
  const _MapsUnavailablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: AppColors.textSecondary.withValues(alpha: 0.5), size: 40),
            const SizedBox(height: 12),
            Text(
              'Map unavailable',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pharmacy list row ─────────────────────────────────────────────────────────

class _PharmacyRow extends StatelessWidget {
  final NearbyPharmacy pharmacy;
  final bool isExpanded;
  final VoidCallback onTap;

  const _PharmacyRow({
    required this.pharmacy,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isExpanded ? AppColors.accent : AppColors.hairline),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.textSecondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pharmacy.name, style: AppTextStyles.subheading),
                        Text(
                          '${pharmacy.distanceLabel} · ${pharmacy.isOpen ? "Open" : "Closed"}',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  StockStatusBadge(level: pharmacy.level),
                ],
              ),
              if (isExpanded) ...[
                const Divider(height: 24, color: AppColors.hairline),
                Text(
                  'Relevant Inventory:',
                  style: AppTextStyles.label
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (pharmacy.previewInventory.isNotEmpty)
                  ...pharmacy.previewInventory.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item, style: AppTextStyles.body),
                          StockStatusBadge(level: pharmacy.level),
                        ],
                      ),
                    );
                  })
                else ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amoxicillin 500mg', style: AppTextStyles.body),
                        StockStatusBadge(level: StockLevel.inStock),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ibuprofen 400mg', style: AppTextStyles.body),
                        StockStatusBadge(level: StockLevel.inStock),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}


