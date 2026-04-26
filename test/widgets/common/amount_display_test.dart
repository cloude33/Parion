// Feature: app-design-overhaul, Property 1: AmountDisplay renk tutarlılığı

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide test, group, expect, setUp, tearDown, setUpAll, tearDownAll;
import 'package:parion/core/design/app_colors.dart';
import 'package:parion/widgets/common/amount_display.dart';

/// Renders [AmountDisplay] and returns the [TextStyle] of the inner [Text].
Future<TextStyle?> _getStyle(
  WidgetTester tester, {
  required double amount,
  required bool isIncome,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AmountDisplay(amount: amount, isIncome: isIncome),
      ),
    ),
  );
  final textWidget = tester.widget<Text>(find.byType(Text));
  return textWidget.style;
}

void main() {
  // ---------------------------------------------------------------------------
  // Unit tests – specific cases
  // ---------------------------------------------------------------------------
  group('AmountDisplay – unit tests', () {
    testWidgets('income: uses AppColors.incomeColor', (tester) async {
      final style = await _getStyle(tester, amount: 1500.0, isIncome: true);
      expect(style?.color, equals(AppColors.incomeColor));
    });

    testWidgets('expense: uses AppColors.expenseColor', (tester) async {
      final style = await _getStyle(tester, amount: 200.0, isIncome: false);
      expect(style?.color, equals(AppColors.expenseColor));
    });

    testWidgets('zero amount with isIncome=true uses incomeColor', (
      tester,
    ) async {
      final style = await _getStyle(tester, amount: 0.0, isIncome: true);
      expect(style?.color, equals(AppColors.incomeColor));
    });

    testWidgets('zero amount with isIncome=false uses expenseColor', (
      tester,
    ) async {
      final style = await _getStyle(tester, amount: 0.0, isIncome: false);
      expect(style?.color, equals(AppColors.expenseColor));
    });

    testWidgets('negative amount with isIncome=true still uses incomeColor', (
      tester,
    ) async {
      final style = await _getStyle(tester, amount: -500.0, isIncome: true);
      expect(style?.color, equals(AppColors.incomeColor));
    });

    testWidgets('large amount with isIncome=false uses expenseColor', (
      tester,
    ) async {
      final style = await _getStyle(
        tester,
        amount: 999999.99,
        isIncome: false,
      );
      expect(style?.color, equals(AppColors.expenseColor));
    });
  });

  // ---------------------------------------------------------------------------
  // Property-based test – Validates: Requirement 3.5
  //
  // **Validates: Requirements 3.5**
  //
  // For any finite double amount and any bool isIncome, AmountDisplay must
  // apply AppColors.incomeColor when isIncome == true and
  // AppColors.expenseColor when isIncome == false.
  // Runs 100 iterations using glados-generated values.
  // ---------------------------------------------------------------------------
  group('AmountDisplay – property tests', () {
    testWidgets(
      'Property 1: color token matches isIncome flag for any amount and bool '
      '(100 iterations)',
      (tester) async {
        // Use glados generators to produce values; drive the loop manually
        // inside a single testWidgets so we have access to [tester].
        final random = Random(42);
        final doubleGen = any.double;
        final boolGen = any.bool;

        int iterations = 0;
        int tested = 0;

        while (tested < 100) {
          iterations++;
          // Increase size gradually as glados does internally.
          final size = (iterations / 2).ceil().clamp(1, 200);

          final amount = doubleGen(random, size).value;
          final isIncome = boolGen(random, size).value;

          // Skip non-finite values (NaN, Infinity) – not valid monetary amounts.
          if (!amount.isFinite) continue;

          final expectedColor =
              isIncome ? AppColors.incomeColor : AppColors.expenseColor;

          final style = await _getStyle(
            tester,
            amount: amount,
            isIncome: isIncome,
          );

          expect(
            style?.color,
            equals(expectedColor),
            reason:
                'amount=$amount, isIncome=$isIncome → expected $expectedColor',
          );

          tested++;
        }
      },
    );
  });
}
