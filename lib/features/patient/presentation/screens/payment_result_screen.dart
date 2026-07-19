import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/payments_repository.dart';

class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({super.key, required this.reference});

  final String reference;

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  PaymentStatus? _payment;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_verify());
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      PaymentStatus? result;
      for (var attempt = 0; attempt < 8; attempt++) {
        result = await PaymentsRepository().getStatus(widget.reference);
        if (result.status != 'pending') break;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (!mounted) return;
      setState(() {
        _payment = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final success = _payment?.isSuccess ?? false;
    final pending = _payment?.status == 'pending';
    return Scaffold(
      appBar: AppBar(title: const Text('Payment status')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Confirming your payment securely…'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        success
                            ? Icons.check_circle_outline
                            : pending
                                ? Icons.schedule_outlined
                                : Icons.error_outline,
                        size: 72,
                        color: success
                            ? AppColors.statusGood
                            : pending
                                ? AppColors.statusWarning
                                : Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error != null
                            ? 'Could not verify payment'
                            : success
                                ? 'Payment confirmed'
                                : pending
                                    ? 'Payment is still processing'
                                    : 'Payment was not completed',
                        style: AppTextStyles.heading,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ??
                            (pending
                                ? 'The signed Paystack webhook has not arrived yet. You can safely check again.'
                                : 'Reference: ${widget.reference}'),
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_error != null || pending)
                        OutlinedButton.icon(
                          onPressed: _verify,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Check again'),
                        ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => context.go('/patient/profile'),
                        child: const Text('Return to profile'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
