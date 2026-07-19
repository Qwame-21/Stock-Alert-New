class RewardTransaction {
  const RewardTransaction({
    required this.id,
    required this.title,
    required this.points,
    required this.status,
    required this.sourceType,
    required this.occurredAt,
    this.description,
    this.sourceReference,
  });

  final String id;
  final String title;
  final String? description;
  final int points;
  final String status;
  final String sourceType;
  final String? sourceReference;
  final DateTime occurredAt;

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      points: (json['points'] as num).toInt(),
      status: json['status'] as String,
      sourceType: json['source_type'] as String,
      sourceReference: json['source_reference'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
    );
  }
}

class RewardSummary {
  const RewardSummary({
    required this.balance,
    required this.pending,
    required this.activity,
  });

  final int balance;
  final List<RewardTransaction> pending;
  final List<RewardTransaction> activity;

  factory RewardSummary.fromJson(Map<String, dynamic> json) {
    List<RewardTransaction> parseList(String key) => (json[key] as List? ?? [])
        .map((item) =>
            RewardTransaction.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return RewardSummary(
      balance: (json['balance'] as num? ?? 0).toInt(),
      pending: parseList('pending'),
      activity: parseList('activity'),
    );
  }
}
