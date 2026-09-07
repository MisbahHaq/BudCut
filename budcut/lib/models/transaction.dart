class AppTransaction {
  final String id;
  final num amount;
  final DateTime date;
  final String categoryId;
  final String merchant;
  final String notes;
  final List<String> tags;
  final bool isRecurring;

  const AppTransaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.merchant,
    required this.notes,
    required this.tags,
    this.isRecurring = false,
  });

  AppTransaction copyWith({
    String? id,
    num? amount,
    DateTime? date,
    String? categoryId,
    String? merchant,
    String? notes,
    List<String>? tags,
    bool? isRecurring,
  }) {
    return AppTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      merchant: merchant ?? this.merchant,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'merchant': merchant,
      'notes': notes,
      'tags': tags,
      'isRecurring': isRecurring,
    };
  }

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      id: json['id'] as String,
      amount: (json['amount'] as num),
      date: DateTime.parse(json['date'] as String),
      categoryId: json['categoryId'] as String,
      merchant: (json['merchant'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      isRecurring: (json['isRecurring'] as bool?) ?? false,
    );
  }
}
