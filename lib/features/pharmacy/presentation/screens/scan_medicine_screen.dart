import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stock_status_badge.dart';
import '../../../inventory/data/models/inventory_medicine.dart';
import '../../../inventory/presentation/controllers/inventory_cubit.dart';

class ScanMedicineScreen extends StatefulWidget {
  const ScanMedicineScreen({super.key});

  @override
  State<ScanMedicineScreen> createState() => _ScanMedicineScreenState();
}

class _ScanMedicineScreenState extends State<ScanMedicineScreen> {
  final _scannerController = MobileScannerController(
    formats: const [
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.qrCode,
    ],
  );
  final _formKey = GlobalKey<FormState>();
  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _genericCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _reorderCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _showForm = false;
  bool _saving = false;
  bool _handledDetection = false;

  @override
  void dispose() {
    _scannerController.dispose();
    for (final controller in [
      _barcodeCtrl,
      _nameCtrl,
      _genericCtrl,
      _brandCtrl,
      _strengthCtrl,
      _dosageCtrl,
      _manufacturerCtrl,
      _batchCtrl,
      _expiryCtrl,
      _quantityCtrl,
      _reorderCtrl,
      _priceCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handledDetection || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue?.trim();
    if (value == null || value.isEmpty) return;
    _handledDetection = true;
    _scannerController.stop();
    setState(() {
      _barcodeCtrl.text = value;
      _showForm = true;
    });
  }

  void _openManualEntry() {
    _scannerController.stop();
    setState(() {
      _handledDetection = true;
      _showForm = true;
    });
  }

  void _rescan() {
    _formKey.currentState?.reset();
    for (final controller in [
      _barcodeCtrl,
      _nameCtrl,
      _genericCtrl,
      _brandCtrl,
      _strengthCtrl,
      _dosageCtrl,
      _manufacturerCtrl,
      _batchCtrl,
      _expiryCtrl,
      _quantityCtrl,
      _reorderCtrl,
      _priceCtrl,
    ]) {
      controller.clear();
    }
    setState(() {
      _handledDetection = false;
      _showForm = false;
    });
    _scannerController.start();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_expiryCtrl.text) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
    );
    if (selected != null) {
      _expiryCtrl.text = selected.toIso8601String().split('T').first;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final quantity = int.parse(_quantityCtrl.text.trim());
      final reorderLevel = int.tryParse(_reorderCtrl.text.trim()) ?? 0;
      final medicine = InventoryMedicine(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        expiry: _expiryCtrl.text.trim(),
        level: quantity <= 0
            ? StockLevel.outOfStock
            : quantity <= reorderLevel
                ? StockLevel.lowStock
                : StockLevel.inStock,
        quantity: quantity,
        barcode: _barcodeCtrl.text.trim(),
        batchNumber: _batchCtrl.text.trim(),
        genericName: _genericCtrl.text.trim(),
        brandName: _brandCtrl.text.trim(),
        strength: _strengthCtrl.text.trim(),
        dosageForm: _dosageCtrl.text.trim(),
        manufacturer: _manufacturerCtrl.text.trim(),
        reorderLevel: reorderLevel,
        unitPrice: _priceCtrl.text.trim().isEmpty
            ? null
            : double.parse(_priceCtrl.text.trim()),
      );
      await context.read<InventoryCubit>().addMedicine(medicine);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${medicine.name} added to inventory.')),
      );
      _rescan();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save medicine: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: _showForm ? 'Back to scanner' : 'Back to dashboard',
          icon: const Icon(Icons.arrow_back),
          onPressed:
              _showForm ? _rescan : () => context.go('/pharmacy/dashboard'),
        ),
        title: Text(_showForm ? 'Receive Stock' : 'Scan Medicine',
            style: AppTextStyles.subheading),
        actions: _showForm
            ? null
            : [
                IconButton(
                  tooltip: 'Toggle flash',
                  onPressed: _scannerController.toggleTorch,
                  icon: const Icon(Icons.flashlight_on_outlined),
                ),
              ],
      ),
      body: _showForm ? _buildForm() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Text('Align the product barcode inside the frame.',
              style: AppTextStyles.body, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => _ScannerError(
                      message: error.errorDetails?.message ??
                          'Camera access is unavailable.',
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.all(42),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openManualEntry,
              icon: const Icon(Icons.keyboard_outlined),
              label: const Text('Enter barcode or medicine manually'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Medicine details', style: AppTextStyles.heading),
          const SizedBox(height: 4),
          Text('Verify the product and batch details before saving.',
              style: AppTextStyles.body),
          const SizedBox(height: 20),
          _field(_barcodeCtrl, 'Barcode', required: false),
          _field(_nameCtrl, 'Medicine name'),
          _field(_genericCtrl, 'Generic name', required: false),
          _field(_brandCtrl, 'Brand name', required: false),
          Row(children: [
            Expanded(child: _field(_strengthCtrl, 'Strength', required: false)),
            const SizedBox(width: 12),
            Expanded(
                child: _field(_dosageCtrl, 'Dosage form', required: false)),
          ]),
          _field(_manufacturerCtrl, 'Manufacturer', required: false),
          const SizedBox(height: 8),
          Text('Batch details', style: AppTextStyles.subheading),
          const SizedBox(height: 12),
          _field(_batchCtrl, 'Batch / lot number'),
          TextFormField(
            controller: _expiryCtrl,
            readOnly: true,
            onTap: _pickExpiry,
            decoration:
                _decoration('Expiry date', Icons.calendar_today_outlined),
            validator: (value) => value == null || value.isEmpty
                ? 'Select the batch expiry date'
                : null,
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _field(_quantityCtrl, 'Quantity', number: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(_reorderCtrl, 'Reorder level',
                  number: true, required: false),
            ),
          ]),
          _field(_priceCtrl, 'Unit cost (GHS)', decimal: true, required: false),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _rescan,
                child: const Text('Rescan'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save stock'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool number = false,
    bool decimal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? TextInputType.number
            : decimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        decoration: _decoration(label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return '$label is required';
          if (number && text.isNotEmpty && (int.tryParse(text) ?? -1) < 0) {
            return 'Enter 0 or more';
          }
          if (decimal &&
              text.isNotEmpty &&
              ((double.tryParse(text) ?? -1) < 0)) {
            return 'Enter a valid cost';
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _decoration(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.body,
      suffixIcon: icon == null ? null : Icon(icon, size: 19),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  final String message;
  const _ScannerError({required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
