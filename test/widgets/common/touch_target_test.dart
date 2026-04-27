// Feature: app-design-overhaul, Property 7: Dokunma hedefi minimum boyutu

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart'
    hide test, group, expect, setUp, tearDown, setUpAll, tearDownAll;
import 'package:parion/widgets/common/app_button.dart';
import 'package:parion/widgets/common/app_card.dart';

const double kMinTouchTarget = 44.0;

/// Pumps an [AppButton] and returns its rendered [Size].
Future<Size> _getButtonSize(
  WidgetTester tester, {
  required String label,
  required AppButtonVariant variant,
  VoidCallback? onPressed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppButton(
            label: label,
            variant: variant,
            onPressed: onPressed ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.getSize(find.byType(AppButton));
}

/// Pumps an [AppCard] with [onTap] and returns its rendered [Size].
Future<Size> _getCardSize(
  WidgetTester tester, {
  required Widget child,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppCard(
            onTap: onTap ?? () {},
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.getSize(find.byType(AppCard));
}

void main() {
  // ---------------------------------------------------------------------------
  // Unit tests – specific cases
  // ---------------------------------------------------------------------------
  group('AppButton touch target – unit tests', () {
    testWidgets('primary variant meets 44x44 minimum', (tester) async {
      final size = await _getButtonSize(
        tester,
        label: 'Kaydet',
        variant: AppButtonVariant.primary,
      );
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
    });

    testWidgets('secondary variant meets 44x44 minimum', (tester) async {
      final size = await _getButtonSize(
        tester,
        label: 'İptal',
        variant: AppButtonVariant.secondary,
      );
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
    });

    testWidgets('text variant meets 44x44 minimum', (tester) async {
      final size = await _getButtonSize(
        tester,
        label: 'Daha Fazla',
        variant: AppButtonVariant.text,
      );
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
    });

    testWidgets('disabled button (onPressed null) meets 44x44 minimum',
        (tester) async {
      final size = await _getButtonSize(
        tester,
        label: 'Devre Dışı',
        variant: AppButtonVariant.primary,
        onPressed: null,
      );
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
    });

    testWidgets('short label button still meets 44x44 minimum', (tester) async {
      final size = await _getButtonSize(
        tester,
        label: 'OK',
        variant: AppButtonVariant.primary,
      );
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
    });
  });

  group('AppCard with onTap touch target – unit tests', () {
    testWidgets('card with onTap meets 44x44 minimum', (tester) async {
      final size = await _getCardSize(
        tester,
        child: const Text('Kart İçeriği'),
      );
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
    });

    testWidgets('card with onTap and tall content meets 44x44 minimum',
        (tester) async {
      final size = await _getCardSize(
        tester,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Satır 1'),
            Text('Satır 2'),
            Text('Satır 3'),
          ],
        ),
      );
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
    });

    testWidgets('card with onTap and icon child meets 44x44 minimum',
        (tester) async {
      final size = await _getCardSize(
        tester,
        child: const Icon(Icons.star),
      );
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
    });
  });

  // ---------------------------------------------------------------------------
  // Property-based tests – Validates: Requirement 10.1
  //
  // **Validates: Requirements 10.1**
  //
  // For any AppButton (any variant, any label) and any AppCard with onTap,
  // the rendered touch target must be at least 44x44 pixels.
  // Runs 100 iterations using glados-generated values.
  // ---------------------------------------------------------------------------
  group('AppButton touch target – property tests', () {
    testWidgets(
      'Property 7: AppButton always has >= 44x44 touch target for any variant '
      'and enabled/disabled state (100 iterations)',
      (tester) async {
        final random = Random(42);
        final intGen = any.positiveInt;
        final boolGen = any.bool;

        // Representative labels of varying lengths
        final labels = [
          'OK',
          'Kaydet',
          'İptal Et',
          'Devam',
          'Gönder',
          'Sil',
          'Güncelle',
          'Ekle',
          'Tamam',
          'Vazgeç',
        ];
        final variants = AppButtonVariant.values;
        int tested = 0;
        int iterations = 0;

        while (tested < 100) {
          iterations++;
          final size = (iterations / 2).ceil().clamp(1, 100);

          final labelIndex = intGen(random, size).value % labels.length;
          final variantIndex = intGen(random, size).value % variants.length;
          final isEnabled = boolGen(random, size).value;

          final label = labels[labelIndex];
          final variant = variants[variantIndex];

          final renderedSize = await _getButtonSize(
            tester,
            label: label,
            variant: variant,
            onPressed: isEnabled ? () {} : null,
          );

          expect(
            renderedSize.width,
            greaterThanOrEqualTo(kMinTouchTarget),
            reason:
                'AppButton(label="$label", variant=$variant, enabled=$isEnabled) '
                'width=${renderedSize.width} < $kMinTouchTarget',
          );
          expect(
            renderedSize.height,
            greaterThanOrEqualTo(kMinTouchTarget),
            reason:
                'AppButton(label="$label", variant=$variant, enabled=$isEnabled) '
                'height=${renderedSize.height} < $kMinTouchTarget',
          );

          tested++;
        }
      },
    );
  });

  group('AppCard with onTap touch target – property tests', () {
    testWidgets(
      'Property 7: AppCard with onTap always has >= 44x44 touch target for '
      'any content height (100 iterations)',
      (tester) async {
        final random = Random(42);
        final intGen = any.positiveInt;

        int tested = 0;
        int iterations = 0;

        while (tested < 100) {
          iterations++;
          final size = (iterations / 2).ceil().clamp(1, 100);

          // Vary the number of text lines (1–5) to exercise different heights
          final lineCount = (intGen(random, size).value % 5) + 1;
          final children = List.generate(
            lineCount,
            (i) => Text('Satır ${i + 1}'),
          );

          final renderedSize = await _getCardSize(
            tester,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          );

          expect(
            renderedSize.width,
            greaterThanOrEqualTo(kMinTouchTarget),
            reason:
                'AppCard(onTap, lineCount=$lineCount) width=${renderedSize.width} < $kMinTouchTarget',
          );
          expect(
            renderedSize.height,
            greaterThanOrEqualTo(kMinTouchTarget),
            reason:
                'AppCard(onTap, lineCount=$lineCount) height=${renderedSize.height} < $kMinTouchTarget',
          );

          tested++;
        }
      },
    );
  });
}
