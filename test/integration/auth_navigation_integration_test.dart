import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

import 'package:parion/screens/welcome_screen.dart';
import 'package:parion/screens/login_screen.dart';
import 'package:parion/screens/register_screen.dart';
import 'package:parion/screens/home_screen.dart';
import 'package:parion/screens/security/biometric_setup_screen.dart';
import 'package:parion/utils/auth_navigation.dart';
import 'package:parion/services/auth/interfaces/auth_orchestrator_interface.dart';
import 'package:parion/services/auth/interfaces/biometric_auth_interface.dart';
import 'package:parion/models/security/security_models.dart';

import 'auth_flow_integration_test.mocks.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('Authentication Navigation Integration Tests', () {
    late MockIAuthOrchestrator mockAuthOrchestrator;
    late MockIBiometricAuthService mockBiometricService;

    setUp(() async {
      // Reset GetIt
      await GetIt.instance.reset();

      // Create mocks
      mockAuthOrchestrator = MockIAuthOrchestrator();
      mockBiometricService = MockIBiometricAuthService();

      // Register mocks in GetIt
      GetIt.instance.registerSingleton<IAuthOrchestrator>(mockAuthOrchestrator);
      GetIt.instance.registerSingleton<IBiometricAuthService>(mockBiometricService);

      // Setup default mock behaviors
      when(mockAuthOrchestrator.initialize()).thenAnswer((_) async {});
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockAuthOrchestrator.authStateStream).thenAnswer(
        (_) => Stream.value(AuthState.unauthenticated()),
      );
      when(mockBiometricService.initialize()).thenAnswer((_) async {});
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => false);
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    testWidgets('Navigation flow: Welcome -> Login -> Register -> Login', (WidgetTester tester) async {
      // Build app with welcome screen
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ));
      await tester.pumpAndSettle();

      // Verify welcome screen
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Parion'), findsOneWidget);

      // Navigate to login
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Verify login screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Hoş Geldiniz'), findsOneWidget);

      // Navigate to register
      await tester.tap(find.text('Kayıt olun'));
      await tester.pumpAndSettle();

      // Verify register screen
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Hesap Oluştur'), findsOneWidget);

      // Navigate back to login
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();

      // Verify back to login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Navigation transitions are smooth', (WidgetTester tester) async {
      // Build app with welcome screen
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      // Navigate to login and verify transition
      await tester.tap(find.text('Giriş Yap'));
      
      // Pump a few frames to see transition
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      
      // Complete transition
      await tester.pumpAndSettle();

      // Verify we're on login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Back navigation works correctly', (WidgetTester tester) async {
      // Build app with navigation stack
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Verify we can go back
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      // Go back to welcome
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back on welcome screen
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('AuthNavigation utility methods work correctly', (WidgetTester tester) async {
      late BuildContext testContext;

      // Build a test widget to get context
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            testContext = context;
            return const Scaffold(
              body: Text('Test'),
            );
          },
        ),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ));
      await tester.pumpAndSettle();

      // Test navigation to login
      AuthNavigation.toLogin(testContext);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Test navigation to register
      AuthNavigation.toRegister(testContext);
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      // Test back navigation
      AuthNavigation.back(testContext);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Extension methods work correctly', (WidgetTester tester) async {
      late BuildContext testContext;

      // Build a test widget to get context
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            testContext = context;
            return const Scaffold(
              body: Text('Test'),
            );
          },
        ),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ));
      await tester.pumpAndSettle();

      // Test extension methods
      testContext.toLogin();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      testContext.toRegister();
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      testContext.goBack();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Biometric setup navigation works', (WidgetTester tester) async {
      late BuildContext testContext;

      // Build a test widget to get context
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            testContext = context;
            return const Scaffold(
              body: Text('Test'),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Test navigation to biometric setup
      final future = AuthNavigation.toBiometricSetup(testContext);
      await tester.pumpAndSettle();
      
      // Verify biometric setup screen is shown
      expect(find.byType(BiometricSetupScreen), findsOneWidget);

      // Simulate completing setup
      Navigator.of(testContext).pop(true);
      await tester.pumpAndSettle();

      // Verify the future completes with the result
      final result = await future;
      expect(result, isTrue);
    });

    testWidgets('Navigation preserves state correctly', (WidgetTester tester) async {
      // Build app with welcome screen
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Enter some text in login form
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.pumpAndSettle();

      // Navigate to register
      await tester.tap(find.text('Kayıt olun'));
      await tester.pumpAndSettle();

      // Navigate back to login
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();

      // Verify the text is still there (state preserved)
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Error recovery navigation works', (WidgetTester tester) async {
      // Setup authentication failure
      when(mockAuthOrchestrator.authenticate(any, any))
          .thenAnswer((_) async => AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: 'Network error',
      ));

      // Build app and navigate to login
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Try to login with error
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.text('Network error'), findsOneWidget);

      // User can still navigate away
      await tester.tap(find.text('Kayıt olun'));
      await tester.pumpAndSettle();

      // Verify navigation worked despite error
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });
}