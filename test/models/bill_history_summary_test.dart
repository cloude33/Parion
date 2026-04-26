import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/bill_history_summary.dart';
import '../property_test_utils.dart';

/// **Feature: statistics-redesign**
/// **Validates: Requirements 9.2**
///
/// Property-based tests for [BillHistorySummary.calculatePaymentRate].
void main() {
  group('BillHistorySummary.calculatePaymentRate Property Tests', () {
    // Feature: statistics-redesign, Property 3: bill payment rate calculation correctness
    PropertyTest.forAll<Map<String, int>>(
      description:
          'Property 3: paid >= 0, total > 0 için (paid / total) * 100 döner',
      generator: () {
        final total = PropertyTest.randomInt(min: 1, max: 1000);
        final paid = PropertyTest.randomInt(min: 0, max: total);
        return {'paid': paid, 'total': total};
      },
      property: (data) {
        final paid = data['paid']!;
        final total = data['total']!;

        final rate = BillHistorySummary.calculatePaymentRate(paid, total);

        // Must equal (paid / total) * 100
        final expected = (paid / total) * 100;
        expect(rate, closeTo(expected, 1e-9));

        return true;
      },
      iterations: 100,
    );

    // Edge case: total = 0 → 0.0
    test('total = 0 ise 0.0 döner', () {
      expect(BillHistorySummary.calculatePaymentRate(0, 0), equals(0.0));
      expect(BillHistorySummary.calculatePaymentRate(5, 0), equals(0.0));
    });

    // Edge case: paid = 0 → 0.0
    test('paid = 0 ise 0.0 döner', () {
      expect(BillHistorySummary.calculatePaymentRate(0, 10), closeTo(0.0, 1e-9));
      expect(BillHistorySummary.calculatePaymentRate(0, 1), closeTo(0.0, 1e-9));
    });

    // Edge case: paid = total → 100.0
    test('paid = total ise 100.0 döner', () {
      expect(
        BillHistorySummary.calculatePaymentRate(10, 10),
        closeTo(100.0, 1e-9),
      );
      expect(
        BillHistorySummary.calculatePaymentRate(1, 1),
        closeTo(100.0, 1e-9),
      );
    });

    // Edge case: negative total → 0.0 (guard)
    test('total < 0 ise 0.0 döner', () {
      expect(BillHistorySummary.calculatePaymentRate(5, -1), equals(0.0));
    });
  });
}
