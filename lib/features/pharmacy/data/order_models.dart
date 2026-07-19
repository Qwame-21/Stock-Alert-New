class Supplier {
  final String id, name, phone, email, contactPerson, paymentTerms;
  final int leadTimeDays;
  const Supplier(
      {required this.id,
      required this.name,
      this.phone = '',
      this.email = '',
      this.contactPerson = '',
      this.paymentTerms = '',
      this.leadTimeDays = 0});
  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
      id: j['id'] as String,
      name: j['name'] as String,
      phone: j['phone'] as String? ?? '',
      email: j['email'] as String? ?? '',
      contactPerson: j['contact_person'] as String? ?? '',
      paymentTerms: j['payment_terms'] as String? ?? '',
      leadTimeDays: j['lead_time_days'] as int? ?? 0);
}

class PurchaseOrderItem {
  final String id, medicineName, barcode;
  final int ordered, received;
  final double? unitCost;
  const PurchaseOrderItem(
      {required this.id,
      required this.medicineName,
      required this.ordered,
      this.received = 0,
      this.barcode = '',
      this.unitCost});
  int get outstanding => ordered - received;
  factory PurchaseOrderItem.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderItem(
          id: j['id'] as String,
          medicineName: j['medicine_name'] as String,
          ordered: j['quantity_ordered'] as int,
          received: j['quantity_received'] as int? ?? 0,
          barcode: j['barcode'] as String? ?? '',
          unitCost: (j['unit_cost'] as num?)?.toDouble());
}

class PurchaseOrder {
  final String id, number, supplierName, status, currency;
  final DateTime createdAt;
  final List<PurchaseOrderItem> items;
  final List<OrderStatusEvent> timeline;
  const PurchaseOrder(
      {required this.id,
      required this.number,
      required this.supplierName,
      required this.status,
      required this.createdAt,
      required this.items,
      this.timeline = const [],
      this.currency = 'GHS'});
  double get total =>
      items.fold(0, (sum, item) => sum + (item.unitCost ?? 0) * item.ordered);
  factory PurchaseOrder.fromJson(Map<String, dynamic> j) => PurchaseOrder(
      id: j['id'] as String,
      number: j['order_number'] as String,
      supplierName: (j['suppliers'] as Map?)?['name'] as String? ?? 'Supplier',
      status: j['status'] as String,
      createdAt: DateTime.parse(j['created_at'] as String),
      currency: j['currency'] as String? ?? 'GHS',
      items: (j['purchase_order_items'] as List? ?? [])
          .map((e) =>
              PurchaseOrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      timeline: (j['purchase_order_status_history'] as List? ?? [])
          .map((e) =>
              OrderStatusEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
}

class OrderStatusEvent {
  final String status;
  final String? note;
  final DateTime createdAt;
  const OrderStatusEvent({
    required this.status,
    required this.createdAt,
    this.note,
  });
  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      OrderStatusEvent(
        status: json['status'] as String,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}
