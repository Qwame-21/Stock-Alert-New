import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/maps_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stock_status_badge.dart';
import '../../../../core/widgets/skeleton_loading.dart';
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
  bool _isLocating = false;
  bool _isSearchingPlace = false;
  bool _isLoadingRoute = false;
  Position? _currentPosition;
  List<_SearchedPlace> _placeResults = const [];
  _SearchedPlace? _selectedPlace;
  List<LatLng> _routePoints = const [];
  _RouteSummary? _routeSummary;
  String? _routeError;

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

  Future<void> _locateUser() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const FormatException('Turn on location services to continue.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const FormatException('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = position);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
      if (_selectedPlace != null) {
        await _loadOsrmRoute(_selectedPlace!);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(error.toString().replaceFirst('FormatException: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openDirections(DiscoveredPharmacy pharmacy) async {
    final destination = pharmacy.hasCoordinates
        ? '${pharmacy.latitude},${pharmacy.longitude}'
        : '${pharmacy.name}, ${pharmacy.location}';
    await _launchDirections(destination);
  }

  Future<void> _launchDirections(String destination) async {
    final origin = _currentPosition == null
        ? null
        : '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      if (origin != null) 'origin': origin,
      'destination': destination,
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  Future<void> _openLocationSearch(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _searchDebounce?.cancel();
    setState(() => _isSearchingPlace = true);
    try {
      var candidates = await _photonPlaceSearch(value);
      if (candidates.isEmpty) {
        candidates = await _nativePlaceSearch(value);
      }
      if (candidates.isEmpty) throw const FormatException('Location not found');
      if (!mounted) return;
      setState(() {
        _placeResults = candidates;
        _selectedPlace = candidates.first;
        _isSearchingPlace = false;
        _mapExpanded = false;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(candidates.first.position, 15),
      );
      if (_currentPosition == null) {
        await _locateUser();
      } else {
        await _loadOsrmRoute(candidates.first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearchingPlace = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Could not find "$value". Check your connection or try a more specific address.'),
        ),
      );
    }
  }

  Future<List<_SearchedPlace>> _photonPlaceSearch(String query) async {
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '5',
      'lang': 'en',
    });
    final response = await http.get(uri, headers: {
      'user-agent': 'StockAlert/0.1 (community pharmacy locator)',
    }).timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>? ?? const [];
    return features.map((item) {
      final feature = Map<String, dynamic>.from(item as Map);
      final geometry = Map<String, dynamic>.from(feature['geometry'] as Map);
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final properties = Map<String, dynamic>.from(
        feature['properties'] as Map? ?? const {},
      );
      final labelParts = [
        properties['name'],
        properties['street'],
        properties['city'],
        properties['country'],
      ].whereType<String>().where((part) => part.trim().isNotEmpty).toSet();
      return _SearchedPlace(
        label: labelParts.isEmpty ? query : labelParts.take(3).join(', '),
        position: LatLng(
          (coordinates[1] as num).toDouble(),
          (coordinates[0] as num).toDouble(),
        ),
      );
    }).toList();
  }

  Future<List<_SearchedPlace>> _nativePlaceSearch(String query) async {
    final locations = await Geocoding()
        .locationFromAddress(query)
        .timeout(const Duration(seconds: 12));
    final geocoder = Geocoding();
    return Future.wait(
      locations.take(5).map((location) async {
        final position = LatLng(location.latitude, location.longitude);
        try {
          final placemarks = await geocoder
              .placemarkFromCoordinates(location.latitude, location.longitude)
              .timeout(const Duration(seconds: 5));
          return _SearchedPlace(
            label: _placeLabel(placemarks.firstOrNull, query),
            position: position,
          );
        } catch (_) {
          return _SearchedPlace(label: query, position: position);
        }
      }),
    );
  }

  String _placeLabel(Placemark? place, String fallback) {
    if (place == null) return fallback;
    final parts = [
      place.name,
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toSet();
    return parts.isEmpty ? fallback : parts.take(3).join(', ');
  }

  Future<void> _selectPlace(_SearchedPlace place) async {
    setState(() {
      _selectedPlace = place;
      _routePoints = const [];
      _routeSummary = null;
      _routeError = null;
    });
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(place.position, 15),
    );
    if (_currentPosition == null) {
      await _locateUser();
    } else {
      await _loadOsrmRoute(place);
    }
  }

  Future<void> _loadOsrmRoute(_SearchedPlace destination) async {
    final origin = _currentPosition;
    if (origin == null) return;
    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
    });
    final coordinates =
        '${origin.longitude},${origin.latitude};${destination.position.longitude},${destination.position.latitude}';
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordinates',
    ).replace(queryParameters: {
      'overview': 'full',
      'geometries': 'geojson',
      'steps': 'false',
    });
    try {
      final response = await http.get(uri, headers: {
        'user-agent': 'StockAlert/0.1 (community pharmacy locator)',
      }).timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || decoded['code'] != 'Ok') {
        throw const FormatException('No driving route was found.');
      }
      final routes = decoded['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) {
        throw const FormatException('No driving route was found.');
      }
      final route = Map<String, dynamic>.from(routes.first as Map);
      final geometry = Map<String, dynamic>.from(route['geometry'] as Map);
      final points = (geometry['coordinates'] as List<dynamic>).map((point) {
        final pair = point as List<dynamic>;
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();
      if (!mounted || destination != _selectedPlace) return;
      setState(() {
        _routePoints = points;
        _isLoadingRoute = false;
        _routeSummary = _RouteSummary(
          distanceKm: (route['distance'] as num).toDouble() / 1000,
          durationMinutes: (route['duration'] as num).toDouble() / 60,
        );
      });
      await _fitRoute(points);
    } catch (error) {
      if (!mounted || destination != _selectedPlace) return;
      setState(() {
        _isLoadingRoute = false;
        _routeError = error is TimeoutException
            ? 'Route request timed out. Tap the destination to retry.'
            : error.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  Future<void> _fitRoute(List<LatLng> points) async {
    final controller = _mapController;
    if (controller == null || points.length < 2) return;
    var south = points.first.latitude;
    var north = south;
    var west = points.first.longitude;
    var east = west;
    for (final point in points.skip(1)) {
      south = point.latitude < south ? point.latitude : south;
      north = point.latitude > north ? point.latitude : north;
      west = point.longitude < west ? point.longitude : west;
      east = point.longitude > east ? point.longitude : east;
    }
    await controller.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(south, west),
        northeast: LatLng(north, east),
      ),
      64,
    ));
  }

  Set<Marker> get _markers {
    final markers =
        _pharmacies.where((pharmacy) => pharmacy.hasCoordinates).map((p) {
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
    for (final place in _placeResults) {
      markers.add(
        Marker(
          markerId: MarkerId(
              'place-${place.position.latitude}-${place.position.longitude}'),
          position: place.position,
          zIndexInt: place == _selectedPlace ? 4 : 3,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place == _selectedPlace
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(title: place.label),
          onTap: () => _selectPlace(place),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> get _polylines => _routePoints.isEmpty
      ? const {}
      : {
          Polyline(
            polylineId: const PolylineId('osrm-driving-route'),
            points: _routePoints,
            color: AppColors.accent,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };

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
        .followedBy(_placeResults.map((place) => place.position))
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
              Expanded(
                child: MapsConfig.hasKey
                    ? GoogleMap(
                        initialCameraPosition: _defaultCamera,
                        markers: _markers,
                        polylines: _polylines,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: true,
                        myLocationEnabled: _currentPosition != null,
                        myLocationButtonEnabled: false,
                        padding: EdgeInsets.only(
                          bottom: _mapExpanded
                              ? 24
                              : _placeResults.isEmpty
                                  ? 230
                                  : 322,
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
            left: 0,
            right: 0,
            top: 18,
            child: _SearchPanel(
              controller: _searchController,
              isLoading: _isLoading || _isSearchingPlace,
              onChanged: _onSearchChanged,
              onSubmitted: _openLocationSearch,
              onClear: () {
                _searchController.clear();
                setState(() {
                  _placeResults = const [];
                  _selectedPlace = null;
                });
                _loadPharmacies();
              },
            ),
          ),
          Positioned(
            right: 16,
            top: 104,
            child: _MapControls(
              onZoomIn: () =>
                  _mapController?.animateCamera(CameraUpdate.zoomIn()),
              onZoomOut: () =>
                  _mapController?.animateCamera(CameraUpdate.zoomOut()),
              onFit: _fitMarkers,
              onLocate: _locateUser,
              isLocating: _isLocating,
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
                onDirections: _openDirections,
                currentPosition: _currentPosition,
                searchedPlaces: _placeResults,
                selectedPlace: _selectedPlace,
                onPlaceSelected: _selectPlace,
                onPlaceDirections: (place) => _launchDirections(
                  '${place.position.latitude},${place.position.longitude}',
                ),
                routeSummary: _routeSummary,
                isLoadingRoute: _isLoadingRoute,
                routeError: _routeError,
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
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool isLoading;

  const _SearchPanel({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
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
  final VoidCallback onLocate;
  final bool isLocating;

  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    required this.onLocate,
    required this.isLocating,
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
          const Divider(height: 1),
          IconButton(
            tooltip: 'My location',
            onPressed: isLocating ? null : onLocate,
            icon: isLocating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
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
  final ValueChanged<DiscoveredPharmacy> onDirections;
  final Position? currentPosition;
  final List<_SearchedPlace> searchedPlaces;
  final _SearchedPlace? selectedPlace;
  final ValueChanged<_SearchedPlace> onPlaceSelected;
  final ValueChanged<_SearchedPlace> onPlaceDirections;
  final _RouteSummary? routeSummary;
  final bool isLoadingRoute;
  final String? routeError;

  const _ResultsSheet({
    required this.pharmacies,
    required this.selectedId,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onSelected,
    required this.onDirections,
    required this.currentPosition,
    required this.searchedPlaces,
    required this.selectedPlace,
    required this.onPlaceSelected,
    required this.onPlaceDirections,
    required this.routeSummary,
    required this.isLoadingRoute,
    required this.routeError,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: searchedPlaces.isEmpty ? 0.34 : 0.46,
      minChildSize: 0.22,
      maxChildSize: 0.88,
      snap: true,
      snapSizes:
          searchedPlaces.isEmpty ? const [0.34, 0.88] : const [0.46, 0.88],
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          searchedPlaces.isEmpty
                              ? '${pharmacies.length} pharmacies'
                              : '${searchedPlaces.length} places • ${pharmacies.length} pharmacies',
                          style: AppTextStyles.subheading,
                        ),
                        Text(
                          'Pull up to see all',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.statusGood,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (searchedPlaces.isNotEmpty)
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        itemCount: searchedPlaces.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final place = searchedPlaces[index];
                          final selected = place == selectedPlace;
                          final distance = currentPosition == null
                              ? null
                              : Geolocator.distanceBetween(
                                    currentPosition!.latitude,
                                    currentPosition!.longitude,
                                    place.position.latitude,
                                    place.position.longitude,
                                  ) /
                                  1000;
                          return Material(
                            color: selected
                                ? const Color(0xFFEAF2F1)
                                : const Color(0xFFF5F6F6),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => onPlaceSelected(place),
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 285,
                                child: ListTile(
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(place.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                    selected && isLoadingRoute
                                        ? 'Calculating driving route…'
                                        : selected && routeError != null
                                            ? routeError!
                                            : selected && routeSummary != null
                                                ? '${routeSummary!.distanceKm.toStringAsFixed(1)} km • ${routeSummary!.durationMinutes.ceil()} min drive'
                                                : distance == null
                                                    ? 'Tap to route from your location'
                                                    : '${distance.toStringAsFixed(1)} km away',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Get directions',
                                    onPressed: () => onPlaceDirections(place),
                                    icon: const Icon(Icons.directions_outlined),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (isLoading && pharmacies.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverList.list(
                  children: const [
                    SkeletonBox(width: double.infinity, height: 150),
                    SizedBox(height: 12),
                    SkeletonBox(width: double.infinity, height: 150),
                  ],
                ),
              )
            else if (error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Could not load results. Retry'),
                  ),
                ),
              )
            else if (pharmacies.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      searchedPlaces.isEmpty
                          ? 'No matching pharmacies found.'
                          : 'Destination found. No matching pharmacy inventory nearby.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: pharmacies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pharmacy = pharmacies[index];
                    return PharmacyResultCard(
                      pharmacy: pharmacy,
                      selected: pharmacy.id == selectedId,
                      onTap: () => onSelected(pharmacy),
                      onDirections: () => onDirections(pharmacy),
                      distanceKm:
                          currentPosition == null || !pharmacy.hasCoordinates
                              ? null
                              : Geolocator.distanceBetween(
                                    currentPosition!.latitude,
                                    currentPosition!.longitude,
                                    pharmacy.latitude!,
                                    pharmacy.longitude!,
                                  ) /
                                  1000,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchedPlace {
  const _SearchedPlace({required this.label, required this.position});

  final String label;
  final LatLng position;
}

class _RouteSummary {
  const _RouteSummary({
    required this.distanceKm,
    required this.durationMinutes,
  });

  final double distanceKm;
  final double durationMinutes;
}

class PharmacyResultCard extends StatelessWidget {
  final DiscoveredPharmacy pharmacy;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDirections;
  final double? distanceKm;

  const PharmacyResultCard({
    super.key,
    required this.pharmacy,
    required this.selected,
    required this.onTap,
    required this.onDirections,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final available =
        pharmacy.medicines.where((item) => item.quantity > 0).toList();
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    child: Text(
                      pharmacy.name,
                      style: AppTextStyles.subheading,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Directions to ${pharmacy.name}',
                    onPressed: onDirections,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(Icons.directions_outlined, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  StockStatusBadge(level: pharmacy.stockLevel),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pharmacy.location,
                      style: AppTextStyles.body,
                      maxLines: 3,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      available.isEmpty
                          ? 'No available stock listed'
                          : '${available.length} medicine${available.length == 1 ? '' : 's'} available',
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (distanceKm != null) ...[
                    const SizedBox(width: 8),
                    Text('${distanceKm!.toStringAsFixed(1)} km',
                        style: AppTextStyles.label),
                  ],
                ],
              ),
              if (!pharmacy.hasCoordinates)
                Text('Location pin unavailable',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.statusWarning),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
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
