import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../data/order_models.dart';
import '../../data/orders_repository.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final _repo = OrdersRepository();
  late final TabController _tabs;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<PurchaseOrder> _orders = [];
  List<Supplier> _suppliers = [];
  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading && _orders.isNotEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([_repo.orders(), _repo.suppliers()]);
      if (!mounted) return;
      setState(() {
        _orders = values[0] as List<PurchaseOrder>;
        _suppliers = values[1] as List<Supplier>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to dashboard',
            onPressed: () => context.go('/pharmacy/dashboard'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text('Suppliers & Orders', style: AppTextStyles.subheading),
          bottom: TabBar(
              controller: _tabs,
              tabs: const [Tab(text: 'Orders'), Tab(text: 'Suppliers')]),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
          ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _busy
              ? null
              : () => _tabs.index == 0 ? _newOrder() : _newSupplier(),
          icon: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: Text(_busy
              ? 'Please wait…'
              : _tabs.index == 0
                  ? 'New order'
                  : 'New supplier')),
      body: _loading
          ? const SkeletonList(itemCount: 6)
          : _error != null
              ? _ErrorView(message: _error!, retry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [_orderList(), _supplierList()]));
  Widget _orderList() => _orders.isEmpty
      ? const _Empty(
          icon: Icons.receipt_long_outlined, text: 'No purchase orders yet.')
      : ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _OrderCard(
              order: _orders[i],
              onStatus: (s) =>
                  _runAction(() => _repo.updateStatus(_orders[i].id, s)),
              onReceive: () => _receive(_orders[i])));
  Widget _supplierList() => _suppliers.isEmpty
      ? const _Empty(
          icon: Icons.local_shipping_outlined, text: 'Add your first supplier.')
      : ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _suppliers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final s = _suppliers[i];
            return _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: AppTextStyles.subheading),
              if (s.contactPerson.isNotEmpty)
                Text(s.contactPerson, style: AppTextStyles.body),
              Text([s.phone, s.email].where((e) => e.isNotEmpty).join(' • '),
                  style: AppTextStyles.body),
              if (s.leadTimeDays > 0)
                Text('${s.leadTimeDays}-day lead time',
                    style: AppTextStyles.label)
            ]));
          });
  Widget _card(Widget child) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(14)),
      child: child);
  Future<void> _newSupplier() async {
    final name = TextEditingController(),
        phone = TextEditingController(),
        email = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('New supplier'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(labelText: 'Supplier name')),
                  TextField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: 'Phone')),
                  TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Save'))
                ]));
    if (ok == true && name.text.trim().isNotEmpty) {
      await _runAction(() async {
        await _repo.addSupplier(
            name: name.text.trim(),
            phone: phone.text.trim(),
            email: email.text.trim());
      });
    }
  }

  Future<void> _newOrder() async {
    if (_suppliers.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add a supplier first.')));
      return;
    }
    Supplier selected = _suppliers.first;
    final medicine = TextEditingController(),
        qty = TextEditingController(text: '1'),
        cost = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, setLocal) => AlertDialog(
                    title: const Text('New purchase order'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      DropdownButtonFormField<Supplier>(
                          initialValue: selected,
                          items: _suppliers
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.name)))
                              .toList(),
                          onChanged: (s) {
                            if (s != null) setLocal(() => selected = s);
                          },
                          decoration:
                              const InputDecoration(labelText: 'Supplier')),
                      TextField(
                          controller: medicine,
                          decoration:
                              const InputDecoration(labelText: 'Medicine')),
                      TextField(
                          controller: qty,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Quantity')),
                      TextField(
                          controller: cost,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Unit cost (GHS)'))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Create draft'))
                    ])));
    if (ok == true && medicine.text.trim().isNotEmpty) {
      await _runAction(() => _repo.createOrder(
            supplierId: selected.id,
            items: [
              {
                'medicineName': medicine.text.trim(),
                'quantity': int.tryParse(qty.text) ?? 1,
                'unitCost': double.tryParse(cost.text)
              }
            ],
          ));
    }
  }

  Future<void> _receive(PurchaseOrder order) async {
    final available = order.items.where((i) => i.outstanding > 0).toList();
    if (available.isEmpty) return;
    final item = available.first,
        qty = TextEditingController(text: '${item.outstanding}'),
        batch = TextEditingController(),
        expiry = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text('Receive ${item.medicineName}'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Outstanding: ${item.outstanding}',
                      style: AppTextStyles.body),
                  TextField(
                      controller: qty,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Quantity received')),
                  TextField(
                      controller: batch,
                      decoration: const InputDecoration(
                          labelText: 'Batch / lot number')),
                  TextField(
                      controller: expiry,
                      decoration: const InputDecoration(
                          labelText: 'Expiry (YYYY-MM-DD)'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Receive stock'))
                ]));
    if (ok == true && batch.text.trim().isNotEmpty) {
      await _runAction(() => _repo.receive(order.id, [
            {
              'orderItemId': item.id,
              'quantity': int.tryParse(qty.text) ?? 0,
              'batchNumber': batch.text.trim(),
              'expiryDate':
                  expiry.text.trim().isEmpty ? null : expiry.text.trim()
            }
          ]));
    }
  }
}

class _OrderCard extends StatelessWidget {
  final PurchaseOrder order;
  final ValueChanged<String> onStatus;
  final VoidCallback onReceive;
  const _OrderCard(
      {required this.order, required this.onStatus, required this.onReceive});
  @override
  Widget build(BuildContext context) {
    final canReceive =
        ['submitted', 'confirmed', 'partially_received'].contains(order.status);
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(order.number, style: AppTextStyles.subheading)),
            _Status(order.status)
          ]),
          Text(order.supplierName, style: AppTextStyles.body),
          const Divider(),
          ...order.items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                  '${i.medicineName}: ${i.received}/${i.ordered} received',
                  style: AppTextStyles.body))),
          Text('Total: ${order.currency} ${order.total.toStringAsFixed(2)}',
              style: AppTextStyles.label),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Community pharmacy order timeline',
                    style: AppTextStyles.label),
                const SizedBox(height: 6),
                if (order.timeline.isEmpty)
                  Text('Created ${_stamp(order.createdAt.toLocal())}',
                      style: AppTextStyles.body.copyWith(fontSize: 12))
                else
                  for (final event in order.timeline)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(_purposeLabel(event.status),
                                style:
                                    AppTextStyles.body.copyWith(fontSize: 12)),
                          ),
                          Text(_stamp(event.createdAt),
                              style: AppTextStyles.label.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            if (order.status == 'draft')
              ActionChip(
                  label: const Text('Submit'),
                  onPressed: () => onStatus('submitted')),
            if (order.status == 'submitted')
              ActionChip(
                  label: const Text('Confirm'),
                  onPressed: () => onStatus('confirmed')),
            if (canReceive)
              ActionChip(
                  avatar: const Icon(Icons.inventory_2_outlined, size: 17),
                  label: const Text('Receive'),
                  onPressed: onReceive),
            if (['draft', 'submitted', 'confirmed'].contains(order.status))
              ActionChip(
                  label: const Text('Cancel'),
                  onPressed: () => onStatus('cancelled'))
          ])
        ]));
  }

  String _purposeLabel(String status) => switch (status) {
        'draft' => 'Order prepared for review',
        'submitted' => 'Sent to supplier',
        'confirmed' => 'Supplier confirmed',
        'partially_received' => 'Stock partially received',
        'received' => 'Stock received and added to inventory',
        'cancelled' => 'Order cancelled',
        _ => status.replaceAll('_', ' '),
      };

  String _stamp(DateTime value) =>
      '${value.day}/${value.month} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _Status extends StatelessWidget {
  final String value;
  const _Status(this.value);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(value.replaceAll('_', ' '),
          style: AppTextStyles.label
              .copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)));
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 52, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(text, style: AppTextStyles.body)
      ]));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _ErrorView({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: retry, child: const Text('Try again'))
          ])));
}
