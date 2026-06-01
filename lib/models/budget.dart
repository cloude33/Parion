class Budget {
  final String id;
  final String category;
  final double amount;
  final int year;
  final int month;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.year,
    required this.month,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'year': year,
    'month': month,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'],
    category: json['category'],
    amount: (json['amount'] as num).toDouble(),
    year: json['year'],
    month: json['month'],
  );

  Budget copyWith({String? id, String? category, double? amount, int? year, int? month}) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}
