import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RewardActivity {
  final String title;
  final String date;
  final int points;
  final bool isEarned;

  const RewardActivity(this.title, this.date, this.points, this.isEarned);
}

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const activities = [
      RewardActivity('Returned Amoxicillin (Expired)', '12 July 2026', 150, true),
      RewardActivity('Refilled Vitamin C Prescription', '10 July 2026', 50, true),
      RewardActivity('Redeemed Doctor Consultation', '05 July 2026', 200, false),
      RewardActivity('Returned Paracetamol', '01 July 2026', 80, true),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Rewards & Points', style: AppTextStyles.subheading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFF438A7E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Available Points Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '480 pts',
                    style: AppTextStyles.heading.copyWith(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Equivalent to GHS 48.00 in value',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Return Status Tracker
            Text('Medicine Returns Tracker', style: AppTextStyles.subheading),
            SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Return Ref: RET-902-A', style: AppTextStyles.subheading),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusWarning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Under Review',
                          style: AppTextStyles.label.copyWith(color: AppColors.statusWarning),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Item: Ibuprofen 400mg (10 caps)', style: AppTextStyles.body),
                  SizedBox(height: 20),
                  // Progress step indicator
                  Row(
                    children: [
                      _buildStep(label: 'Submitted', active: true, completed: true),
                      _buildLine(completed: true),
                      _buildStep(label: 'Reviewing', active: true, completed: false),
                      _buildLine(completed: false),
                      _buildStep(label: 'Resolved', active: false, completed: false),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Activity History
            Text('Points Activity', style: AppTextStyles.subheading),
            SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                final act = activities[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.hairline),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(act.title, style: AppTextStyles.subheading),
                            Text(act.date, style: AppTextStyles.body),
                          ],
                        ),
                      ),
                      Text(
                        '${act.isEarned ? "+" : "-"}${act.points} pts',
                        style: AppTextStyles.subheading.copyWith(
                          color: act.isEarned ? AppColors.statusGood : AppColors.statusBad,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required String label, required bool active, required bool completed}) {
    Color color = AppColors.hairline;
    IconData icon = Icons.circle_outlined;
    if (completed) {
      color = AppColors.statusGood;
      icon = Icons.check_circle;
    } else if (active) {
      color = AppColors.accent;
      icon = Icons.play_circle_outline;
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(color: color, fontSize: 10)),
      ],
    );
  }

  Widget _buildLine({required bool completed}) {
    return Expanded(
      child: Container(
        height: 2,
        color: completed ? AppColors.statusGood : AppColors.hairline,
      ),
    );
  }
}
