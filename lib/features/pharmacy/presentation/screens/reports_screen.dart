import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Pharmacy Reports', style: AppTextStyles.subheading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Key Performance Indicators', style: AppTextStyles.subheading),
            const SizedBox(height: 12),
            _buildKpiCard(
              title: 'Stock Turnover Rate',
              value: '4.8x / year',
              description: 'Typical target is 4.0x. Excellent shelf freshness.',
              icon: Icons.loop_outlined,
            ),
            const SizedBox(height: 12),
            _buildKpiCard(
              title: 'Order Fulfillment Rate',
              value: '97.2%',
              description: '45 of 47 purchase orders delivered complete.',
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            _buildKpiCard(
              title: 'Average Expiry Age',
              value: '14.2 months',
              description: 'Average remaining shelf life of batch storage.',
              icon: Icons.timer_outlined,
            ),
            const SizedBox(height: 24),

            Text('Simulated Expiry Trends', style: AppTextStyles.subheading),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batches expiring per month', style: AppTextStyles.label),
                  const SizedBox(height: 20),
                  // Custom bar chart using rows & containers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar('Jul', 30, true),
                      _buildBar('Aug', 50, true),
                      _buildBar('Sep', 20, false),
                      _buildBar('Oct', 90, false),
                      _buildBar('Nov', 40, false),
                      _buildBar('Dec', 10, false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withOpacity(0.08),
            radius: 20,
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.heading.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.body.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double heightPercent, bool urgent) {
    return Column(
      children: [
        Container(
          width: 24,
          height: heightPercent,
          decoration: BoxDecoration(
            color: urgent ? AppColors.statusWarning : AppColors.accent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
      ],
    );
  }
}
