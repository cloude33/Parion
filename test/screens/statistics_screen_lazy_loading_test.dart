import 'package:flutter_test/flutter_test.dart';
import '../property_test_utils.dart';

/// **Feature: statistics-redesign**
/// **Validates: Requirements 1.6, 15.1**
///
/// Property-based tests for the `_onTabChanged` lazy loading logic.
///
/// Since `_onTabChanged` is a private method on a StatefulWidget state,
/// the pure logic is extracted into a testable function:
///
/// ```dart
/// List<bool> visitTab(List<bool> tabLoaded, int tabIndex) {
///   if (tabLoaded[tabIndex]) return List<bool>.from(tabLoaded); // already loaded, no change
///   final result = List<bool>.from(tabLoaded);
///   result[tabIndex] = true;
///   return result;
/// }
/// ```

/// Pure function that mirrors the `_onTabChanged` lazy loading logic.
/// When visiting tab at [tabIndex]:
///   - If already loaded, returns a copy with no changes
///   - If not yet loaded, sets only [tabIndex] to true; all other tabs remain unchanged
List<bool> visitTab(List<bool> tabLoaded, int tabIndex) {
  if (tabLoaded[tabIndex]) return List<bool>.from(tabLoaded);
  final result = List<bool>.from(tabLoaded);
  result[tabIndex] = true;
  return result;
}

void main() {
  group('_onTabChanged — Özellik 7: Lazy Loading Sekme Yükleme Sırası', () {
    // Feature: statistics-redesign, Property 7: lazy loading tab isolation

    /// Property 7a: When visiting an unloaded tab i for the first time,
    /// only tabLoaded[i] becomes true; all other tabs remain unchanged.
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 7: ilk kez ziyaret edilen sekme (tabLoaded[i] == false) için yalnızca tabLoaded[i] true olur, diğerleri değişmez',
      generator: () {
        // Pick a random tab index (0–6)
        final tabIndex = PropertyTest.randomInt(min: 0, max: 6);

        // Build a random initial tabLoaded state where the target tab is NOT loaded
        final tabLoaded = List<bool>.generate(7, (i) {
          if (i == tabIndex) return false; // ensure target tab is unloaded
          return PropertyTest.randomBool();
        });

        return {
          'tabLoaded': tabLoaded,
          'tabIndex': tabIndex,
        };
      },
      property: (data) {
        final tabLoaded = data['tabLoaded'] as List<bool>;
        final tabIndex = data['tabIndex'] as int;

        // Pre-condition: the target tab must be unloaded
        expect(tabLoaded[tabIndex], isFalse,
            reason: 'Pre-condition: tab $tabIndex must be unloaded');

        final result = visitTab(tabLoaded, tabIndex);

        // The visited tab must now be true
        expect(
          result[tabIndex],
          isTrue,
          reason: 'Tab $tabIndex should be true after first visit',
        );

        // All other tabs must remain unchanged
        for (int i = 0; i < result.length; i++) {
          if (i != tabIndex) {
            expect(
              result[i],
              equals(tabLoaded[i]),
              reason:
                  'Tab $i should remain ${tabLoaded[i]} (unchanged) after visiting tab $tabIndex',
            );
          }
        }

        return true;
      },
      iterations: 100,
    );

    /// Property 7b: Visiting an already-loaded tab changes nothing.
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 7b: zaten yüklenmiş bir sekmeyi ziyaret etmek hiçbir şeyi değiştirmez',
      generator: () {
        // Pick a random tab index (0–6)
        final tabIndex = PropertyTest.randomInt(min: 0, max: 6);

        // Build a random initial tabLoaded state where the target tab IS loaded
        final tabLoaded = List<bool>.generate(7, (i) {
          if (i == tabIndex) return true; // ensure target tab is already loaded
          return PropertyTest.randomBool();
        });

        return {
          'tabLoaded': tabLoaded,
          'tabIndex': tabIndex,
        };
      },
      property: (data) {
        final tabLoaded = data['tabLoaded'] as List<bool>;
        final tabIndex = data['tabIndex'] as int;

        // Pre-condition: the target tab must already be loaded
        expect(tabLoaded[tabIndex], isTrue,
            reason: 'Pre-condition: tab $tabIndex must already be loaded');

        final result = visitTab(tabLoaded, tabIndex);

        // The result must be identical to the input — no changes at all
        for (int i = 0; i < result.length; i++) {
          expect(
            result[i],
            equals(tabLoaded[i]),
            reason:
                'Tab $i should remain ${tabLoaded[i]} when revisiting already-loaded tab $tabIndex',
          );
        }

        return true;
      },
      iterations: 100,
    );

    /// Property 7c: The result list always has exactly 7 elements.
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 7c: visitTab sonucu her zaman 7 elemanlıdır',
      generator: () {
        final tabIndex = PropertyTest.randomInt(min: 0, max: 6);
        final tabLoaded = List<bool>.generate(7, (_) => PropertyTest.randomBool());
        return {'tabLoaded': tabLoaded, 'tabIndex': tabIndex};
      },
      property: (data) {
        final tabLoaded = data['tabLoaded'] as List<bool>;
        final tabIndex = data['tabIndex'] as int;

        final result = visitTab(tabLoaded, tabIndex);
        expect(result.length, equals(7));

        return true;
      },
      iterations: 100,
    );

    /// Property 7d: Visiting a tab is idempotent — visiting the same tab twice
    /// produces the same result as visiting it once.
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 7d: aynı sekmeyi iki kez ziyaret etmek, bir kez ziyaret etmekle aynı sonucu verir (idempotent)',
      generator: () {
        final tabIndex = PropertyTest.randomInt(min: 0, max: 6);
        final tabLoaded = List<bool>.generate(7, (_) => PropertyTest.randomBool());
        return {'tabLoaded': tabLoaded, 'tabIndex': tabIndex};
      },
      property: (data) {
        final tabLoaded = data['tabLoaded'] as List<bool>;
        final tabIndex = data['tabIndex'] as int;

        final afterFirst = visitTab(tabLoaded, tabIndex);
        final afterSecond = visitTab(afterFirst, tabIndex);

        // Visiting twice must equal visiting once
        for (int i = 0; i < 7; i++) {
          expect(
            afterSecond[i],
            equals(afterFirst[i]),
            reason:
                'Tab $i: second visit of tab $tabIndex should not change anything',
          );
        }

        return true;
      },
      iterations: 100,
    );

    // ── Edge-case unit tests ──────────────────────────────────────────────────

    test('sekme 0 (Özet) ilk kez ziyaret edildiğinde yalnızca sekme 0 true olur', () {
      final tabLoaded = List<bool>.filled(7, false);
      final result = visitTab(tabLoaded, 0);

      expect(result[0], isTrue);
      for (int i = 1; i < 7; i++) {
        expect(result[i], isFalse, reason: 'Tab $i should remain false');
      }
    });

    test('sekme 6 (Tekrarlayan) ilk kez ziyaret edildiğinde yalnızca sekme 6 true olur', () {
      final tabLoaded = List<bool>.filled(7, false);
      final result = visitTab(tabLoaded, 6);

      expect(result[6], isTrue);
      for (int i = 0; i < 6; i++) {
        expect(result[i], isFalse, reason: 'Tab $i should remain false');
      }
    });

    test('zaten yüklenmiş sekme 0 tekrar ziyaret edildiğinde hiçbir şey değişmez', () {
      final tabLoaded = [true, false, true, false, false, true, false];
      final result = visitTab(tabLoaded, 0);

      for (int i = 0; i < 7; i++) {
        expect(result[i], equals(tabLoaded[i]),
            reason: 'Tab $i should be unchanged');
      }
    });

    test('bazı sekmeler yüklüyken sekme 3 ilk kez ziyaret edildiğinde yalnızca sekme 3 değişir', () {
      final tabLoaded = [true, false, true, false, false, false, false];
      final result = visitTab(tabLoaded, 3);

      expect(result[0], isTrue);   // unchanged
      expect(result[1], isFalse);  // unchanged
      expect(result[2], isTrue);   // unchanged
      expect(result[3], isTrue);   // newly loaded
      expect(result[4], isFalse);  // unchanged
      expect(result[5], isFalse);  // unchanged
      expect(result[6], isFalse);  // unchanged
    });

    test('tüm sekmeler yüklüyken herhangi bir sekme ziyaret edildiğinde hiçbir şey değişmez', () {
      final tabLoaded = List<bool>.filled(7, true);
      for (int tabIndex = 0; tabIndex < 7; tabIndex++) {
        final result = visitTab(tabLoaded, tabIndex);
        for (int i = 0; i < 7; i++) {
          expect(result[i], isTrue,
              reason: 'Tab $i should remain true when visiting tab $tabIndex');
        }
      }
    });

    test('visitTab orijinal listeyi mutate etmez (immutability)', () {
      final tabLoaded = List<bool>.filled(7, false);
      final original = List<bool>.from(tabLoaded);

      visitTab(tabLoaded, 2);

      // Original list must be unchanged
      for (int i = 0; i < 7; i++) {
        expect(tabLoaded[i], equals(original[i]),
            reason: 'Original tabLoaded[$i] should not be mutated');
      }
    });
  });
}
