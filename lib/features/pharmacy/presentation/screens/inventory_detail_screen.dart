import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String medicineName;
  final String initialExpiry;
  final String initialBatch;
  final String initialSupplier;
  final int initialQuantity;

  const InventoryDetailScreen({
    super.key,
    required this.medicineName,
    required this.initialExpiry,
    this.initialBatch = 'AMX-2026-X',
    this.initialSupplier = 'Standard Wholesales Ltd',
    this.initialQuantity = 250,
  });

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _batchCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _batchCtrl.text = widget.initialBatch;
    _supplierCtrl.text = widget.initialSupplier;
    _qtyCtrl.text = widget.initialQuantity.toString();
  }

  @override
  void dispose() {
    _batchCtrl.dispose();
    _supplierCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved successfully!')),
    );
    context.pop();
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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/pharmacy/inventory');
              }
            }),
        title: Text(widget.medicineName, style: AppTextStyles.subheading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inventory Item Details', style: AppTextStyles.heading),
            const SizedBox(height: 6),
            Text('Expires on ${widget.initialExpiry}',
                style: AppTextStyles.body),
            const SizedBox(height: 24),
            const _FieldLabel('Batch Number'),
            _AppTextField(controller: _batchCtrl, hint: 'Batch Number'),
            const _FieldLabel('Supplier'),
            _AppTextField(controller: _supplierCtrl, hint: 'Supplier'),
            const _FieldLabel('Quantity in Stock'),
            _AppTextField(controller: _qtyCtrl, hint: 'Quantity'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
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

  const _AppTextField({required this.controller, required this.hint});

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
        ),
      ),
    );
  }
}
