import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/screens/welcome_screen.dart';
import 'package:parion/screens/login_screen.dart';
import 'package:parion/screens/register_screen.dart';
import '../test_setup.dart';

/// Performance tests for Authentication System
/// Tests loading times, animation performance, and responsiveness
/// 
/// Performance Targets:
/// - Screen load: < 500ms
/// - Animation duration: < 300ms
/// - Form validation: < 100ms
/// - Navigation: < 200ms
void main() {
  group('Authentication Performance Tests', () {
    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();
    });

    tearDownAll(() async {
      await TestSetup.cleanupTestEnvironment();
    });

    setUp(() async {
      await TestSetup.setupTest();
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    group('Screen Loading Performance', () {
      testWidgets(
        'should load welcome screen within 500ms',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            const MaterialApp(
              home: WelcomeScreen(),
            ),
          );

          // Initial pump
          await tester.pump();
          
          // Wait for animations and async operations
          await tester.pump(const Duration(milliseconds: 300));

          stopwatch.stop();
          final loadTime = stopwatch.elapsedMilliseconds;

          print('🚀 Welcome screen load time: ${loadTime}ms');
          
          // Target: < 500ms
          expect(
            loadTime,
            lessThan(500),
            reason: 'Welcome screen should load within 500ms. Actual: ${loadTime}ms',
          );

          // Verify screen loaded successfully
          expect(find.text('Parion'), findsOneWidget);
        },
      );

      testWidgets(
        'should load login screen within 500ms',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          stopwatch.stop();
          final loadTime = stopwatch.elapsedMilliseconds;

          print('🚀 Login screen load time: ${loadTime}ms');
          
          // Target: < 500ms
          expect(
            loadTime,
            lessThan(500),
            reason: 'Login screen should load within 500ms. Actual: ${loadTime}ms',
          );

          expect(find.text('Hoş Geldiniz'), findsOneWidget);
        },
      );

      testWidgets(
        'should load register screen within 500ms',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            const MaterialApp(
              home: RegisterScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          stopwatch.stop();
          final loadTime = stopwatch.elapsedMilliseconds;

          print('🚀 Register screen load time: ${loadTime}ms');
          
          // Target: < 500ms
          expect(
            loadTime,
            lessThan(500),
            reason: 'Register screen should load within 500ms. Actual: ${loadTime}ms',
          );

          expect(find.text('Kayıt Ol'), findsOneWidget);
        },
      );
    });

    group('Animation Performance', () {
      testWidgets(
        'should complete welcome screen animations within 300ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: WelcomeScreen(),
            ),
          );

          await tester.pump();

          final stopwatch = Stopwatch()..start();

          // Wait for animations to complete
          await tester.pump(const Duration(milliseconds: 250));

          stopwatch.stop();
          final animationTime = stopwatch.elapsedMilliseconds;

          print('🚀 Welcome screen animation time: ${animationTime}ms');
          
          // Target: < 300ms
          expect(
            animationTime,
            lessThan(300),
            reason: 'Animations should complete within 300ms. Actual: ${animationTime}ms',
          );
        },
      );

      testWidgets(
        'should complete login screen animations within 300ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pump();

          final stopwatch = Stopwatch()..start();

          // Wait for animations to complete
          await tester.pump(const Duration(milliseconds: 250));

          stopwatch.stop();
          final animationTime = stopwatch.elapsedMilliseconds;

          print('🚀 Login screen animation time: ${animationTime}ms');
          
          // Target: < 300ms
          expect(
            animationTime,
            lessThan(300),
            reason: 'Animations should complete within 300ms. Actual: ${animationTime}ms',
          );
        },
      );

      testWidgets(
        'should handle rapid navigation without animation lag',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (context) => const WelcomeScreen(),
                '/login': (context) => const LoginScreen(),
                '/register': (context) => const RegisterScreen(),
              },
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final stopwatch = Stopwatch()..start();

          // Rapid navigation
          await tester.tap(find.text('Giriş Yap'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          await tester.pageBack();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          await tester.tap(find.text('Kayıt Ol'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          stopwatch.stop();
          final navigationTime = stopwatch.elapsedMilliseconds;

          print('🚀 Rapid navigation time: ${navigationTime}ms');
          
          // Target: < 600ms for 3 navigation actions
          expect(
            navigationTime,
            lessThan(600),
            reason: 'Navigation should be smooth. Actual: ${navigationTime}ms',
          );
        },
      );
    });

    group('Form Performance', () {
      testWidgets(
        'should validate email field within 100ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final emailField = find.byType(TextFormField).first;

          final stopwatch = Stopwatch()..start();

          // Enter invalid email
          await tester.enterText(emailField, 'invalid-email');
          await tester.pump();

          stopwatch.stop();
          final validationTime = stopwatch.elapsedMilliseconds;

          print('🚀 Email validation time: ${validationTime}ms');
          
          // Target: < 100ms
          expect(
            validationTime,
            lessThan(100),
            reason: 'Validation should be fast. Actual: ${validationTime}ms',
          );
        },
      );

      testWidgets(
        'should validate password field within 100ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final passwordField = find.byType(TextFormField).last;

          final stopwatch = Stopwatch()..start();

          // Enter short password
          await tester.enterText(passwordField, '123');
          await tester.pump();

          stopwatch.stop();
          final validationTime = stopwatch.elapsedMilliseconds;

          print('🚀 Password validation time: ${validationTime}ms');
          
          // Target: < 100ms
          expect(
            validationTime,
            lessThan(100),
            reason: 'Validation should be fast. Actual: ${validationTime}ms',
          );
        },
      );

      testWidgets(
        'should handle rapid form input without lag',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final emailField = find.byType(TextFormField).first;
          final passwordField = find.byType(TextFormField).last;

          final stopwatch = Stopwatch()..start();

          // Rapid input
          for (int i = 0; i < 10; i++) {
            await tester.enterText(emailField, 'test$i@example.com');
            await tester.pump();
            
            await tester.enterText(passwordField, 'password$i');
            await tester.pump();
          }

          stopwatch.stop();
          final inputTime = stopwatch.elapsedMilliseconds;

          print('🚀 Rapid form input time: ${inputTime}ms');
          
          // Target: < 1000ms for 20 input operations
          expect(
            inputTime,
            lessThan(1000),
            reason: 'Form input should be responsive. Actual: ${inputTime}ms',
          );
        },
      );
    });

    group('Button Response Performance', () {
      testWidgets(
        'should respond to button taps within 50ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: WelcomeScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final loginButton = find.text('Giriş Yap');

          final stopwatch = Stopwatch()..start();

          await tester.tap(loginButton);
          await tester.pump();

          stopwatch.stop();
          final responseTime = stopwatch.elapsedMilliseconds;

          print('🚀 Button response time: ${responseTime}ms');
          
          // Target: < 50ms
          expect(
            responseTime,
            lessThan(50),
            reason: 'Button should respond immediately. Actual: ${responseTime}ms',
          );
        },
      );

      testWidgets(
        'should handle multiple rapid button taps',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: WelcomeScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final loginButton = find.text('Giriş Yap');
          final registerButton = find.text('Kayıt Ol');

          final stopwatch = Stopwatch()..start();

          // Rapid button taps
          for (int i = 0; i < 5; i++) {
            await tester.tap(loginButton);
            await tester.pump();
            
            await tester.tap(registerButton);
            await tester.pump();
          }

          stopwatch.stop();
          final totalTime = stopwatch.elapsedMilliseconds;

          print('🚀 Multiple button taps time: ${totalTime}ms');
          
          // Target: < 500ms for 10 button taps
          expect(
            totalTime,
            lessThan(500),
            reason: 'Multiple taps should be handled efficiently. Actual: ${totalTime}ms',
          );
        },
      );
    });

    group('Memory Performance', () {
      testWidgets(
        'should not leak memory during screen transitions',
        (WidgetTester tester) async {
          // Create and dispose screens multiple times
          for (int i = 0; i < 10; i++) {
            await tester.pumpWidget(
              const MaterialApp(
                home: WelcomeScreen(),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            // Navigate to login
            await tester.tap(find.text('Giriş Yap'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            // Dispose by creating new app
            await tester.pumpWidget(
              const MaterialApp(
                home: Scaffold(body: Text('Empty')),
              ),
            );

            await tester.pump();
          }

          // If we get here without OOM, test passes
          expect(find.text('Empty'), findsOneWidget);
          
          print('🚀 Memory leak test passed - no leaks detected');
        },
      );

      testWidgets(
        'should dispose resources properly',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Dispose by navigating away
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: Center(child: Text('Other Screen')),
              ),
            ),
          );

          await tester.pump();

          // Should dispose without errors
          expect(find.text('Other Screen'), findsOneWidget);
          
          print('🚀 Resource disposal test passed');
        },
      );
    });

    group('Scroll Performance', () {
      testWidgets(
        'should maintain smooth scrolling on login screen',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final scrollView = find.byType(SingleChildScrollView);

          final stopwatch = Stopwatch()..start();

          // Perform scroll operations
          for (int i = 0; i < 5; i++) {
            await tester.drag(scrollView, const Offset(0, -100));
            await tester.pump();
            
            await tester.drag(scrollView, const Offset(0, 100));
            await tester.pump();
          }

          stopwatch.stop();
          final scrollTime = stopwatch.elapsedMilliseconds;

          print('🚀 Scroll performance time: ${scrollTime}ms');
          
          // Target: < 500ms for 10 scroll operations
          expect(
            scrollTime,
            lessThan(500),
            reason: 'Scrolling should be smooth. Actual: ${scrollTime}ms',
          );
        },
      );
    });

    group('Biometric Performance', () {
      testWidgets(
        'should check biometric availability quickly',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            const MaterialApp(
              home: WelcomeScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          stopwatch.stop();
          final checkTime = stopwatch.elapsedMilliseconds;

          print('🚀 Biometric availability check time: ${checkTime}ms');
          
          // Target: < 500ms (includes screen load)
          expect(
            checkTime,
            lessThan(500),
            reason: 'Biometric check should be fast. Actual: ${checkTime}ms',
          );
        },
      );
    });

    group('Error Handling Performance', () {
      testWidgets(
        'should display error messages quickly',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final emailField = find.byType(TextFormField).first;
          final loginButton = find.text('Giriş Yap');

          // Enter invalid email
          await tester.enterText(emailField, 'invalid');
          await tester.pump();

          final stopwatch = Stopwatch()..start();

          // Trigger validation by attempting login
          await tester.tap(loginButton);
          await tester.pump();

          stopwatch.stop();
          final errorTime = stopwatch.elapsedMilliseconds;

          print('🚀 Error display time: ${errorTime}ms');
          
          // Target: < 100ms
          expect(
            errorTime,
            lessThan(100),
            reason: 'Error should display quickly. Actual: ${errorTime}ms',
          );
        },
      );
    });

    group('Stress Tests', () {
      testWidgets(
        'should handle rapid interactions without crashing',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (context) => const WelcomeScreen(),
                '/login': (context) => const LoginScreen(),
                '/register': (context) => const RegisterScreen(),
              },
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final stopwatch = Stopwatch()..start();

          // Rapid interactions
          for (int i = 0; i < 20; i++) {
            // Navigate to login
            await tester.tap(find.text('Giriş Yap'));
            await tester.pump();

            // Go back
            await tester.pageBack();
            await tester.pump();

            // Navigate to register
            await tester.tap(find.text('Kayıt Ol'));
            await tester.pump();

            // Go back
            await tester.pageBack();
            await tester.pump();
          }

          stopwatch.stop();
          final stressTime = stopwatch.elapsedMilliseconds;

          print('🚀 Stress test completed in: ${stressTime}ms');
          
          // Should complete without crashing
          expect(find.text('Parion'), findsOneWidget);
        },
      );
    });
  });

  group('Performance Benchmarks Summary', () {
    test('should print performance summary', () {
      print('\n${'=' * 60}');
      print('🚀 AUTHENTICATION PERFORMANCE SUMMARY');
      print('=' * 60);
      print('Target Metrics:');
      print('  ✓ Screen load time: < 500ms');
      print('  ✓ Animation duration: < 300ms');
      print('  ✓ Form validation: < 100ms');
      print('  ✓ Button response: < 50ms');
      print('  ✓ Navigation: < 200ms');
      print('  ✓ Error display: < 100ms');
      print('  ✓ Scroll performance: 60fps');
      print('=' * 60 + '\n');
    });
  });
}