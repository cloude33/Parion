class SavingsRateTrendData {
  final DateTime month;       // Ayın ilk günü
  final double income;        // Toplam gelir
  final double expense;       // Toplam gider
  final double? savingsRate;  // null ise gelir = 0 (Veri Yok)

  SavingsRateTrendData({
    required this.month,
    required this.income,
    required this.expense,
    this.savingsRate,
  });

  /// Tasarruf oranını hesaplar.
  /// Gelir > 0 ise: (gelir - gider) / gelir × 100
  /// Gelir ≤ 0 ise: null döner
  static double? calculateRate(double income, double expense) {
    if (income <= 0) return null;
    return (income - expense) / income * 100;
  }

  factory SavingsRateTrendData.fromMonthlyData({
    required DateTime month,
    required double income,
    required double expense,
  }) {
    return SavingsRateTrendData(
      month: month,
      income: income,
      expense: expense,
      savingsRate: calculateRate(income, expense),
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month.toIso8601String(),
    'income': income,
    'expense': expense,
    'savingsRate': savingsRate,
  };

  factory SavingsRateTrendData.fromJson(Map<String, dynamic> json) =>
      SavingsRateTrendData(
        month: DateTime.parse(json['month']),
        income: json['income'],
        expense: json['expense'],
        savingsRate: json['savingsRate'],
      );
}
