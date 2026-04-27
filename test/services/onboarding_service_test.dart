// Feature: app-design-overhaul, Property 4: Onboarding tamamlanma kalıcılığı (round-trip)

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart'
    hide test, group, expect, setUp, tearDown, setUpAll, tearDownAll;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parion/services/onboarding_service.dart';

/// **Validates: Requirements 7.1, 7.4**
///
/// Property 4: Onboarding tamamlanma kalıcılığı (round-trip)
///
/// For any call sequence, after [markOnboardingCompleted()] is called,
/// [isOnboardingCompleted()] must always return `true`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Unit tests – specific cases
  // ---------------------------------------------------------------------------
  group('OnboardingService – unit tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isOnboardingCompleted returns false initially', () async {
      final service = OnboardingService();
      expect(await service.isOnboardingCompleted(), isFalse);
    });

    test('isOnboardingCompleted returns true after markOnboardingCompleted',
        () async {
      final service = OnboardingService();
      await service.markOnboardingCompleted();
      expect(await service.isOnboardingCompleted(), isTrue);
    });

    test('markOnboardingCompleted is idempotent', () async {
      final service = OnboardingService();
      await service.markOnboardingCompleted();
      await service.markOnboardingCompleted();
      expect(await service.isOnboardingCompleted(), isTrue);
    });

    test('fresh instance reads persisted value', () async {
      final service1 = OnboardingService();
      await service1.markOnboardingCompleted();

      // A second instance shares the same SharedPreferences mock.
      final service2 = OnboardingService();
      expect(await service2.isOnboardingCompleted(), isTrue);
    });

    test('isOnboardingCompleted returns false when key is absent', () async {
      SharedPreferences.setMockInitialValues({'other_key': true});
      final service = OnboardingService();
      expect(await service.isOnboardingCompleted(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Property-based test
  //
  // **Validates: Requirements 7.1, 7.4**
  //
  // For any iteration (100 total), after calling markOnboardingCompleted()
  // on a freshly mocked SharedPreferences, isOnboardingCompleted() must
  // return true.  Each iteration resets the mock to ensure isolation.
  // ---------------------------------------------------------------------------
  group('OnboardingService – property tests', () {
    test(
      'Property 4: isOnboardingCompleted always returns true after '
      'markOnboardingCompleted (100 iterations)',
      () async {
        // Use glados int generator purely to drive 100 varied iterations;
        // the actual value is not used in the assertion – what matters is
        // that the round-trip holds for every fresh SharedPreferences state.
        final random = Random(42);
        final intGen = any.int;

        int iterations = 0;
        int tested = 0;

        while (tested < 100) {
          iterations++;
          final size = (iterations / 2).ceil().clamp(1, 200);

          // Consume a generated value to advance the random state (mirrors
          // how other glados-based tests in this project work).
          intGen(random, size);

          // Each iteration gets a completely fresh SharedPreferences mock.
          SharedPreferences.setMockInitialValues({});

          final service = OnboardingService();

          // Pre-condition: onboarding not yet completed.
          final before = await service.isOnboardingCompleted();
          expect(
            before,
            isFalse,
            reason: 'iteration $tested: expected false before marking',
          );

          // Action: mark as completed.
          await service.markOnboardingCompleted();

          // Post-condition: must always be true.
          final after = await service.isOnboardingCompleted();
          expect(
            after,
            isTrue,
            reason: 'iteration $tested: expected true after marking',
          );

          tested++;
        }
      },
    );
  });
}
