// Feature: app-design-overhaul, Property 5: AppTextField doğrulama tutarlılığı

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart'
    hide test, group, expect, setUp, tearDown, setUpAll, tearDownAll;
import 'package:parion/widgets/common/app_text_field.dart';

/// Renders [AppTextField] inside a [Form] with a validator that always returns
/// [errorMessage] for non-empty strings, triggers validation, and returns
/// whether the error text is visible in the widget tree.
Future<bool> _isErrorVisible(
  WidgetTester tester, {
  required String inputValue,
  required String errorMessage,
}) async {
  final controller = TextEditingController(text: inputValue);
  final formKey = GlobalKey<FormState>();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: AppTextField(
            label: 'Test Field',
            controller: controller,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                return errorMessage;
              }
              return null;
            },
          ),
        ),
      ),
    ),
  );

  // Trigger form validation
  formKey.currentState!.validate();
  await tester.pump();

  // Check if the error message text is visible
  return find.text(errorMessage).evaluate().isNotEmpty;
}

void main() {
  // ---------------------------------------------------------------------------
  // Unit tests – specific validation cases
  // ---------------------------------------------------------------------------
  group('AppTextField – unit tests', () {
    testWidgets('shows error message when validator returns non-null string',
        (tester) async {
      const errorMessage = 'Bu alan zorunludur';
      final isVisible = await _isErrorVisible(
        tester,
        inputValue: 'some input',
        errorMessage: errorMessage,
      );
      expect(isVisible, isTrue);
    });

    testWidgets('shows error for single character input', (tester) async {
      const errorMessage = 'Geçersiz değer';
      final isVisible = await _isErrorVisible(
        tester,
        inputValue: 'a',
        errorMessage: errorMessage,
      );
      expect(isVisible, isTrue);
    });

    testWidgets('shows error for numeric string input', (tester) async {
      const errorMessage = 'Sayı giremezsiniz';
      final isVisible = await _isErrorVisible(
        tester,
        inputValue: '12345',
        errorMessage: errorMessage,
      );
      expect(isVisible, isTrue);
    });

    testWidgets('shows error for special character input', (tester) async {
      const errorMessage = 'Özel karakter hatası';
      final isVisible = await _isErrorVisible(
        tester,
        inputValue: '!@#\$%',
        errorMessage: errorMessage,
      );
      expect(isVisible, isTrue);
    });

    testWidgets('shows error for whitespace-only input', (tester) async {
      const errorMessage = 'Boşluk hatası';
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppTextField(
                label: 'Test',
                controller: TextEditingController(text: '   '),
                validator: (value) {
                  if (value != null && value.trim().isEmpty) {
                    return errorMessage;
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('does not show error when validator returns null',
        (tester) async {
      const errorMessage = 'Bu hata görünmemeli';
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppTextField(
                label: 'Test',
                controller: TextEditingController(text: 'valid'),
                validator: (value) => null,
              ),
            ),
          ),
        ),
      );
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text(errorMessage), findsNothing);
    });

    testWidgets('renders without validator and without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Form(
              child: AppTextField(label: 'No Validator'),
            ),
          ),
        ),
      );
      expect(find.byType(AppTextField), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Property-based test – Validates: Requirement 3.3
  //
  // **Validates: Requirements 3.3**
  //
  // For any non-empty string input value, when the AppTextField validator
  // returns a non-null error message, the widget must visually reflect the
  // error state (error message is visible in the widget tree).
  // Runs 100 iterations using glados-generated values.
  // ---------------------------------------------------------------------------
  group('AppTextField – property tests', () {
    testWidgets(
      'Property 5: error message is visible for any non-empty string input '
      'when validator returns error (100 iterations)',
      (tester) async {
        final random = Random(42);
        // Use nonEmptyLetters to always generate non-empty strings
        final stringGen = any.nonEmptyLetters;

        int iterations = 0;
        int tested = 0;

        while (tested < 100) {
          iterations++;
          final size = (iterations / 2).ceil().clamp(1, 200);

          final inputValue = stringGen(random, size).value;

          const errorMessage = 'Doğrulama hatası';

          final isVisible = await _isErrorVisible(
            tester,
            inputValue: inputValue,
            errorMessage: errorMessage,
          );

          expect(
            isVisible,
            isTrue,
            reason:
                'inputValue="${inputValue.length > 20 ? '${inputValue.substring(0, 20)}...' : inputValue}" '
                '→ error message should be visible when validator returns non-null',
          );

          tested++;
        }
      },
    );
  });
}
