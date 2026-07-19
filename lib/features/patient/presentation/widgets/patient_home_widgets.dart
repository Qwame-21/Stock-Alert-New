import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/graded_photo.dart';

class PatientHomeImages {
  PatientHomeImages._();

  static const heroPharmacist = 'assets/images/patient_home_hero.png';
  static const medicineShelves = 'assets/images/patient_home_find_medicine.png';
  static const doctorTablet =
      'assets/images/patient_home_book_consultation.png';
  static const pharmacyStorefront =
      'assets/images/patient_home_nearby_pharmacy.png';
  static const rewards = 'assets/images/patient_home_rewards.png';
  static const doctorPortrait = 'assets/images/patient_home_reminder.png';
}

class HealthcareAssetImage extends StatelessWidget {
  const HealthcareAssetImage({
    super.key,
    required this.imageUrl,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String imageUrl;
  final String semanticLabel;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return GradedPhoto.asset(
      imageUrl,
      semanticLabel: semanticLabel,
      fit: fit,
      alignment: alignment,
    );
  }
}

class HeroBannerImage extends StatelessWidget {
  const HeroBannerImage({
    super.key,
    required this.imageUrl,
    required this.semanticLabel,
    this.alignment = Alignment.center,
  });

  final String imageUrl;
  final String semanticLabel;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => HealthcareAssetImage(
        imageUrl: imageUrl,
        semanticLabel: semanticLabel,
        alignment: alignment,
      );
}

class PharmacyImageCard extends StatelessWidget {
  const PharmacyImageCard({
    super.key,
    required this.imageUrl,
    required this.semanticLabel,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final String semanticLabel;
  final Alignment alignment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => HealthcareAssetImage(
        imageUrl: imageUrl,
        semanticLabel: semanticLabel,
        alignment: alignment,
        fit: fit,
      );
}

class DoctorPortraitCard extends StatelessWidget {
  const DoctorPortraitCard({super.key});

  @override
  Widget build(BuildContext context) => const HealthcareAssetImage(
        imageUrl: PatientHomeImages.doctorPortrait,
        semanticLabel: 'Doctor holding a tablet',
        alignment: Alignment.topCenter,
      );
}

class HeroBannerItem {
  const HeroBannerItem({
    required this.headline,
    required this.supportingText,
    required this.buttonLabel,
    required this.imageUrl,
    required this.imageLabel,
    required this.onPressed,
    this.imageAlignment = Alignment.center,
  });

  final String headline;
  final String supportingText;
  final String buttonLabel;
  final String imageUrl;
  final String imageLabel;
  final VoidCallback onPressed;
  final Alignment imageAlignment;
}

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.items});

  final List<HeroBannerItem> items;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  static const _interval = Duration(seconds: 7);
  final _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) => _advance());
  }

  void _advance() {
    if (!mounted || !_controller.hasClients || widget.items.length < 2) return;
    final next = (_currentPage + 1) % widget.items.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: 'Healthcare highlights carousel',
      child: Column(
        children: [
          SizedBox(
            height: 188,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) => HeroBanner(item: widget.items[index]),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? AppColors.accent
                      : AppColors.hairline,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.item});

  final HeroBannerItem item;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B4038),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: MediaQuery.sizeOf(context).width * .27,
            right: 0,
            top: 0,
            bottom: 0,
            child: HeroBannerImage(
              imageUrl: item.imageUrl,
              semanticLabel: item.imageLabel,
              alignment: item.imageAlignment,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
            child: FractionallySizedBox(
              widthFactor: .43,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.headline,
                    maxLines: textScaler.scale(1) > 1.25 ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.supportingText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 11.5,
                      color: const Color(0xFF4F5856),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: item.onPressed,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(104, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(item.buttonLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientIdentityCard extends StatelessWidget {
  const PatientIdentityCard({
    super.key,
    required this.patientName,
    required this.patientIdLabel,
    required this.qrToken,
    required this.onTap,
  });

  final String patientName;
  final String patientIdLabel;
  final String qrToken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Verified patient identity card for $patientName',
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x180B4038),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified,
                              size: 18, color: AppColors.statusGood),
                          const SizedBox(width: 7),
                          Text(
                            'Verified Patient',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.statusGood,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(patientName, style: AppTextStyles.subheading),
                      const SizedBox(height: 3),
                      Text('ID: $patientIdLabel', style: AppTextStyles.body),
                    ],
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: QrImageView(data: qrToken, size: 84),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuickActionData {
  const QuickActionData({
    required this.icon,
    required this.label,
    required this.imageUrl,
    required this.imageLabel,
    required this.onTap,
    this.imageAlignment = Alignment.center,
    this.imageFit = BoxFit.cover,
  });

  final IconData icon;
  final String label;
  final String imageUrl;
  final String imageLabel;
  final VoidCallback onTap;
  final Alignment imageAlignment;
  final BoxFit imageFit;
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.actions});

  final List<QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (_, index) => QuickActionTile(action: actions[index]),
    );
  }
}

class QuickActionTile extends StatefulWidget {
  const QuickActionTile({super.key, required this.action});

  final QuickActionData action;

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.action.label,
      child: AnimatedScale(
        scale: _pressed ? .975 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _pressed
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x0D0B4038),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.action.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: .56,
                        heightFactor: 1,
                        child: PharmacyImageCard(
                          imageUrl: widget.action.imageUrl,
                          semanticLabel: widget.action.imageLabel,
                          alignment: widget.action.imageAlignment,
                          fit: widget.action.imageFit,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              widget.action.icon,
                              color: AppColors.accent,
                              size: 27,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 108,
                          child: Text(
                            widget.action.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subheading.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 128),
            child: Row(
              children: [
                const SizedBox(
                  width: 132,
                  height: 128,
                  child: DoctorPortraitCard(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subheading.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 5),
                        Text(subtitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              height: 1.35,
                            )),
                      ],
                    ),
                  ),
                ),
                trailing ??
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.chevron_right),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
