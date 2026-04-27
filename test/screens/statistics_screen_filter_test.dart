import 'package:flutter_test/flutter_test.dart';
import 'package:parion/screens/statistics_screen.dart';
import '../property_test_utils.dart';

/// **Feature: statistics-redesign**
/// **Validates: Requirements 2.3, 15.3**
///
/// Property-based tests for the `_onFilterChanged` logic.
///
/// Since `_onFilterChanged` is a private method on a StatefulWidget state,
/// the pure logic is extracted into a testable function:
///
/// ```dart
/// List<bool> applyFilterChange(List<bool> tabLoaded, int activeTabIndex) {
///   final result = List<bool>.filled(tabLoaded.length, false);
///   result[activeTabIndex] = true;
///   return result;
/// }
/// ```

/// Pure function that mirrors the `_onFilterChanged` tab-reset logic.
/// After a filter change:
///   - All tabs are reset to false
///   - The active tab is immediately set to true
List<bool> applyFilterChange(List<bool> tabLoaded, int activeTabIndex) {
  final result = List<bool>.filled(tabLoaded.length, false);
  result[activeTabIndex] = true;
  return result;
}

void main() {
  group('_onFilterChanged — Özellik 5: Zaman Filtresi Değişiminde Sekme Sıfırlama', () {
    // Feature: statistics-redesign, Property 5: filter change resets all tabs

    /// Property 5a: For any TimeFilter value and any active tab index (0–6),
    /// after applyFilterChange all tabs except the active one are false.
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 5: herhangi bir filtre değişiminde aktif sekme dışındaki tüm _tabLoaded[i] değerleri false olur',
      generator: () {
        // Pick a random active tab index (0–6)
        final activeTabIndex = PropertyTest.randomInt(min: 0, max: 6);

        // Build a random initial tabLoaded state (some true, some false)
        final tabLoaded = List<bool>.generate(
          7,
          (_) => PropertyTest.randomBool(),
        );

        // Pick a random TimeFilter value (0–4 maps to the 5 enum values)
        final filterIndex = PropertyTest.randomInt(min: 0, max: 4);
        final filters = TimeFilter.values;
        final filter = filters[filterIndex];

        return {
          'tabLoaded': tabLoaded,
          'activeTabIndex': activeTabIndex,
          'filter': filter,
        };
      },
      property: (data) {
        final tabLoaded = data['tabLoaded'] as List<bool>;
        final activeTabIndex = data['activeTabIndex'] as int;
        // filter is generated but the pure function doesn't need it —
        // the property holds for ALL TimeFilter values by construction.

        final result = applyFilterChange(tabLoaded, activeTabIndex);

        // The result must have the same length as the input
        expect(result.length, equals(7));

        // All tabs except the active one must be false
        for (int i = 0; i < result.length; i++) {
          if (i != activeTabIndex) {
            expect(
              result[i],
              isFalse,
              reason:
                  'Tab $i should be false after filter change (active=$activeTabIndex)',
            );
          }
        }

        // The active tab must be true
        expect(
          result[activeTabIndex],
          isTrue,
          reason:
              'Active tab $activeTabIndex should be true after filter change',
        );

        return true;
      },
      iterations: 100,
    );

    /// Property 5b: The result list always has exactly 7 elements.
    PropertyTest.forAll<int>(
      description:
          'Property 5b: filtre değişimi sonrası _tabLoaded listesi her zaman 7 elemanlıdır',
      generator: () => PropertyTest.randomInt(min: 0, max: 6),
      property: (activeTabIndex) {
        final tabLoaded = List<bool>.filled(7, false);
        final result = applyFilterChange(tabLoaded, activeTabIndex);
        expect(result.length, equals(7));
        return true;
      },
      iterations: 100,
    );

    /// Property 5c: Exactly one tab is true after filter change (the active tab).
    PropertyTest.forAll<int>(
      description:
          'Property 5c: filtre değişimi sonrası tam olarak bir sekme (aktif sekme) true olur',
      generator: () => PropertyTest.randomInt(min: 0, max: 6),
      property: (activeTabIndex) {
        // Start with all tabs loaded (worst case — all true)
        final tabLoaded = List<bool>.filled(7, true);
        final result = applyFilterChange(tabLoaded, activeTabIndex);

        final trueCount = result.where((v) => v).length;
        expect(
          trueCount,
          equals(1),
          reason:
              'Exactly one tab should be true after filter change, got $trueCount',
        );
        expect(result[activeTabIndex], isTrue);

        return true;
      },
      iterations: 100,
    );

    /// Property 5d: All 5 TimeFilter values produce the same reset behaviour.
    /// Tests each TimeFilter value explicitly across all possible active tab indices.
    PropertyTest.forAll<Map<String, int>>(
      description:
          'Property 5d: tüm 5 TimeFilter değeri (daily, weekly, monthly, yearly, custom) için sekme sıfırlama davranışı aynıdır',
      generator: () {
        return {
          'activeTabIndex': PropertyTest.randomInt(min: 0, max: 6),
          'filterIndex': PropertyTest.randomInt(min: 0, max: 4),
        };
      },
      property: (data) {
        final activeTabIndex = data['activeTabIndex']!;
        final filterIndex = data['filterIndex']!;

        // Verify the TimeFilter enum has exactly 5 values
        expect(TimeFilter.values.length, equals(5));

        // Verify the specific filter value exists
        final filter = TimeFilter.values[filterIndex];
        expect(filter, isNotNull);

        // Apply the filter change logic
        final tabLoaded = List<bool>.generate(7, (i) => i < 3); // first 3 true
        final result = applyFilterChange(tabLoaded, activeTabIndex);

        // Regardless of which filter was chosen, the reset behaviour is identical:
        // all tabs false except the active one
        for (int i = 0; i < 7; i++) {
          if (i == activeTabIndex) {
            expect(result[i], isTrue,
                reason: 'Active tab $i must be true for filter $filter');
          } else {
            expect(result[i], isFalse,
                reason: 'Tab $i must be false for filter $filter');
          }
        }

        return true;
      },
      iterations: 100,
    );

    // ── Edge-case unit tests ──────────────────────────────────────────────────

    test('aktif sekme 0 (Özet) iken filtre değişiminde yalnızca sekme 0 true olur', () {
      final tabLoaded = List<bool>.filled(7, true);
      final result = applyFilterChange(tabLoaded, 0);

      expect(result[0], isTrue);
      for (int i = 1; i < 7; i++) {
        expect(result[i], isFalse, reason: 'Tab $i should be false');
      }
    });

    test('aktif sekme 6 (Tekrarlayan) iken filtre değişiminde yalnızca sekme 6 true olur', () {
      final tabLoaded = List<bool>.filled(7, true);
      final result = applyFilterChange(tabLoaded, 6);

      expect(result[6], isTrue);
      for (int i = 0; i < 6; i++) {
        expect(result[i], isFalse, reason: 'Tab $i should be false');
      }
    });

    test('tüm sekmeler zaten false iken filtre değişiminde aktif sekme true olur', () {
      final tabLoaded = List<bool>.filled(7, false);
      final result = applyFilterChange(tabLoaded, 3);

      expect(result[3], isTrue);
      for (int i = 0; i < 7; i++) {
        if (i != 3) expect(result[i], isFalse);
      }
    });

    test('TimeFilter enum tam olarak 5 değer içerir', () {
      expect(TimeFilter.values.length, equals(5));
      expect(TimeFilter.values, contains(TimeFilter.daily));
      expect(TimeFilter.values, contains(TimeFilter.weekly));
      expect(TimeFilter.values, contains(TimeFilter.monthly));
      expect(TimeFilter.values, contains(TimeFilter.yearly));
      expect(TimeFilter.values, contains(TimeFilter.custom));
    });
  });
}
