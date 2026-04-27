// Feature: app-design-overhaul, Property 3: Durum widget'ları tema uyumu

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart'
    hide test, group, expect, setUp, tearDown, setUpAll, tearDownAll;
import 'package:parion/widgets/common/app_empty_state.dart';
import 'package:parion/widgets/common/app_error_state.dart';
import 'package:parion/widgets/common/app_loading_state.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [ThemeData] with a distinctive [ColorScheme] so we can verify
/// that the widgets pick up theme tokens rather than hardcoded values.
ThemeData _buildTheme({required Brightness brightness, required Color seed}) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ),
    useMaterial3: true,
  );
}

/// Collects the [color] of the first [Icon] widget in the tree.
Color? _firstIconColor(WidgetTester tester) {
  final icons = tester.widgetList<Icon>(find.byType(Icon));
  for (final icon in icons) {
    if (icon.color != null) return icon.color;
  }
  return null;
}

/// Returns true if [a] and [b] have the same base RGB (ignoring alpha),
/// within a small floating-point tolerance.
bool _sameBaseRgb(Color a, Color b, {double tolerance = 1.5}) {
  return (a.r - b.r).abs() * 255 <= tolerance &&
      (a.g - b.g).abs() * 255 <= tolerance &&
      (a.b - b.b).abs() * 255 <= tolerance;
}

// ---------------------------------------------------------------------------
// Unit tests — specific light / dark scenarios
// ---------------------------------------------------------------------------

void main() {
  group('AppEmptyState – theme compatibility', () {
    testWidgets('renders without error in light theme', (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.light,
        seed: const Color(0xFF2C6BED),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Boş',
              description: 'Hiç öğe yok.',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(AppEmptyState), findsOneWidget);
    });

    testWidgets('renders without error in dark theme', (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.dark,
        seed: const Color(0xFF0A84FF),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Boş',
              description: 'Hiç öğe yok.',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(AppEmptyState), findsOneWidget);
    });

    testWidgets(
        'icon color base RGB matches colorScheme.onSurface in light theme',
        (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.light,
        seed: const Color(0xFF2C6BED),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'T',
              description: 'D',
            ),
          ),
        ),
      );
      final iconColor = _firstIconColor(tester);
      expect(iconColor, isNotNull);
      expect(
        _sameBaseRgb(iconColor!, theme.colorScheme.onSurface),
        isTrue,
        reason:
            'AppEmptyState icon base RGB should match colorScheme.onSurface. '
            'icon=$iconColor onSurface=${theme.colorScheme.onSurface}',
      );
    });

    testWidgets(
        'icon color base RGB matches colorScheme.onSurface in dark theme',
        (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.dark,
        seed: const Color(0xFF0A84FF),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'T',
              description: 'D',
            ),
          ),
        ),
      );
      final iconColor = _firstIconColor(tester);
      expect(iconColor, isNotNull);
      expect(
        _sameBaseRgb(iconColor!, theme.colorScheme.onSurface),
        isTrue,
        reason:
            'AppEmptyState icon base RGB should match colorScheme.onSurface in dark. '
            'icon=$iconColor onSurface=${theme.colorScheme.onSurface}',
      );
    });

    testWidgets(
        'icon color changes when theme onSurface changes (proves theme usage)',
        (tester) async {
      // Use two very different seeds so onSurface colors are clearly different.
      final lightTheme = _buildTheme(
        brightness: Brightness.light,
        seed: const Color(0xFF2C6BED),
      );
      final darkTheme = _buildTheme(
        brightness: Brightness.dark,
        seed: const Color(0xFF2C6BED),
      );

      // Verify the two themes have different onSurface colors.
      if (_sameBaseRgb(
          lightTheme.colorScheme.onSurface, darkTheme.colorScheme.onSurface)) {
        return; // skip — themes are too similar to distinguish
      }

      // Render with light theme.
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: const Scaffold(
            body: AppEmptyState(icon: Icons.inbox, title: 'T', description: 'D'),
          ),
        ),
      );
      await tester.pump();
      final lightIconColor = _firstIconColor(tester);

      // Clear the tree, then render with dark theme.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: const Scaffold(
            body: AppEmptyState(icon: Icons.inbox, title: 'T', description: 'D'),
          ),
        ),
      );
      await tester.pump();
      final darkIconColor = _firstIconColor(tester);

      expect(
        _sameBaseRgb(lightIconColor!, darkIconColor!),
        isFalse,
        reason:
            'AppEmptyState icon color should differ between light and dark themes '
            'when onSurface differs. light=$lightIconColor dark=$darkIconColor',
      );
    });
  });

  group('AppErrorState – theme compatibility', () {
    testWidgets('renders without error in light theme', (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.light,
        seed: const Color(0xFF2C6BED),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: AppErrorState(message: 'Bir hata oluştu.'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(AppErrorState), findsOneWidget);
    });

    testWidgets('renders without error in dark theme', (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.dark,
        seed: const Color(0xFF0A84FF),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: AppErrorState(message: 'Bir hata oluştu.'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(AppErrorState), findsOneWidget);
    });

    testWidgets('error icon base color matches colorScheme.error in light theme',
        (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.light,
        seed: const Color(0xFF2C6BED),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: AppErrorState(message: 'Hata')),
        ),
      );
      final iconColor = _firstIconColor(tester);
      expect(iconColor, isNotNull);
      expect(
        _sameBaseRgb(iconColor!, theme.colorScheme.error),
        isTrue,
        reason:
            'AppErrorState icon base RGB should match colorScheme.error. '
            'icon=$iconColor error=${theme.colorScheme.error}',
      );
    });

    testWidgets('error icon base color matches colorScheme.error in dark theme',
        (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.dark,
        seed: const Color(0xFF0A84FF),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: AppErrorState(message: 'Hata')),
        ),
      );
      final iconColor = _firstIconColor(tester);
      expect(iconColor, isNotNull);
      expect(
        _sameBaseRgb(iconColor!, theme.colorScheme.error),
        isTrue,
        reason:
            'AppErrorState icon base RGB should match colorScheme.error in dark. '
            'icon=$iconColor error=${theme.colorScheme.error}',
      );
    });

    testWidgets(
        'error icon color changes when theme error color changes (proves theme usage)',
        (tester) async {
      final lightTheme = _buildTheme(
        brightness: Brightness.light,
        seed: const Color(0xFF2C6BED),
      );
      final darkTheme = _buildTheme(
        brightness: Brightness.dark,
        seed: const Color(0xFF2C6BED),
      );

      if (_sameBaseRgb(
          lightTheme.colorScheme.error, darkTheme.colorScheme.error)) {
        return; // skip — error colors are too similar
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: const Scaffold(body: AppErrorState(message: 'E')),
        ),
      );
      await tester.pump();
      final lightIconColor = _firstIconColor(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: const Scaffold(body: AppErrorState(message: 'E')),
        ),
      );
      await tester.pump();
      final darkIconColor = _firstIconColor(tester);

      expect(
        _sameBaseRgb(lightIconColor!, darkIconColor!),
        isFalse,
        reason:
            'AppErrorState icon color should differ between light and dark themes '
            'when error color differs. light=$lightIconColor dark=$darkIconColor',
      );
    });
  });

  group('AppLoadingState – theme compatibility', () {
    testWidgets('renders without error in light theme', (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.light,
        seed: const Color(0xFF2C6BED),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: AppLoadingState()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets('renders without error in dark theme', (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.dark,
        seed: const Color(0xFF0A84FF),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: AppLoadingState()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets(
        'fallback CircularProgressIndicator uses colorScheme.primary when itemCount=0',
        (tester) async {
      final theme = _buildTheme(
        brightness: Brightness.light,
        seed: const Color(0xFF2C6BED),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: AppLoadingState(itemCount: 0)),
        ),
      );
      await tester.pump();
      final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      expect(indicator.color, isNotNull);
      expect(
        _sameBaseRgb(indicator.color!, theme.colorScheme.primary),
        isTrue,
        reason:
            'AppLoadingState fallback indicator base RGB should match colorScheme.primary. '
            'indicator=${indicator.color} primary=${theme.colorScheme.primary}',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Property-based test
  //
  // **Validates: Requirements 4.7, 8.2**
  //
  // For any theme (light or dark), AppEmptyState, AppErrorState, and
  // AppLoadingState must render without errors and use Theme.of(context)
  // colorScheme tokens for their colors — not hardcoded values.
  //
  // The property is verified by:
  // 1. Rendering each widget with two different themes (different seed colors)
  // 2. Verifying the widget renders without errors in both themes
  // 3. Verifying that when the theme's colorScheme changes, the widget's
  //    rendered colors change accordingly (proving theme token usage)
  //
  // Runs 100 iterations using glados-generated seed colors.
  // ---------------------------------------------------------------------------
  group('State widgets – property tests', () {
    testWidgets(
      'Property 3: state widgets render correctly and adapt to any theme '
      '(100 iterations)',
      (tester) async {
        final random = Random(42);
        final intGen = any.int;

        int tested = 0;
        int iterations = 0;

        while (tested < 100) {
          iterations++;
          final size = (iterations / 2).ceil().clamp(1, 200);

          // Generate two distinct seed colors.
          final r1 = (intGen(random, size).value.abs() % 256);
          final g1 = (intGen(random, size).value.abs() % 256);
          final b1 = (intGen(random, size).value.abs() % 256);
          final r2 = (intGen(random, size).value.abs() % 256);
          final g2 = (intGen(random, size).value.abs() % 256);
          final b2 = (intGen(random, size).value.abs() % 256);

          final seed1 = Color.fromARGB(255, r1, g1, b1);
          final seed2 = Color.fromARGB(255, r2, g2, b2);

          final lightTheme = _buildTheme(brightness: Brightness.light, seed: seed1);
          final darkTheme = _buildTheme(brightness: Brightness.dark, seed: seed2);

          // --- AppEmptyState: renders in both themes without error ---
          for (final theme in [lightTheme, darkTheme]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: const Scaffold(
                  body: AppEmptyState(
                    icon: Icons.inbox,
                    title: 'Test',
                    description: 'Desc',
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 50));
            expect(
              find.byType(AppEmptyState),
              findsOneWidget,
              reason: 'AppEmptyState should render for seed1=$seed1 seed2=$seed2',
            );
          }

          // --- AppErrorState: renders in both themes without error ---
          for (final theme in [lightTheme, darkTheme]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: const Scaffold(
                  body: AppErrorState(message: 'Error'),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 50));
            expect(
              find.byType(AppErrorState),
              findsOneWidget,
              reason: 'AppErrorState should render for seed1=$seed1 seed2=$seed2',
            );
          }

          // --- AppLoadingState: renders in both themes without error ---
          for (final theme in [lightTheme, darkTheme]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: const Scaffold(body: AppLoadingState()),
              ),
            );
            await tester.pump(const Duration(milliseconds: 100));
            expect(
              find.byType(AppLoadingState),
              findsOneWidget,
              reason: 'AppLoadingState should render for seed1=$seed1 seed2=$seed2',
            );
          }

          // --- Verify theme token usage: AppEmptyState icon color tracks onSurface ---
          // Render with lightTheme and capture icon color.
          await tester.pumpWidget(
            MaterialApp(
              theme: lightTheme,
              home: const Scaffold(
                body: AppEmptyState(icon: Icons.inbox, title: 'T', description: 'D'),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          final emptyIconLight = _firstIconColor(tester);

          // Clear tree, then render with darkTheme.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(
            MaterialApp(
              theme: darkTheme,
              home: const Scaffold(
                body: AppEmptyState(icon: Icons.inbox, title: 'T', description: 'D'),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          final emptyIconDark = _firstIconColor(tester);

          // If the two themes have different onSurface colors, the icon colors
          // must also differ — proving the widget uses theme tokens.
          if (emptyIconLight != null &&
              emptyIconDark != null &&
              !_sameBaseRgb(
                  lightTheme.colorScheme.onSurface,
                  darkTheme.colorScheme.onSurface)) {
            expect(
              _sameBaseRgb(emptyIconLight, emptyIconDark),
              isFalse,
              reason:
                  'AppEmptyState icon color should differ when onSurface differs. '
                  'light=$emptyIconLight dark=$emptyIconDark '
                  'lightOnSurface=${lightTheme.colorScheme.onSurface} '
                  'darkOnSurface=${darkTheme.colorScheme.onSurface}',
            );
          }

          // --- Verify theme token usage: AppErrorState icon color tracks error ---
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(
            MaterialApp(
              theme: lightTheme,
              home: const Scaffold(body: AppErrorState(message: 'E')),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          final errorIconLight = _firstIconColor(tester);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(
            MaterialApp(
              theme: darkTheme,
              home: const Scaffold(body: AppErrorState(message: 'E')),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          final errorIconDark = _firstIconColor(tester);

          if (errorIconLight != null &&
              errorIconDark != null &&
              !_sameBaseRgb(
                  lightTheme.colorScheme.error, darkTheme.colorScheme.error)) {
            expect(
              _sameBaseRgb(errorIconLight, errorIconDark),
              isFalse,
              reason:
                  'AppErrorState icon color should differ when error color differs. '
                  'light=$errorIconLight dark=$errorIconDark '
                  'lightError=${lightTheme.colorScheme.error} '
                  'darkError=${darkTheme.colorScheme.error}',
            );
          }

          tested++;
        }
      },
    );
  });
}
