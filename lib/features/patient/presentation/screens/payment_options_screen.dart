import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/payments_repository.dart';

class PaymentOptionsScreen extends StatefulWidget {
  const PaymentOptionsScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '1.00');
  bool _isStartingPayment = false;
  String _method = 'mobile_money';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_isStartingPayment || !_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isStartingPayment = true);
    try {
      final amount = double.parse(_amountController.text.trim());
      final checkout = await PaymentsRepository().startCheckout(
        amountMinor: (amount * 100).round(),
      );
      await PaymentsRepository().openCheckout(checkout.authorizationUrl);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isStartingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: const Color(0xFFE9EEEC),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('StockAlert balance', style: AppTextStyles.body),
                    Text('GH₵0.00',
                        style: AppTextStyles.heading.copyWith(fontSize: 30)),
                    const Divider(height: 24),
                    Text(
                        'Your amount is calculated dynamically below and paid securely through Paystack.',
                        style: AppTextStyles.body),
                  ]),
            ),
            const SizedBox(height: 20),
            Text('Payment methods', style: AppTextStyles.subheading),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _method,
              onChanged: (value) {
                if (value != null) setState(() => _method = value);
              },
              child: Card(
                  child: Column(children: [
                RadioListTile<String>(
                  value: 'mobile_money',
                  secondary: const Icon(Icons.phone_android_outlined),
                  title: const Text('Mobile money'),
                  subtitle: Text(widget.phoneNumber.trim().isEmpty
                      ? 'Add a phone number in your profile'
                      : widget.phoneNumber),
                ),
                const Divider(height: 1),
                const RadioListTile<String>(
                  value: 'card',
                  secondary: Icon(Icons.credit_card_outlined),
                  title: Text('Debit or credit card'),
                  subtitle:
                      Text('Card details are entered in secure checkout.'),
                ),
              ])),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _amountController,
                onChanged: (_) => setState(() {}),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'GHS ',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null) return 'Enter a valid amount';
                  if (amount < 1) return 'The minimum payment is GHS 1.00';
                  if (amount > 100000) {
                    return 'Enter an amount below GHS 100,000';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isStartingPayment ? null : _pay,
              icon: _isStartingPayment
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(_isStartingPayment
                  ? 'Opening secure checkout…'
                  : 'Pay GHS ${_amountController.text.trim()} securely'),
            ),
          ],
        ),
      ),
    );
  }
}
