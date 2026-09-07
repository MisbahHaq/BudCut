enum BillFrequency { weekly, monthly, yearly }

extension BillFrequencyLabel on BillFrequency {
  String get label {
    switch (this) {
      case BillFrequency.weekly:
        return 'Weekly';
      case BillFrequency.monthly:
        return 'Monthly';
      case BillFrequency.yearly:
        return 'Yearly';
    }
  }
}

class RecurringBill {
  final String id;
  String name;
  num amount;
  BillFrequency frequency;
  int billingDay;
  String categoryId;
  bool isActive;

  RecurringBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.billingDay,
    required this.categoryId,
    this.isActive = true,
  });

  String get frequencyLabel {
    switch (frequency) {
      case BillFrequency.weekly:
        return 'Weekly';
      case BillFrequency.monthly:
        return 'Monthly';
      case BillFrequency.yearly:
        return 'Yearly';
    }
  }

  /// Monthly liability in PKR (converts weekly/yearly to monthly equivalent).
  num get monthlyLiability {
    switch (frequency) {
      case BillFrequency.weekly:
        return amount * 52 / 12;
      case BillFrequency.monthly:
        return amount;
      case BillFrequency.yearly:
        return amount / 12;
    }
  }

  RecurringBill copyWith({
    String? id,
    String? name,
    num? amount,
    BillFrequency? frequency,
    int? billingDay,
    String? categoryId,
    bool? isActive,
  }) {
    return RecurringBill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      billingDay: billingDay ?? this.billingDay,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'frequency': frequency.name,
      'billingDay': billingDay,
      'categoryId': categoryId,
      'isActive': isActive,
    };
  }

  factory RecurringBill.fromJson(Map<String, dynamic> json) {
    return RecurringBill(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num),
      frequency: BillFrequency.values.byName(json['frequency'] as String),
      billingDay: (json['billingDay'] as num).toInt(),
      categoryId: json['categoryId'] as String,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }
}
