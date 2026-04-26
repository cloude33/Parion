// Feature: statistics-redesign, Property 4: bill payment rate color coding consistency
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:parion/core/design/app_colors.dart';
import 'package:parion/models/bill_history_summary.dart';
import 'package:parion/models/bill_template.dart';
import 'package:parion/widgets/statistics/bill_history_summary_card.dart';
import 'package:parion/widgets/statistics/statistics_empty_state.dart';
import '../../property_test_utils.dart';

// Helper to wrap widget in a testable MaterialApp
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

BillHistorySummary _makeSummary({
  double paymentRate = 100,
  int paid = 12,
  int total = 12,
  DateTime? lastPaidDate,
  DateTime? nextDueDate,
}) {
  return BillHistorySummary(
    templateId: 'test-id',
    templateName: 'Elektrik',
    category: BillTemplateCategory.electricity,
    totalPayments: total,
    paidPayments: paid,
    paymentRate: paymentRate,
    lastPaidDate: lastPaidDate,
    nextDueDate: nextDueDate,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  // -------------------------------------------------------------------------
  // Property 4: Fatura Ödeme Oranı Renk Kodlaması Tutarlılığı
  // Validates: Requirements 9.3
  // -------------------------------------------------------------------------
  group('Property 4: colorForRate color coding consistency', () {
    PropertyTest.forAll<double>(
      description:
          'rate >= 100 always returns AppColors.success',
      generator: () => PropertyTest.randomDouble(min: 100, max: 300),
      property: (rate) {
        final color = BillHistorySummaryCard.colorForRate(rate);
        return color == AppColors.success;
      },
      iterations: 100,
    );

    PropertyTest.forAll<double>(
      description:
          '50 <= rate < 100 always returns AppColors.warning',
      generator: () => PropertyTest.randomDouble(min: 50, max: 99.9999),
      property: (rate) {
        final color = BillHistorySummaryCard.colorForRate(rate);
        return color == AppColors.warning;
      },
      iterations: 100,
    );

    PropertyTest.forAll<double>(
      description:
          'rate < 50 always returns AppColors.error',
      generator: () => PropertyTest.randomDouble(min: -100, max: 49.9999),
      property: (rate) {
        final color = BillHistorySummaryCard.colorForRate(rate);
        return color == AppColors.error;
      },
      iterations: 100,
    );

    // Boundary values
    test('boundary: rate == 100 returns AppColors.success', () {
      expect(BillHistorySummaryCard.colorForRate(100), AppColors.success);
    });

    test('boundary: rate == 50 returns AppColors.warning', () {
      expect(BillHistorySummaryCard.colorForRate(50), AppColors.warning);
    });

    test('boundary: rate == 49.9 returns AppColors.error', () {
      expect(BillHistorySummaryCard.colorForRate(49.9), AppColors.error);
    });

    test('boundary: rate == 0 returns AppColors.error', () {
      expect(BillHistorySummaryCard.colorForRate(0), AppColors.error);
    });
  });

  // -------------------------------------------------------------------------
  // Task 7.3: Widget tests
  // Validates: Requirements 9.3, 9.5
  // -------------------------------------------------------------------------
  group('BillHistorySummaryCard widget tests', () {
    // --- Empty state (Requirement 9.5) ---
    testWidgets('shows empty state when summaries list is empty',
        (WidgetTester tester) async {
      bool addBillCalled = false;

      await tester.pumpWidget(
        _wrap(
          BillHistorySummaryCard(
            summaries: const [],
            onAddBill: () => addBillCalled = true,
          ),
        ),
      );
      await tester.pump();

      // StatisticsEmptyState should be shown
      expect(find.byType(StatisticsEmptyState), findsOneWidget);
      expect(find.text('Fatura Şablonu Yok'), findsOneWidget);

      // Action button should be present and tappable
      expect(find.text('Fatura Ekle'), findsOneWidget);
      await tester.tap(find.text('Fatura Ekle'));
      expect(addBillCalled, isTrue);
    });

    testWidgets('shows empty state without action button when onAddBill is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const BillHistorySummaryCard(summaries: []),
        ),
      );
      await tester.pump();

      expect(find.byType(StatisticsEmptyState), findsOneWidget);
      expect(find.text('Fatura Ekle'), findsNothing);
    });

    // --- Filled state: success color (rate >= 100) (Requirement 9.3) ---
    testWidgets('shows check_circle icon for rate >= 100 (success)',
        (WidgetTester tester) async {
      final summary = _makeSummary(paymentRate: 100, paid: 12, total: 12);

      await tester.pumpWidget(
        _wrap(BillHistorySummaryCard(summaries: [summary])),
      );
      await tester.pump();

      // check_circle icon should be present with success color
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, equals(AppColors.success));
    });

    // --- Filled state: warning color (50 <= rate < 100) (Requirement 9.3) ---
    testWidgets('shows warning icon for 50 <= rate < 100 (warning)',
        (WidgetTester tester) async {
      final summary = _makeSummary(paymentRate: 75, paid: 9, total: 12);

      await tester.pumpWidget(
        _wrap(BillHistorySummaryCard(summaries: [summary])),
      );
      await tester.pump();

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.warning_amber_rounded),
      );
      expect(icon.color, equals(AppColors.warning));
    });

    // --- Filled state: error color (rate < 50) (Requirement 9.3) ---
    testWidgets('shows cancel icon for rate < 50 (error)',
        (WidgetTester tester) async {
      final summary = _makeSummary(paymentRate: 25, paid: 3, total: 12);

      await tester.pumpWidget(
        _wrap(BillHistorySummaryCard(summaries: [summary])),
      );
      await tester.pump();

      final icon = tester.widget<Icon>(find.byIcon(Icons.cancel));
      expect(icon.color, equals(AppColors.error));
    });

    // --- All three color categories in one widget ---
    testWidgets('renders all three color categories correctly',
        (WidgetTester tester) async {
      final summaries = [
        _makeSummary(
          paymentRate: 100,
          paid: 12,
          total: 12,
        )..toString(), // success
        _makeSummary(
          paymentRate: 75,
          paid: 9,
          total: 12,
        )..toString(), // warning
        _makeSummary(
          paymentRate: 25,
          paid: 3,
          total: 12,
        )..toString(), // error
      ];

      // Build with three distinct summaries
      final successSummary =
          _makeSummary(paymentRate: 100, paid: 12, total: 12);
      final warningSummary =
          _makeSummary(paymentRate: 75, paid: 9, total: 12);
      final errorSummary =
          _makeSummary(paymentRate: 25, paid: 3, total: 12);

      await tester.pumpWidget(
        _wrap(
          BillHistorySummaryCard(
            summaries: [successSummary, warningSummary, errorSummary],
          ),
        ),
      );
      await tester.pump();

      // All three icons should be present
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);

      // Verify colors
      final successIcon =
          tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(successIcon.color, equals(AppColors.success));

      final warningIcon =
          tester.widget<Icon>(find.byIcon(Icons.warning_amber_rounded));
      expect(warningIcon.color, equals(AppColors.warning));

      final errorIcon = tester.widget<Icon>(find.byIcon(Icons.cancel));
      expect(errorIcon.color, equals(AppColors.error));
    });

    // --- Dates are displayed (Requirement 9.4) ---
    testWidgets('shows last paid date and next due date when provided',
        (WidgetTester tester) async {
      final summary = _makeSummary(
        paymentRate: 100,
        paid: 1,
        total: 1,
        lastPaidDate: DateTime(2024, 5, 15),
        nextDueDate: DateTime(2024, 6, 15),
      );

      await tester.pumpWidget(
        _wrap(BillHistorySummaryCard(summaries: [summary])),
      );
      await tester.pump();

      expect(find.text('15.05.2024'), findsOneWidget);
      expect(find.text('15.06.2024'), findsOneWidget);
    });

    testWidgets('shows dash when dates are null', (WidgetTester tester) async {
      final summary = _makeSummary(
        paymentRate: 100,
        paid: 0,
        total: 0,
        lastPaidDate: null,
        nextDueDate: null,
      );

      await tester.pumpWidget(
        _wrap(BillHistorySummaryCard(summaries: [summary])),
      );
      await tester.pump();

      // Two dashes — one for each null date
      expect(find.text('—'), findsNWidgets(2));
    });

    // --- Payment rate percentage is shown ---
    testWidgets('shows payment rate percentage', (WidgetTester tester) async {
      final summary = _makeSummary(paymentRate: 75, paid: 9, total: 12);

      await tester.pumpWidget(
        _wrap(BillHistorySummaryCard(summaries: [summary])),
      );
      await tester.pump();

      expect(find.text('%75'), findsOneWidget);
      expect(find.text('9/12'), findsOneWidget);
    });

    // --- Card header is shown ---
    testWidgets('shows card header title', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          BillHistorySummaryCard(
            summaries: [_makeSummary()],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Fatura Ödeme Geçmişi'), findsOneWidget);
    });

    // --- Semantics for accessibility (Requirement 19.3) ---
    testWidgets('includes Semantics for screen reader accessibility',
        (WidgetTester tester) async {
      final summary = _makeSummary(paymentRate: 100, paid: 12, total: 12);

      await tester.pumpWidget(
        _wrap(BillHistorySummaryCard(summaries: [summary])),
      );
      await tester.pump();

      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
