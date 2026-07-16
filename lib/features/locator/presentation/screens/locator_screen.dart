import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/maps_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stock_status_badge.dart';
import '../../data/pharmacy_discovery_repository.dart';

class LocatorScreen extends StatefulWidget {
  final String? initialSearch;
  final String? highlightPharmacyName;

  const LocatorScreen({
    super.key,
    this.initialSearch,
    this.highlightPharmacyName,
  });

  @override
  State<LocatorScreen> createState() => _LocatorScreenState();
}

class _LocatorScreenState extends State<LocatorScreen> {
  static const _defaultCamera = CameraPosition(
    target: LatLng(5.6037, -0.1870),
    zoom: 12.5,
  );

  final _repository = PharmacyDiscoveryRepository();
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  List<DiscoveredPharmacy> _pharmacies = const [];
  String? _selectedPharmacyId;
  String? _error;
  bool _isLoading = true;
  bool _mapExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch ?? '';
    _loadPharmacies(_searchController.text);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies([String query = '']) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _repository.search(query);
      if (!mounted) return;
      setState(() {
        _pharmacies = results;
        _isLoading = false;
        final highlighted = widget.highlightPharmacyName;
        if (_selectedPharmacyId == null && highlighted != null) {
          for (final pharmacy in results) {
            if (pharmacy.name.toLowerCase() == highlighted.toLowerCase()) {
              _selectedPharmacyId = pharmacy.id;
              break;
            }
          }
        }
      });
      await _fitMarkers();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadPharmacies(value),
    );
  }

  Set<Marker> get _markers {
    return _pharmacies.where((pharmacy) => pharmacy.hasCoordinates).map((p) {
      final selected = p.id == _selectedPharmacyId;
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.latitude!, p.longitude!),
        zIndexInt: selected ? 2 : 1,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected
              ? BitmapDescriptor.hueAzure
              : p.stockLevel == StockLevel.inStock
                  ? BitmapDescriptor.hueGreen
                  : p.stockLevel == StockLevel.lowStock
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(title: p.name, snippet: p.location),
        onTap: () => _selectPharmacy(p),
      );
    }).toSet();
  }

  Future<void> _selectPharmacy(DiscoveredPharmacy pharmacy) async {
    setState(() => _selectedPharmacyId = pharmacy.id);
    if (pharmacy.hasCoordinates) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pharmacy.latitude!, pharmacy.longitude!),
          15,
        ),
      );
    }
  }

  Future<void> _fitMarkers() async {
    final controller = _mapController;
    final points = _pharmacies
        .where((pharmacy) => pharmacy.hasCoordinates)
        .map((pharmacy) => LatLng(pharmacy.latitude!, pharmacy.longitude!))
        .toList();
    if (controller == null || points.isEmpty) return;
    if (points.length == 1) {
      await controller
          .animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }
    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;
    for (final point in points.skip(1)) {
      south = point.latitude < south ? point.latitude : south;
      north = point.latitude > north ? point.latitude : north;
      west = point.longitude < west ? point.longitude : west;
      east = point.longitude > east ? point.longitude : east;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/patient/home'),
        ),
        title: Text('Nearby pharmacies', style: AppTextStyles.subheading),
        actions: [
          IconButton(
            tooltip: _mapExpanded ? 'Show results' : 'Expand map',
            onPressed: () => setState(() => _mapExpanded = !_mapExpanded),
            icon: Icon(
                _mapExpanded ? Icons.view_list_outlined : Icons.map_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _SearchPanel(
                controller: _searchController,
                isLoading: _isLoading,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  _loadPharmacies();
                },
              ),
              Expanded(
                child: MapsConfig.hasKey
                    ? GoogleMap(
                        initialCameraPosition: _defaultCamera,
                        markers: _markers,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: true,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        padding: EdgeInsets.only(
                          bottom: _mapExpanded ? 24 : 230,
                          right: 8,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _fitMarkers();
                        },
                      )
                    : const _MapUnavailable(),
              ),
            ],
          ),
          Positioned(
            right: 16,
            top: 86,
            child: _MapControls(
              onZoomIn: () =>
                  _mapController?.animateCamera(CameraUpdate.zoomIn()),
              onZoomOut: () =>
                  _mapController?.animateCamera(CameraUpdate.zoomOut()),
              onFit: _fitMarkers,
            ),
          ),
          if (!_mapExpanded)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ResultsSheet(
                pharmacies: _pharmacies,
                selectedId: _selectedPharmacyId,
                isLoading: _isLoading,
                error: _error,
                onRetry: () => _loadPharmacies(_searchController.text),
                onSelected: _selectPharmacy,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isLoading;

  const _SearchPanel({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search pharmacy, location or medicine',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : controller.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.hairline),
          ),
        ),
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;

  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              tooltip: 'Zoom in',
              onPressed: onZoomIn,
              icon: const Icon(Icons.add)),
          const Divider(height: 1),
          IconButton(
              tooltip: 'Zoom out',
              onPressed: onZoomOut,
              icon: const Icon(Icons.remove)),
          const Divider(height: 1),
          IconButton(
              tooltip: 'Show all',
              onPressed: onFit,
              icon: const Icon(Icons.center_focus_strong)),
        ],
      ),
    );
  }
}

class _ResultsSheet extends StatelessWidget {
  final List<DiscoveredPharmacy> pharmacies;
  final String? selectedId;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<DiscoveredPharmacy> onSelected;

  const _ResultsSheet({
    required this.pharmacies,
    required this.selectedId,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 10),
            child: Row(
              children: [
                Text('${pharmacies.length} pharmacies',
                    style: AppTextStyles.subheading),
                const Spacer(),
                Text('Live inventory',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.statusGood)),
              ],
            ),
          ),
          Expanded(
            child: error != null
                ? Center(
                    child: TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Could not load results. Retry'),
                    ),
                  )
                : !isLoading && pharmacies.isEmpty
                    ? Center(
                        child: Text('No matching pharmacies found.',
                            style: AppTextStyles.body))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pharmacies.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final pharmacy = pharmacies[index];
                          return _PharmacyCard(
                            pharmacy: pharmacy,
                            selected: pharmacy.id == selectedId,
                            onTap: () => onSelected(pharmacy),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final DiscoveredPharmacy pharmacy;
  final bool selected;
  final VoidCallback onTap;

  const _PharmacyCard({
    required this.pharmacy,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available =
        pharmacy.medicines.where((item) => item.quantity > 0).toList();
    return SizedBox(
      width: 270,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.06)
                : Colors.white,
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.hairline),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(pharmacy.name,
                          style: AppTextStyles.subheading, maxLines: 1)),
                  StockStatusBadge(level: pharmacy.stockLevel),
                ],
              ),
              const SizedBox(height: 6),
              Text(pharmacy.location, style: AppTextStyles.body, maxLines: 1),
              const Spacer(),
              Text(
                available.isEmpty
                    ? 'No available stock listed'
                    : '${available.length} medicine${available.length == 1 ? '' : 's'} available',
                style: AppTextStyles.label,
              ),
              if (!pharmacy.hasCoordinates)
                Text('Location pin unavailable',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.statusWarning)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined,
              size: 44, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text('Google Maps is not configured.', style: AppTextStyles.body),
        ],
      ),
    );
  }
}
