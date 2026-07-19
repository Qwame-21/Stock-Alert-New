import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/liquid_glass_card.dart';
import '../controllers/registration_cubit.dart';

class RegistrationStepFourScreen extends StatefulWidget {
  const RegistrationStepFourScreen({super.key});

  @override
  State<RegistrationStepFourScreen> createState() =>
      _RegistrationStepFourScreenState();
}

class _RegistrationStepFourScreenState
    extends State<RegistrationStepFourScreen> {
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  // Card details
  String _cardNumber = '';
  String _cardExpiry = '';
  bool _hasCardLinked = false;

  Future<void> _pickProfileImage() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile Photo', style: AppTextStyles.heading),
            const SizedBox(height: 4),
            Text('Choose how to add your profile picture.',
                style: AppTextStyles.body),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.accent),
              ),
              title: Text('Take a Photo', style: AppTextStyles.subheading),
              subtitle: Text('Open camera', style: AppTextStyles.body),
              onTap: () async {
                Navigator.pop(ctx);
                await _captureFromSource(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.accent),
              ),
              title:
                  Text('Choose from Gallery', style: AppTextStyles.subheading),
              subtitle:
                  Text('Pick an existing photo', style: AppTextStyles.body),
              onTap: () async {
                Navigator.pop(ctx);
                await _captureFromSource(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
            backgroundColor: AppColors.statusBad,
          ),
        );
      }
    }
  }

  void _showCardInputDialog() {
    final cardNoCtrl = TextEditingController(text: _cardNumber);
    final expiryCtrl = TextEditingController(text: _cardExpiry);
    final cvvCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Link Payment Card', style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text('Enter your card details to link to your patient wallet.',
                  style: AppTextStyles.body),
              const SizedBox(height: 20),
              TextField(
                controller: cardNoCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.subheading,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '4000 1234 5678 9010',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryCtrl,
                      keyboardType: TextInputType.datetime,
                      style: AppTextStyles.subheading,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvvCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      style: AppTextStyles.subheading,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.characters,
                style: AppTextStyles.subheading,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'ROLAND ADAMS',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (cardNoCtrl.text.isEmpty ||
                        expiryCtrl.text.isEmpty ||
                        cvvCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill out all fields'),
                            backgroundColor: AppColors.statusBad),
                      );
                      return;
                    }
                    setState(() {
                      _cardNumber = cardNoCtrl.text;
                      _cardExpiry = expiryCtrl.text;
                      _hasCardLinked = true;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment Card linked successfully!'),
                        backgroundColor: AppColors.statusGood,
                      ),
                    );
                  },
                  child: const Text('Link Card'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPayoutInputDialog() {
    final number = TextEditingController();
    String network = 'MTN Mobile Money';
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
              builder: (context, setSheetState) => Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receive pharmacy payments',
                          style: AppTextStyles.heading),
                      Text(
                          'Add the mobile money account where settled customer payments should be received.',
                          style: AppTextStyles.body),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                          initialValue: network,
                          decoration: const InputDecoration(
                              labelText: 'Mobile money network'),
                          items: const [
                            DropdownMenuItem(
                                value: 'MTN Mobile Money',
                                child: Text('MTN Mobile Money')),
                            DropdownMenuItem(
                                value: 'Telecel Cash',
                                child: Text('Telecel Cash')),
                            DropdownMenuItem(
                                value: 'AirtelTigo Money',
                                child: Text('AirtelTigo Money')),
                          ],
                          onChanged: (v) => setSheetState(() => network = v!)),
                      const SizedBox(height: 12),
                      TextField(
                          controller: number,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              labelText: 'Registered account number')),
                      const SizedBox(height: 20),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: () {
                                if (number.text
                                        .replaceAll(RegExp(r'\D'), '')
                                        .length <
                                    9) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Enter a valid mobile money number.')));
                                  return;
                                }
                                setState(() {
                                  _hasCardLinked = true;
                                  _cardNumber = number.text.trim();
                                  _cardExpiry = network;
                                });
                                Navigator.pop(sheetContext);
                              },
                              child: const Text('Save payout account'))),
                    ]),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) {
        final isPatient = state.role == 'patient';
        final displayName = isPatient ? state.fullName : state.pharmacyName;
        final idPrefix = isPatient ? 'PAT' : 'PHA';
        final randomId = '$idPrefix-7X9A-2B4C';
        final qrToken = 'stockalert-$randomId-token';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              tooltip: isPatient
                  ? 'Back to health information'
                  : 'Back to pharmacy verification',
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  // Pharmacy onboarding intentionally skips patient-only step 3.
                  context.go(isPatient ? '/register/3' : '/register/2');
                }
              },
            ),
            title: Text('4 of 4', style: AppTextStyles.label),
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Identity Tag', style: AppTextStyles.heading),
                    const SizedBox(height: 6),
                    Text(
                      'Show this card to verify your identity at any pharmacy.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 24),
                    // Frosted glass card
                    SizedBox(
                      width: double.infinity,
                      child: LiquidGlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Verification badge
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Icon(Icons.verified,
                                    size: 16, color: AppColors.statusGood),
                                const SizedBox(width: 6),
                                Text(
                                  isPatient
                                      ? 'Verified Patient'
                                      : 'Verified Pharmacy',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.statusGood,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Picture Placeholder (for Safety & Validation)
                            if (isPatient) ...[
                              Center(
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: AppColors.hairline,
                                        backgroundImage:
                                            _profileImagePath != null
                                                ? FileImage(
                                                    File(_profileImagePath!))
                                                : null,
                                        child: _profileImagePath == null
                                            ? const Icon(
                                                Icons.camera_alt_outlined,
                                                size: 32,
                                                color: AppColors.textSecondary,
                                              )
                                            : null,
                                      ),
                                      if (_profileImagePath != null)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.accent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.refresh,
                                                size: 12, color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Name
                            Center(
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName
                                    : 'James Mensah',
                                style: AppTextStyles.heading,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // ID Label
                            Center(
                              child: Text(
                                isPatient ? 'Patient ID' : 'Pharmacy ID',
                                style: AppTextStyles.label,
                              ),
                            ),
                            Center(
                              child: Text(
                                randomId,
                                style: AppTextStyles.subheading,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // QR Code
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: QrImageView(
                                  data: qrToken,
                                  size: 160,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 16,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 14, color: AppColors.statusGood),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: AppTextStyles.label.copyWith(
                                          color: AppColors.statusGood),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Member Since\nJuly 2026',
                                  style: AppTextStyles.label,
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Add to Wallet button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isPatient
                            ? _showCardInputDialog
                            : _showPayoutInputDialog,
                        icon: Icon(
                            _hasCardLinked
                                ? Icons.credit_card
                                : Icons.credit_card_outlined,
                            size: 18),
                        label: Text(_hasCardLinked
                            ? (isPatient
                                ? 'Payment Card Linked'
                                : 'Payout Account Added')
                            : (isPatient
                                ? 'Add to Wallet'
                                : 'Add Mobile Money Payout')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _hasCardLinked
                              ? AppColors.statusGood
                              : AppColors.textPrimary,
                          side: BorderSide(
                              color: _hasCardLinked
                                  ? AppColors.statusGood
                                  : AppColors.hairline),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Done button -> saves session & goes to home screen
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.submitStatus ==
                                RegistrationSubmitStatus.loading
                            ? null
                            : () async {
                                final cubit = context.read<RegistrationCubit>();
                                final success =
                                    await cubit.submitRegistrationToSupabase();

                                if (!context.mounted) return;

                                if (success) {
                                  // Check if we have a live session (email confirmation OFF)
                                  // or if the user needs to confirm their email first
                                  final session = Supabase
                                      .instance.client.auth.currentSession;
                                  if (session != null) {
                                    // Fully authenticated — go straight to the app
                                    if (isPatient) {
                                      context.go('/patient/home');
                                    } else {
                                      context.go('/pharmacy/dashboard');
                                    }
                                  } else {
                                    // Email confirmation required
                                    context.go('/login', extra: {
                                      'expiredMessage':
                                          'Account created! Check your email to confirm your address, then log in here.',
                                    });
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        cubit.state.submitError ??
                                            'Registration failed. Please try again.',
                                      ),
                                      backgroundColor: AppColors.statusBad,
                                    ),
                                  );
                                }
                              },
                        child: state.submitStatus ==
                                RegistrationSubmitStatus.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Done'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                )),
          ),
        );
      },
    );
  }
}
