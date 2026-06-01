import '../../models/family/family_export.dart';

class SplitCalculator {
  static List<ExpenseShare> equalSplit({
    required double totalAmount,
    required List<FamilyMember> members,
  }) {
    if (members.isEmpty || totalAmount <= 0) return [];
    final each = totalAmount / members.length;
    final cents = (each * 100).round();
    final base = cents / 100.0;
    return members
        .map((m) => ExpenseShare(memberId: m.id, amount: base))
        .toList();
  }

  static List<ExpenseShare> exactSplit({
    required double totalAmount,
    required Map<String, double> amounts,
  }) {
    final sum = amounts.values.fold<double>(0, (s, v) => s + v);
    if ((sum - totalAmount).abs() > 0.01) {
      throw ArgumentError(
        'Toplam (${sum.toStringAsFixed(2)}) harcama tutarına eşit olmalı',
      );
    }
    return amounts.entries
        .map(
          (e) => ExpenseShare(
            memberId: e.key,
            amount: e.value,
          ),
        )
        .toList();
  }

  static List<ExpenseShare> percentageSplit({
    required double totalAmount,
    required Map<String, double> percentages,
  }) {
    final sumPct =
        percentages.values.fold<double>(0, (s, v) => s + v);
    if ((sumPct - 100).abs() > 0.01) {
      throw ArgumentError('Yüzdelerin toplamı %100 olmalı');
    }
    return percentages.entries.map((e) {
      final amount = totalAmount * (e.value / 100.0);
      return ExpenseShare(
        memberId: e.key,
        amount: _round2(amount),
        percentage: e.value,
      );
    }).toList();
  }

  static List<ExpenseShare> sharesSplit({
    required double totalAmount,
    required Map<String, double> shareUnits,
  }) {
    final totalShares = shareUnits.values.fold<double>(0, (s, v) => s + v);
    if (totalShares <= 0) {
      throw ArgumentError('Pay toplamı sıfırdan büyük olmalı');
    }
    return shareUnits.entries.map((e) {
      final amount = totalAmount * (e.value / totalShares);
      return ExpenseShare(
        memberId: e.key,
        amount: _round2(amount),
        percentage: (e.value / totalShares) * 100.0,
      );
    }).toList();
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100.0;
}
