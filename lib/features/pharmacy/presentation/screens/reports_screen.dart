import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../inventory/presentation/controllers/inventory_cubit.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/pharmacy/dashboard')),
          title: Text('Pharmacy Reports', style: AppTextStyles.subheading)),
      body: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
        final items = state.medicines;
        final units = items.fold<int>(0, (s, m) => s + m.quantity);
        final value = items.fold<double>(
            0, (s, m) => s + (m.unitPrice ?? 0) * m.quantity);
        final low = items.where((m) => m.quantity <= m.reorderLevel).length;
        final expired = items.where((m) => m.isExpired).length;
        final soon = items.where((m) => m.isExpiringSoon).length;
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text('Live inventory overview', style: AppTextStyles.heading),
          const SizedBox(height: 16),
          GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _Metric('Stock units', '$units', Icons.inventory_2_outlined),
                _Metric('Inventory value', 'GHS ${value.toStringAsFixed(2)}',
                    Icons.payments_outlined),
                _Metric('Low / out of stock', '$low', Icons.trending_down),
                _Metric('Expired batches', '$expired', Icons.dangerous_outlined)
              ]),
          const SizedBox(height: 24),
          Text('Expiry outlook', style: AppTextStyles.subheading),
          const SizedBox(height: 10),
          _Summary(
              label: 'Expired', value: expired, color: AppColors.statusBad),
          _Summary(
              label: 'Due within 90 days',
              value: soon,
              color: AppColors.statusWarning),
          _Summary(
              label: 'Healthy shelf life',
              value: items.length - expired - soon,
              color: AppColors.statusGood)
        ]);
      }));
}

class _Metric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Metric(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.accent),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child:
              Text(value, style: AppTextStyles.heading.copyWith(fontSize: 19)),
        ),
        Text(label,
            style: AppTextStyles.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis)
      ]));
}

class _Summary extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Summary(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(13)),
      child: Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.body)),
        Text('$value batches', style: AppTextStyles.subheading)
      ]));
}
