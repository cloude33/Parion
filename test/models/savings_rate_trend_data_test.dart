import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/savings_rate_trend_data.dart';
import '../property_test_utils.dart';

/// **Feature: statistics-redesign**
/// **Validates: Requirements 3.2, 5.2, 5.6**
///
/// Property-based tests for [SavingsRateTrendData.calculateRate].
void main() {
  group('SavingsRateTrendData.calculateRate Property Tests', () {
    // Feature: statistics-redesign, Property 1: savings rate calculation correctness
    PropertyTest.forAll<Map<String, double>>(
      description:
          'Property 1: income > 0 için (income - expense) / income * 100 döner',
      generator: () {
        return {
          'income': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000000.0),
          'expense': PropertyTest.randomDouble(min: -500000.0, max: 1000000.0),
        };
      },
      property: (data) {
        final income = data['income']!;
        final expense = data['expense']!;

        final rate = SavingsRateTrendData.calculateRate(income, expense);

        // Must not be null when income > 0
        expect(rate, isNotNull);

        // Must equal (income - expense) / income * 100
        final expected = (income - expense) / income * 100;
        expect(rate, closeTo(expected, 1e-9));

        return true;
      },
      iterations: 100,
    );

    // Feature: statistics-redesign, Property 2: zero income returns null
    PropertyTest.forAll<double>(
      description: 'Property 2: income = 0 için null döner',
      generator: () {
        return PropertyTest.randomDouble(min: -500000.0, max: 500000.0);
      },
      property: (expense) {
        final rate = SavingsRateTrendData.calculateRate(0, expense);

        // Must be null when income = 0
        expect(rate, isNull);

        return true;
      },
      iterations: 100,
    );

    // Edge case: negative income also returns null (income <= 0 guard)
    test('income < 0 için null döner', () {
      expect(SavingsRateTrendData.calculateRate(-100, 50), isNull);
      expect(SavingsRateTrendData.calculateRate(-0.01, 0), isNull);
    });

    // Edge case: expense equals income → rate = 0
    test('expense == income ise tasarruf oranı 0 döner', () {
      final rate = SavingsRateTrendData.calculateRate(1000, 1000);
      expect(rate, closeTo(0.0, 1e-9));
    });

    // Edge case: expense = 0 → rate = 100
    test('expense = 0 ise tasarruf oranı 100 döner', () {
      final rate = SavingsRateTrendData.calculateRate(1000, 0);
      expect(rate, closeTo(100.0, 1e-9));
    });

    // Edge case: expense > income → negative rate
    test('expense > income ise tasarruf oranı negatif döner', () {
      final rate = SavingsRateTrendData.calculateRate(1000, 1500);
      expect(rate, closeTo(-50.0, 1e-9));
    });
  });
}
