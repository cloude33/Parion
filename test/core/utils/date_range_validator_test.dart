import 'package:flutter_test/flutter_test.dart';
import 'package:parion/core/utils/date_range_validator.dart';
import '../../../test/property_test_utils.dart';

/// **Feature: statistics-redesign**
/// **Validates: Requirements 2.5**
///
/// Property-based tests for [validateDateRange].
void main() {
  group('validateDateRange Property Tests', () {
    // Feature: statistics-redesign, Property 6: invalid date range rejection
    PropertyTest.forAll<Map<String, DateTime>>(
      description:
          'Property 6: endDate < startDate koşulunda isValid == false ve errorMessage != null döner',
      generator: () {
        // Generate a start date, then an end date strictly before it
        final start = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2030, 12, 31),
        );
        // end is 1..365 days before start
        final daysBack = 1 + PropertyTest.randomInt(min: 0, max: 364);
        final end = start.subtract(Duration(days: daysBack));
        return {'start': start, 'end': end};
      },
      property: (data) {
        final start = data['start']!;
        final end = data['end']!;

        final result = validateDateRange(start, end);

        expect(result.isValid, isFalse,
            reason: 'end ($end) < start ($start) olduğunda isValid false olmalı');
        expect(result.errorMessage, isNotNull,
            reason: 'end ($end) < start ($start) olduğunda errorMessage null olmamalı');

        return true;
      },
      iterations: 100,
    );

    // Feature: statistics-redesign, Property 6 (inverse): endDate >= startDate koşulunda isValid == true
    PropertyTest.forAll<Map<String, DateTime>>(
      description:
          'Property 6 (inverse): endDate >= startDate koşulunda isValid == true ve errorMessage == null döner',
      generator: () {
        // Generate a start date, then an end date on or after it
        final start = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2030, 6, 30),
        );
        // end is 0..365 days after start (0 = same day)
        final daysAhead = PropertyTest.randomInt(min: 0, max: 365);
        final end = start.add(Duration(days: daysAhead));
        return {'start': start, 'end': end};
      },
      property: (data) {
        final start = data['start']!;
        final end = data['end']!;

        final result = validateDateRange(start, end);

        expect(result.isValid, isTrue,
            reason: 'end ($end) >= start ($start) olduğunda isValid true olmalı');
        expect(result.errorMessage, isNull,
            reason: 'end ($end) >= start ($start) olduğunda errorMessage null olmalı');

        return true;
      },
      iterations: 100,
    );

    // Feature: statistics-redesign, Property 6 (same day): endDate == startDate koşulunda isValid == true
    PropertyTest.forAll<DateTime>(
      description:
          'Property 6 (same day): endDate == startDate (aynı gün) koşulunda isValid == true döner',
      generator: () {
        return PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2030, 12, 31),
        );
      },
      property: (date) {
        final result = validateDateRange(date, date);

        expect(result.isValid, isTrue,
            reason: 'Aynı gün ($date) geçerli bir aralık olmalı');
        expect(result.errorMessage, isNull,
            reason: 'Aynı gün ($date) için errorMessage null olmalı');

        return true;
      },
      iterations: 100,
    );
  });

  group('validateDateRange Edge Case Tests', () {
    // Edge case: same date is valid
    test('Aynı tarih geçerlidir', () {
      final date = DateTime(2024, 6, 15);
      final result = validateDateRange(date, date);
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    // Edge case: one day apart (end after start) is valid
    test('Bir gün arayla (end > start) geçerlidir', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 2);
      final result = validateDateRange(start, end);
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    // Edge case: one day apart (end before start) is invalid
    test('Bir gün arayla (end < start) geçersizdir', () {
      final start = DateTime(2024, 1, 2);
      final end = DateTime(2024, 1, 1);
      final result = validateDateRange(start, end);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    // Edge case: large date range (years apart) is valid
    test('Büyük tarih aralığı (yıllar arası) geçerlidir', () {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2030, 12, 31);
      final result = validateDateRange(start, end);
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    // Edge case: large reversed date range is invalid
    test('Büyük ters tarih aralığı geçersizdir', () {
      final start = DateTime(2030, 12, 31);
      final end = DateTime(2020, 1, 1);
      final result = validateDateRange(start, end);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    // Edge case: error message content check
    test('Geçersiz aralıkta hata mesajı boş değildir', () {
      final start = DateTime(2024, 6, 15);
      final end = DateTime(2024, 6, 14);
      final result = validateDateRange(start, end);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage!.isNotEmpty, isTrue);
    });
  });
}
