import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:parion/services/auth/interfaces/auth_orchestrator_interface.dart';
import 'package:parion/services/auth/interfaces/biometric_auth_interface.dart';
import 'package:parion/services/auth/interfaces/session_manager_interface.dart';
import 'package:parion/services/auth/interfaces/social_login_interface.dart';
import 'package:parion/services/auth/interfaces/security_controller_interface.dart';
import 'package:parion/services/auth/interfaces/data_sync_interface.dart';
import 'package:parion/models/security/security_models.dart';
import 'package:parion/screens/welcome_screen.dart';
import 'package:parion/screens/login_screen.dart';
import 'package:parion/screens/register_screen.dart';

import 'auth_flow_integration_test.mocks.dart';
import '../test_setup.dart';

@GenerateMocks([
  IAuthOrchestrator,
  IBiometricAuthService,
  ISessionManager,
  ISocialLoginService,
  ISecurityController,
  DataSyncInterface,
])
void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('Authentication Flow Integration Tests', () {
    late MockIAuthOrchestrator mockAuthOrchestrator;
    late MockIBiometricAuthService mockBiometricService;
    late MockISessionManager mockSessionManager;
    late MockISocialLoginService mockSocialLoginService;
    late MockISecurityController mockSecurityController;
    late MockDataSyncInterface mockDataSyncService;

    setUp(() async {
      // Reset GetIt
      await GetIt.instance.reset();

      // Create mocks
      mockAuthOrchestrator = MockIAuthOrchestrator();
      mockBiometricService = MockIBiometricAuthService();
      mockSessionManager = MockISessionManager();
      mockSocialLoginService = MockISocialLoginService();
      mockSecurityController = MockISecurityController();
      mockDataSyncService = MockDataSyncInterface();

      // Register mocks in GetIt
      GetIt.instance.registerSingleton<IAuthOrchestrator>(mockAuthOrchestrator);
      GetIt.instance.registerSingleton<IBiometricAuthService>(mockBiometricService);
      GetIt.instance.registerSingleton<ISessionManager>(mockSessionManager);
      GetIt.instance.registerSingleton<ISocialLoginService>(mockSocialLoginService);
      GetIt.instance.registerSingleton<ISecurityController>(mockSecurityController);
      GetIt.instance.registerSingleton<DataSyncInterface>(mockDataSyncService);

      // Setup default mock behaviors
      when(mockAuthOrchestrator.initialize()).thenAnswer((_) async {});
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockAuthOrchestrator.authStateStream).thenAnswer(
        (_) => Stream.value(AuthState.unauthenticated()),
      );
      when(mockBiometricService.initialize()).thenAnswer((_) async {});
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => true);
      when(mockSessionManager.initialize()).thenAnswer((_) async {});
      when(mockSocialLoginService.initialize()).thenAnswer((_) async {});
      when(mockSecurityController.initialize()).thenAnswer((_) async {});
      when(mockDataSyncService.initialize()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    testWidgets('Complete email/password authentication flow', (WidgetTester tester) async {
      // Setup: User is not authenticated, biometric available
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => true);

      // Build the app
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      // Verify welcome screen is displayed
      expect(find.text('Parion'), findsOneWidget);
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('Kayıt Ol'), findsOneWidget);

      // Tap login button
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Verify navigation to login screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Hoş Geldiniz'), findsOneWidget);

      // Enter email and password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      // Setup successful authentication
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        argThat(isA<Map<String, dynamic>>()),
      )).thenAnswer((_) async => AuthResult.success(
        method: AuthMethod.emailPassword,
        metadata: {'userId': 'test-user-id'},
      ));

      when(mockAuthOrchestrator.authStateStream).thenAnswer(
        (_) => Stream.value(AuthState.authenticated(
          sessionId: 'test-session',
          authMethod: AuthMethod.emailPassword,
        )),
      );

      // Tap login button
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();

      // Verify authentication was called
      verify(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        argThat(predicate<Map<String, dynamic>>((map) => 
          map.containsKey('email') && map['email'] == 'test@example.com'
        )),
      )).called(1);

      // Verify navigation to home screen would occur
      // Note: In a real integration test, we'd verify the actual navigation
      // but for unit testing, we verify the auth orchestrator was called correctly
    });

    testWidgets('Biometric authentication flow', (WidgetTester tester) async {
      // Setup: User is not authenticated, biometric available
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => true);

      // Build the app
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      // Verify biometric button is displayed
      expect(find.text('Biyometrik Giriş'), findsOneWidget);

      // Setup successful biometric authentication
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.biometric,
        argThat(isA<Map<String, dynamic>>()),
      )).thenAnswer((_) async => AuthResult.success(
        method: AuthMethod.biometric,
        metadata: {'userId': 'test-user-id'},
      ));

      when(mockAuthOrchestrator.authStateStream).thenAnswer(
        (_) => Stream.value(AuthState.authenticated(
          sessionId: 'test-session',
          authMethod: AuthMethod.biometric,
        )),
      );

      // Tap biometric button
      await tester.tap(find.text('Biyometrik Giriş'));
      await tester.pumpAndSettle();

      // Verify biometric authentication was called
      verify(mockAuthOrchestrator.authenticate(
        AuthMethod.biometric,
        argThat(predicate<Map<String, dynamic>>((map) => 
          map.containsKey('reason') && map['reason'].toString().contains('kimliğinizi doğrulayın')
        )),
      )).called(1);
    });

    testWidgets('Social login flow (Google)', (WidgetTester tester) async {
      // Setup: User is not authenticated
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => false);

      // Build the app and navigate to login
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Verify login screen is displayed
      expect(find.byType(LoginScreen), findsOneWidget);

      // Setup successful Google authentication
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.social,
        argThat(isA<Map<String, dynamic>>()),
      )).thenAnswer((_) async => AuthResult.success(
        method: AuthMethod.social,
        metadata: {
          'provider': 'google',
          'userId': 'test-user-id',
          'email': 'test@gmail.com',
        },
      ));

      when(mockAuthOrchestrator.authStateStream).thenAnswer(
        (_) => Stream.value(AuthState.authenticated(
          sessionId: 'test-session',
          authMethod: AuthMethod.social,
        )),
      );

      // Tap Google login button
      await tester.tap(find.text('Google'));
      await tester.pumpAndSettle();

      // Verify Google authentication was called
      verify(mockAuthOrchestrator.authenticate(
        AuthMethod.social,
        argThat(predicate<Map<String, dynamic>>((map) => 
          map.containsKey('provider') && map['provider'] == 'google'
        )),
      )).called(1);
    });

    testWidgets('Registration flow', (WidgetTester tester) async {
      // Setup: User is not authenticated
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => false);

      // Build the app
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      // Tap register button
      await tester.tap(find.text('Kayıt Ol'));
      await tester.pumpAndSettle();

      // Verify navigation to register screen
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Hesap Oluştur'), findsOneWidget);

      // Fill registration form
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), 'Password123!');
      await tester.enterText(textFields.at(3), 'Password123!');
      await tester.pumpAndSettle();

      // Accept terms and conditions
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Setup successful registration
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        argThat(isA<Map<String, dynamic>>()),
      )).thenAnswer((_) async => AuthResult.success(
        method: AuthMethod.emailPassword,
        metadata: {
          'userId': 'new-user-id',
          'isNewUser': true,
        },
      ));

      when(mockDataSyncService.syncAllUserData(argThat(isA<String>()))).thenAnswer((_) async => SyncResult.success());

      // Tap register button
      await tester.tap(find.text('Hesap Oluştur'));
      await tester.pumpAndSettle();

      // Verify registration was called
      verify(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        argThat(allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map['email'] == 'test@example.com' &&
            map['displayName'] == 'Test User' &&
            map['isSignUp'] == true
          ),
        ])),
      )).called(1);

      // Verify data sync was called
      verify(mockDataSyncService.syncAllUserData(argThat(isA<String>()))).called(1);
    });

    testWidgets('Error handling during authentication', (WidgetTester tester) async {
      // Setup: User is not authenticated
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => false);

      // Build the app and navigate to login
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await tester.enterText(find.byType(TextFormField).first, 'invalid@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
      await tester.pumpAndSettle();

      // Setup authentication failure
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        argThat(isA<Map<String, dynamic>>()),
      )).thenAnswer((_) async => AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: 'E-posta veya şifre hatalı',
      ));

      // Tap login button
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('E-posta veya şifre hatalı'), findsOneWidget);

      // Verify authentication was attempted
      verify(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        argThat(isA<Map<String, dynamic>>()),
      )).called(1);
    });

    testWidgets('Navigation between screens', (WidgetTester tester) async {
      // Setup: User is not authenticated
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => false);

      // Build the app
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      // Verify welcome screen
      expect(find.byType(WelcomeScreen), findsOneWidget);

      // Navigate to login
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Navigate to register from login
      await tester.tap(find.text('Kayıt olun'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      // Navigate back to login from register
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Navigate back to welcome
      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Loading states during authentication', (WidgetTester tester) async {
      // Setup: User is not authenticated
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => true);

      // Build the app and navigate to login
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      // Setup delayed authentication response
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        argThat(isA<Map<String, dynamic>>()),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return AuthResult.success(
          method: AuthMethod.emailPassword,
          metadata: {'userId': 'test-user-id'},
        );
      });

      // Tap login button
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pump(); // Don't settle, so we can see loading state

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for authentication to complete
      await tester.pumpAndSettle();

      // Verify loading indicator is gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Biometric unavailable scenario', (WidgetTester tester) async {
      // Setup: User is not authenticated, biometric not available
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => false);
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => false);

      // Build the app
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      // Verify biometric button is not displayed
      expect(find.text('Biyometrik Giriş'), findsNothing);

      // Verify other buttons are still available
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('Kayıt Ol'), findsOneWidget);
    });

    testWidgets('Already authenticated user flow', (WidgetTester tester) async {
      // Setup: User is already authenticated
      when(mockAuthOrchestrator.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthOrchestrator.authStateStream).thenAnswer(
        (_) => Stream.value(AuthState.authenticated(
          sessionId: 'existing-session',
          authMethod: AuthMethod.emailPassword,
        )),
      );

      // Build the app
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pumpAndSettle();

      // Verify that authentication check was called
      verify(mockAuthOrchestrator.isAuthenticated()).called(1);

      // In a real app, this would navigate directly to home screen
      // For this test, we verify the authentication check occurred
    });
  });
}