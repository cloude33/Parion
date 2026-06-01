import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../models/cash_flow_data.dart';
import 'data_service.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final DataService _dataService = DataService();
  static const _storageKey = 'budgets';

  Future<List<Budget>> getBudgets({int? year, int? month}) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey) ?? '[]';
    final list = (jsonDecode(json) as List).map((e) => Budget.fromJson(e)).toList();

    if (year != null && month != null) {
      return list.where((b) => b.year == year && b.month == month).toList();
    }
    return list;
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(budgets.map((b) => b.toJson()).toList()));
  }

  Future<void> setBudget(Budget budget) async {
    final all = await getBudgets();
    final idx = all.indexWhere((b) => b.category == budget.category && b.year == budget.year && b.month == budget.month);
    if (idx != -1) {
      all[idx] = budget;
    } else {
      all.add(budget);
    }
    await saveBudgets(all);
  }

  Future<void> deleteBudget(String id) async {
    final all = await getBudgets();
    all.removeWhere((b) => b.id == id);
    await saveBudgets(all);
  }

  Future<Map<String, BudgetComparison>> getComparisons(int year, int month) async {
    final budgets = await getBudgets(year: year, month: month);
    final transactions = await _dataService.getTransactions();
    final comparisons = <String, BudgetComparison>{};

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final monthExpenses = transactions.where((t) =>
      t.type == 'expense' &&
      !t.date.isBefore(start) &&
      t.date.isBefore(end)
    ).toList();

    for (final budget in budgets) {
      final actual = monthExpenses
          .where((t) => t.category == budget.category)
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      final remaining = budget.amount - actual;
      final usage = budget.amount > 0 ? (actual / budget.amount) * 100 : 0.0;

      comparisons[budget.category] = BudgetComparison(
        category: budget.category,
        budget: budget.amount,
        actual: actual,
        remaining: remaining,
        usagePercentage: usage,
        exceeded: actual > budget.amount,
      );
    }

    return comparisons;
  }

  Future<double> getTotalBudget(int year, int month) async {
    final budgets = await getBudgets(year: year, month: month);
    return budgets.fold<double>(0.0, (sum, b) => sum + b.amount);
  }

  Future<double> getTotalSpent(int year, int month) async {
    final comparisons = await getComparisons(year, month);
    return comparisons.values.fold<double>(0.0, (sum, c) => sum + c.actual);
  }
}
