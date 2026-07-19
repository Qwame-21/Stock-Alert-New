import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/liquid_glass_card.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/models/identity_tag_model.dart';
import '../controllers/identity_tag_cubit.dart';

class IdentityTagScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const IdentityTagScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Identity Tag', style: AppTextStyles.subheading),
      ),
      body: BlocBuilder<IdentityTagCubit, IdentityTagState>(
        builder: (context, state) {
          if (state is IdentityTagLoading) {
            return const SkeletonList(itemCount: 3);
          }
          if (state is IdentityTagError) {
            return Center(
              child: Text(state.message, style: AppTextStyles.body),
            );
          }
          if (state is IdentityTagLoaded) {
            return _IdentityCardView(
              tag: state.tag,
              patientName: patientName,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _IdentityCardView extends StatelessWidget {
  final IdentityTagModel tag;
  final String patientName;

  const _IdentityCardView({required this.tag, required this.patientName});

  String get _statusLabel {
    switch (tag.verificationStatus) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Verification pending';
      case VerificationStatus.rejected:
        return 'Verification needed';
    }
  }

  Color get _statusColor {
    switch (tag.verificationStatus) {
      case VerificationStatus.verified:
        return AppColors.statusGood;
      case VerificationStatus.pending:
        return AppColors.statusWarning;
      case VerificationStatus.rejected:
        return AppColors.statusBad;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LiquidGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(patientName, style: AppTextStyles.heading),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style:
                            AppTextStyles.label.copyWith(color: _statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: QrImageView(
                    // this is the opaque token, never raw patient data -
                    // see IdentityTagModel for why that matters
                    data: tag.qrToken,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Member since ${tag.memberSince.year}',
                    style: AppTextStyles.body),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: platform wallet integration (Apple/Google Wallet)
              },
              icon: const Icon(Icons.credit_card_outlined, size: 18),
              label: const Text('Add to Wallet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.hairline),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
