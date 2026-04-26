import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:parion/core/design/app_colors.dart';
import 'package:parion/models/savings_rate_trend_data.dart';
import 'package:parion/widgets/statistics/savings_rate_trend_chart.dart';

// Helper to wrap widget in a testable MaterialApp
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 400,
        child: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  group('SavingsRateTrendChart', () {
    // --- Requirement 5.3: positive rate uses AppColors.success ---
    testWidgets('uses AppColors.success color for positive savings rate',
        (WidgetTester tester) async {
      final data = [
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 1, 1),
          income: 10000,
          expense: 6000, // savingsRate = 40%
        ),
      ];

      await tester.pumpWidget(_wrap(SavingsRateTrendChart(trendData: data)));
      await tester.pump();

      // The widget should render without errors
      expect(find.byType(SavingsRateTrendChart), findsOneWidget);

      // Verify the chart title is shown
      expect(find.text('Tasarruf Oranı Trendi'), findsOneWidget);

      // Verify the average badge shows a positive trend icon
      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      // Verify AppColors.success is referenced in the widget tree by checking
      // that the badge color is success-based (positive average)
      final badgeIcon = tester.widget<Icon>(find.byIcon(Icons.trending_up));
      expect(badgeIcon.color, equals(AppColors.success));
    });

    // --- Requirement 5.3: negative rate uses AppColors.error ---
    testWidgets('uses AppColors.error color for negative savings rate',
        (WidgetTester tester) async {
      final data = [
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 1, 1),
          income: 5000,
          expense: 8000, // savingsRate = -60%
        ),
      ];

      await tester.pumpWidget(_wrap(SavingsRateTrendChart(trendData: data)));
      await tester.pump();

      expect(find.byType(SavingsRateTrendChart), findsOneWidget);
      expect(find.text('Tasarruf Oranı Trendi'), findsOneWidget);

      // Negative average → trending_down icon with error color
      expect(find.byIcon(Icons.trending_down), findsOneWidget);

      final badgeIcon = tester.widget<Icon>(find.byIcon(Icons.trending_down));
      expect(badgeIcon.color, equals(AppColors.error));
    });

    // --- Requirement 5.6: income = 0 shows "Veri Yok" label ---
    testWidgets('shows "Veri Yok" label for month with income = 0',
        (WidgetTester tester) async {
      final data = [
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 3, 1), // March
          income: 0,
          expense: 0,
        ),
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 4, 1),
          income: 8000,
          expense: 5000,
        ),
      ];

      await tester.pumpWidget(_wrap(SavingsRateTrendChart(trendData: data)));
      await tester.pump();

      // "Veri Yok" chip should appear for the zero-income month
      expect(find.textContaining('Veri Yok'), findsOneWidget);
    });

    testWidgets('shows empty state when trendData is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          _wrap(const SavingsRateTrendChart(trendData: [])));
      await tester.pump();

      expect(find.text('Veri yok'), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('renders chart with mixed positive and negative rates',
        (WidgetTester tester) async {
      final data = List.generate(6, (i) {
        final income = i.isEven ? 10000.0 : 5000.0;
        final expense = i.isEven ? 6000.0 : 7000.0;
        return SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, i + 1, 1),
          income: income,
          expense: expense,
        );
      });

      await tester.pumpWidget(_wrap(SavingsRateTrendChart(trendData: data)));
      await tester.pump();

      expect(find.byType(SavingsRateTrendChart), findsOneWidget);
      expect(find.text('Tasarruf Oranı Trendi'), findsOneWidget);
    });

    testWidgets('includes Semantics widget for screen reader accessibility',
        (WidgetTester tester) async {
      final data = [
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 1, 1),
          income: 10000,
          expense: 7000,
        ),
      ];

      await tester.pumpWidget(_wrap(SavingsRateTrendChart(trendData: data)));
      await tester.pump();

      // Semantics widget should be present
      expect(find.byType(Semantics), findsWidgets);

      // The outermost Semantics should have a non-empty label
      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasLabel = semanticsWidgets.any(
        (s) => s.properties.label != null && s.properties.label!.isNotEmpty,
      );
      expect(hasLabel, isTrue);
    });

    testWidgets('shows "Veri Yok" for multiple zero-income months',
        (WidgetTester tester) async {
      final data = [
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 1, 1),
          income: 0,
          expense: 0,
        ),
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 2, 1),
          income: 0,
          expense: 500,
        ),
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 3, 1),
          income: 9000,
          expense: 5000,
        ),
      ];

      await tester.pumpWidget(_wrap(SavingsRateTrendChart(trendData: data)));
      await tester.pump();

      // Two "Veri Yok" chips should appear
      expect(find.textContaining('Veri Yok'), findsNWidgets(2));
    });

    testWidgets('displays average rate in header badge',
        (WidgetTester tester) async {
      final data = [
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 1, 1),
          income: 10000,
          expense: 5000, // 50%
        ),
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 2, 1),
          income: 10000,
          expense: 7000, // 30%
        ),
      ];

      await tester.pumpWidget(_wrap(SavingsRateTrendChart(trendData: data)));
      await tester.pump();

      // Average = (50 + 30) / 2 = 40%
      expect(find.textContaining('Ort. 40.0%'), findsOneWidget);
    });

    testWidgets('uses provided averageRate override',
        (WidgetTester tester) async {
      final data = [
        SavingsRateTrendData.fromMonthlyData(
          month: DateTime(2024, 1, 1),
          income: 10000,
          expense: 5000,
        ),
      ];

      await tester.pumpWidget(
        _wrap(SavingsRateTrendChart(trendData: data, averageRate: 25.0)),
      );
      await tester.pump();

      expect(find.textContaining('Ort. 25.0%'), findsOneWidget);
    });
  });
}
