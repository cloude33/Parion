// Feature: app-design-overhaul, Property 2: AppSpacing değerleri 4px tabanlıdır

import 'package:glados/glados.dart';
import 'package:parion/core/design/app_spacing.dart';

void main() {
  // All AppSpacing constants as a list for iteration
  const allSpacingValues = <double>[
    AppSpacing.xs,
    AppSpacing.sm,
    AppSpacing.md,
    AppSpacing.lg,
    AppSpacing.xl,
    AppSpacing.xxl,
    AppSpacing.xxxl,
    AppSpacing.huge,
  ];

  // Unit tests: explicitly verify each constant value
  group('AppSpacing unit tests', () {
    test('xs is 4', () => expect(AppSpacing.xs, 4.0));
    test('sm is 8', () => expect(AppSpacing.sm, 8.0));
    test('md is 12', () => expect(AppSpacing.md, 12.0));
    test('lg is 16', () => expect(AppSpacing.lg, 16.0));
    test('xl is 20', () => expect(AppSpacing.xl, 20.0));
    test('xxl is 24', () => expect(AppSpacing.xxl, 24.0));
    test('xxxl is 32', () => expect(AppSpacing.xxxl, 32.0));
    test('huge is 48', () => expect(AppSpacing.huge, 48.0));

    test('all constants are divisible by 4', () {
      for (final value in allSpacingValues) {
        expect(
          value % 4,
          0.0,
          reason: 'AppSpacing value $value is not divisible by 4',
        );
      }
    });
  });

  // Property-based test — Validates: Requirement 2.3
  // Verifies that every AppSpacing constant satisfies value % 4 == 0
  Glados(any.positiveIntOrZero, ExploreConfig(numRuns: 100)).test(
    'Property 2: every AppSpacing constant is divisible by 4',
    (int _) {
      for (final value in allSpacingValues) {
        expect(
          value % 4,
          0.0,
          reason: 'AppSpacing value $value must be divisible by 4',
        );
      }
    },
  );
}
