import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stock_status_badge.dart';
import '../../../locator/data/pharmacy_discovery_repository.dart';

class FindMedicineScreen extends StatefulWidget {
  const FindMedicineScreen({super.key});

  @override
  State<FindMedicineScreen> createState() => _FindMedicineScreenState();
}

class _FindMedicineScreenState extends State<FindMedicineScreen> {
  final _repository = PharmacyDiscoveryRepository();
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<DiscoveredPharmacy> _pharmacies = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search([String query = '']) async {
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
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = [
      for (final pharmacy in _pharmacies)
        for (final medicine in pharmacy.medicines)
          (pharmacy: pharmacy, medicine: medicine),
    ]..sort((left, right) {
        final stockComparison = left.medicine.stockLevel.index
            .compareTo(right.medicine.stockLevel.index);
        if (stockComparison != 0) return stockComparison;
        return left.pharmacy.location
            .toLowerCase()
            .compareTo(right.pharmacy.location.toLowerCase());
      });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/patient/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Medicine search', style: AppTextStyles.subheading),
        actions: [
          IconButton(
            tooltip: 'View nearby pharmacies',
            onPressed: () => context.push(
              '/patient/nearby',
              extra: {'search': _searchController.text},
            ),
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search medicine name, brand or pharmacy',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _search();
                            },
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
          ),
          if (!_isLoading && _error == null && results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${results.length} stocked location${results.length == 1 ? '' : 's'} • tap a place for its map',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _error != null
                ? _SearchError(onRetry: () => _search(_searchController.text))
                : !_isLoading && results.isEmpty
                    ? const _EmptySearch()
                    : RefreshIndicator(
                        onRefresh: () => _search(_searchController.text),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final result = results[index];
                            return _MedicineResultCard(
                              pharmacy: result.pharmacy,
                              medicine: result.medicine,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MedicineResultCard extends StatelessWidget {
  final DiscoveredPharmacy pharmacy;
  final PharmacyMedicine medicine;

  const _MedicineResultCard({
    required this.pharmacy,
    required this.medicine,
  });

  void _openMap(BuildContext context) => context.push(
        '/patient/nearby',
        extra: {'highlight': pharmacy.name, 'search': medicine.name},
      );

  Future<void> _openDirections(BuildContext context) async {
    final destination = pharmacy.hasCoordinates
        ? '${pharmacy.latitude},${pharmacy.longitude}'
        : '${pharmacy.name}, ${pharmacy.location}';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openMap(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication_outlined,
                      color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medicine.name, style: AppTextStyles.subheading),
                      if (medicine.genericName?.isNotEmpty == true)
                        Text(medicine.genericName!, style: AppTextStyles.body),
                    ],
                  ),
                ),
                StockStatusBadge(level: medicine.stockLevel),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pharmacy.location, style: AppTextStyles.label),
                      Text(pharmacy.name,
                          style: AppTextStyles.body, maxLines: 1),
                    ],
                  ),
                ),
                Text('${medicine.quantity} available',
                    style: AppTextStyles.label),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.accent),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMap(context),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View on map'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: medicine.quantity <= 0
                        ? null
                        : () => _openDirections(context),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Directions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  final VoidCallback onRetry;

  const _SearchError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry medicine search'),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.medication_outlined,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('No live inventory matches your search.',
              style: AppTextStyles.body),
        ],
      ),
    );
  }
}
