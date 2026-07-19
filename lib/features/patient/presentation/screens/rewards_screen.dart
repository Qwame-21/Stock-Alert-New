import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/models/reward_summary.dart';
import '../../data/rewards_repository.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _repository = RewardsRepository();
  late Future<RewardSummary> _rewards = _repository.load();

  Future<void> _refresh() async {
    final next = _repository.load();
    setState(() => _rewards = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFBFB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Rewards', style: AppTextStyles.subheading),
      ),
      body: FutureBuilder<RewardSummary>(
        future: _rewards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList(itemCount: 4);
          }
          if (snapshot.hasError) {
            return _RewardsError(onRetry: _refresh);
          }
          return _RewardsContent(
            summary: snapshot.data ??
                const RewardSummary(balance: 0, pending: [], activity: []),
            onRefresh: _refresh,
          );
        },
      ),
    );
  }
}

class _RewardsContent extends StatelessWidget {
  const _RewardsContent({required this.summary, required this.onRefresh});

  final RewardSummary summary;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _BalanceCard(balance: summary.balance),
          if (summary.pending.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _SectionHeading(
              title: 'In review',
              subtitle: 'Points appear in your balance after verification.',
            ),
            const SizedBox(height: 12),
            ...summary.pending.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RewardActivityTile(item: item, pending: true),
              ),
            ),
          ],
          const SizedBox(height: 28),
          const _SectionHeading(
            title: 'Points activity',
            subtitle: 'A secure history of earned and redeemed points.',
          ),
          const SizedBox(height: 12),
          if (summary.activity.isEmpty)
            const _EmptyRewards()
          else
            ...summary.activity.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RewardActivityTile(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$balance available reward points',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x251B5349),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Available points',
                  style: TextStyle(
                    color: Color(0xFFDCEBE8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '$balance pts',
              style: AppTextStyles.heading.copyWith(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Points are updated from verified StockAlert activity.',
              style: TextStyle(
                color: Color(0xFFDCEBE8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                AppTextStyles.subheading.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 12)),
      ],
    );
  }
}

class _RewardActivityTile extends StatelessWidget {
  const _RewardActivityTile({required this.item, this.pending = false});

  final RewardTransaction item;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final positive = item.points > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  pending ? const Color(0xFFFFF7E6) : const Color(0xFFE8F3F0),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              pending
                  ? Icons.hourglass_top_rounded
                  : positive
                      ? Icons.add_circle_outline_rounded
                      : Icons.redeem_outlined,
              color: pending ? AppColors.statusWarning : AppColors.accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subheading.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  pending
                      ? 'Verification in progress'
                      : _formatDate(item.occurredAt),
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${positive ? '+' : ''}${item.points} pts',
            style: AppTextStyles.label.copyWith(
              color: pending
                  ? AppColors.statusWarning
                  : positive
                      ? AppColors.statusGood
                      : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _EmptyRewards extends StatelessWidget {
  const _EmptyRewards();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F3F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_outlined, color: AppColors.accent),
          ),
          const SizedBox(height: 14),
          Text('No rewards activity yet', style: AppTextStyles.subheading),
          const SizedBox(height: 5),
          Text(
            'Verified reward activity will appear here automatically.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _RewardsError extends StatelessWidget {
  const _RewardsError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppColors.textSecondary, size: 38),
            const SizedBox(height: 14),
            Text('Rewards are unavailable', style: AppTextStyles.subheading),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
