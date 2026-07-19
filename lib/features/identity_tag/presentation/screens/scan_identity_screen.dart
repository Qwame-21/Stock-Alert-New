import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/identity_card_repository.dart';

class ScanIdentityScreen extends StatefulWidget {
  const ScanIdentityScreen({super.key});

  @override
  State<ScanIdentityScreen> createState() => _ScanIdentityScreenState();
}

class _ScanIdentityScreenState extends State<ScanIdentityScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _resolving = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null || _resolving) return;
    setState(() => _resolving = true);
    await _controller.stop();
    try {
      final identity = await IdentityCardRepository().resolve(token);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verified patient identity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: identity.entries
                .where((entry) => entry.value != null)
                .map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('${_label(entry.key)}: ${entry.value}'),
                    ))
                .toList(),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _resolving = false);
        await _controller.start();
      }
    }
  }

  String _label(String key) => switch (key) {
        'patientId' => 'Patient ID',
        'fullName' => 'Full name',
        'dateOfBirth' => 'Date of birth',
        'emergencyContactName' => 'Emergency contact',
        'emergencyContactPhone' => 'Emergency phone',
        _ => key,
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan patient identity')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Ask the patient for permission, then align their StockAlert QR inside the frame.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(controller: _controller, onDetect: _onDetect),
                    IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.all(52),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 3),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                    if (_resolving)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
