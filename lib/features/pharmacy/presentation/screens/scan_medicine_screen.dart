import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ScanMedicineScreen extends StatefulWidget {
  const ScanMedicineScreen({super.key});

  @override
  State<ScanMedicineScreen> createState() => _ScanMedicineScreenState();
}

class _ScanMedicineScreenState extends State<ScanMedicineScreen> {
  bool _isScanned = false;

  final _medNameCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();

  @override
  void dispose() {
    _medNameCtrl.dispose();
    _supplierCtrl.dispose();
    _batchCtrl.dispose();
    _expiryCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  void _simulateScan() {
    setState(() {
      _isScanned = true;
      _medNameCtrl.text = 'Amoxicillin 500mg';
      _supplierCtrl.text = 'Standard Wholesales Ltd';
      _batchCtrl.text = 'AMX-2026-09';
      _expiryCtrl.text = '2026-10-15';
      _quantityCtrl.text = '100';
    });
  }

  void _saveToInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicine saved to inventory successfully!')),
    );
    setState(() {
      _isScanned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Scan Medicine', style: AppTextStyles.subheading),
      ),
      body: _isScanned ? _buildConfirmationForm() : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Align barcode within the viewfinder',
            style: AppTextStyles.subheading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Viewfinder simulation
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.05),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 80, color: AppColors.accent),
                  // Floating red laser line simulator
                  Positioned(
                    top: 150,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 2,
                      color: AppColors.statusBad,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _simulateScan,
              icon: const Icon(Icons.flash_on),
              label: const Text('Simulate Successful Scan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm Scanned Medicine', style: AppTextStyles.heading),
          const SizedBox(height: 6),
          Text('Pre-filled from barcode metadata. Verify before saving.', style: AppTextStyles.body),
          const SizedBox(height: 24),

          const _FieldLabel('Medicine Name'),
          _AppTextField(controller: _medNameCtrl, hint: 'Medicine Name'),

          const _FieldLabel('Supplier'),
          _AppTextField(controller: _supplierCtrl, hint: 'Supplier'),

          const _FieldLabel('Batch Number'),
          _AppTextField(controller: _batchCtrl, hint: 'Batch Number'),

          const _FieldLabel('Expiry Date'),
          _AppTextField(controller: _expiryCtrl, hint: 'YYYY-MM-DD', icon: Icons.calendar_today),

          const _FieldLabel('Quantity'),
          _AppTextField(controller: _quantityCtrl, hint: '100'),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isScanned = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.hairline),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Rescan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveToInventory,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(text, style: AppTextStyles.label),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;

  const _AppTextField({required this.controller, required this.hint, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.subheading,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body,
          border: InputBorder.none,
          suffixIcon: icon != null ? Icon(icon, size: 18) : null,
        ),
      ),
    );
  }
}
