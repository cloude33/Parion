// Feature: app-design-overhaul, Property 6: Ekran durum yönetimi tutarlılığı

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart'
    hide test, group, expect, setUp, tearDown, setUpAll, tearDownAll;
import 'package:parion/widgets/common/app_empty_state.dart';
import 'package:parion/widgets/common/app_error_state.dart';
import 'package:parion/widgets/common/app_loading_state.dart';

// ---------------------------------------------------------------------------
// Test helper widget
// ---------------------------------------------------------------------------

enum ScreenState { loading, empty, error }

class _TestScreen extends StatelessWidget {
  const _TestScreen({required this.state});
  final ScreenState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ScreenState.loading => const AppLoadingState(),
      ScreenState.empty => const AppEmptyState(
          icon: Icons.inbox,
          title: 'Boş',
          description: 'Veri yok',
        ),
      ScreenState.error => const AppErrorState(message: 'Hata oluştu'),
    };
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps [_TestScreen] with the given [state] and returns the tester.
Future<void> _pumpScreen(WidgetTester tester, ScreenState state) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: _TestScreen(state: state)),
    ),
  );
  // Allow animations to settle (AppLoadingState uses AnimationController).
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Unit tests – one per state
  // -------------------------------------------------------------------------
  group('Screen state management – unit tests', () {
    testWidgets('loading state: AppLoadingState present, others absent',
        (tester) async {
      await _pumpScreen(tester, ScreenState.loading);

      expect(find.byType(AppLoadingState), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);
      expect(find.byType(AppErrorState), findsNothing);
    });

    testWidgets('empty state: AppEmptyState present, others absent',
        (tester) async {
      await _pumpScreen(tester, ScreenState.empty);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.byType(AppLoadingState), findsNothing);
      expect(find.byType(AppErrorState), findsNothing);
    });

    testWidgets('error state: AppErrorState present, others absent',
        (tester) async {
      await _pumpScreen(tester, ScreenState.error);

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.byType(AppLoadingState), findsNothing);
      expect(find.byType(AppEmptyState), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Property-based test
  //
  // **Validates: Requirements 4.4, 4.5, 4.6**
  //
  // For any ScreenState value, exactly the corresponding state widget must be
  // present in the widget tree and the other two must be absent.
  // Runs 100 iterations using glados-generated values.
  // -------------------------------------------------------------------------
  group('Screen state management – property tests', () {
    testWidgets(
      'Property 6: for any screen state only the relevant widget is present '
      '(100 iterations)',
      (tester) async {
        final random = Random(42);
        // All three ScreenState values.
        final states = ScreenState.values;

        for (int i = 0; i < 100; i++) {
          // Randomly pick a state using glados int generator.
          final size = (i / 2).ceil().clamp(1, 200);
          final indexSample = any.int(random, size);
          final state = states[indexSample.value.abs() % states.length];

          await _pumpScreen(tester, state);

          switch (state) {
            case ScreenState.loading:
              expect(
                find.byType(AppLoadingState),
                findsOneWidget,
                reason: 'iteration $i: AppLoadingState must be present',
              );
              expect(
                find.byType(AppEmptyState),
                findsNothing,
                reason: 'iteration $i: AppEmptyState must be absent',
              );
              expect(
                find.byType(AppErrorState),
                findsNothing,
                reason: 'iteration $i: AppErrorState must be absent',
              );
            case ScreenState.empty:
              expect(
                find.byType(AppEmptyState),
                findsOneWidget,
                reason: 'iteration $i: AppEmptyState must be present',
              );
              expect(
                find.byType(AppLoadingState),
                findsNothing,
                reason: 'iteration $i: AppLoadingState must be absent',
              );
              expect(
                find.byType(AppErrorState),
                findsNothing,
                reason: 'iteration $i: AppErrorState must be absent',
              );
            case ScreenState.error:
              expect(
                find.byType(AppErrorState),
                findsOneWidget,
                reason: 'iteration $i: AppErrorState must be present',
              );
              expect(
                find.byType(AppLoadingState),
                findsNothing,
                reason: 'iteration $i: AppLoadingState must be absent',
              );
              expect(
                find.byType(AppEmptyState),
                findsNothing,
                reason: 'iteration $i: AppEmptyState must be absent',
              );
          }
        }
      },
    );
  });
}
