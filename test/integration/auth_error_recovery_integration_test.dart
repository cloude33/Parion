import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

import 'package:parion/screens/login_screen.dart';
import 'package:parion/screens/welcome_screen.dart';
import 'package:parion/services/auth/interfaces/auth_orchestrator_interface.dart';
import 'package:parion/services/auth/interfaces/biometric_auth_interface.dart';
import 'package:parion/services/auth/interfaces/data_sync_interface.dart';
import 'package:parion/models/security/security_models.dart';
import 'package:parion/widgets/auth_error_widget.dart';

import 'auth_flow_integration_test.mocks.dart';

void main() {
  group('Authentication Error Recovery Integration Tests', () {
    late MockIAuthOrchestrator mockAuthOrchestrator;
    late MockIBiometricAuthService mockBiometricService;
    late MockDataSyncInterface mockDataSyncService;

    setUp(() async {
      // Reset GetIt
      await GetIt.instance.reset();

      // Create mocks
      mockAuthOrchestrator = MockIAuthOrchestrator();
      mockBiometricService = MockIBiometricAuthService();
      mockDataSyncService = MockDataSyncInterface();

      // Register mocks in GetIt
      GetIt.instance.registerSingleton<IAuthOrchestrator>(mockAuthOrchestrator);
      GetIt.instance.registerSingleton<IBiometricAuthService>(mockBiometricService);
      GetIt.instance.registerSingleton<DataSyncInterface>(mockDataSyncService);

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

    testWidgets('Network error recovery in login flow', (WidgetTester tester) async {
      // Build app and navigate to login
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      // Setup network error
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
      )).thenAnswer((_) async => AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: 'Bağlantı sorunu yaşanıyor. Lütfen internet bağlantınızı kontrol edin.',
      ));

      // Attempt login
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Bağlantı sorunu yaşanıyor. Lütfen internet bağlantınızı kontrol edin.'), findsOneWidget);

      // Setup successful retry
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
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

      // Retry login
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();

      // Verify success
      verify(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
      )).called(2); // First failed, second succeeded
    });

    testWidgets('Invalid credentials error recovery', (WidgetTester tester) async {
      // Build app and navigate to login
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await tester.enterText(find.byType(TextFormField).first, 'wrong@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
      await tester.pumpAndSettle();

      // Setup invalid credentials error
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
      )).thenAnswer((_) async => AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: 'E-posta veya şifre hatalı. Lütfen tekrar deneyin.',
      ));

      // Attempt login
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('E-posta veya şifre hatalı. Lütfen tekrar deneyin.'), findsOneWidget);

      // Clear fields and enter correct credentials
      await tester.enterText(find.byType(TextFormField).first, 'correct@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'correctpassword');
      await tester.pumpAndSettle();

      // Setup successful authentication
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
      )).thenAnswer((_) async => AuthResult.success(
        method: AuthMethod.emailPassword,
        metadata: {'userId': 'test-user-id'},
      ));

      // Retry with correct credentials
      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();

      // Verify no error message
      expect(find.text('E-posta veya şifre hatalı. Lütfen tekrar deneyin.'), findsNothing);
    });

    testWidgets('Biometric authentication failure recovery', (WidgetTester tester) async {
      // Setup biometric available
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => true);

      // Build app
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify biometric button is available
      expect(find.text('Biyometrik Giriş'), findsOneWidget);

      // Setup biometric failure
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.biometric,
        any,
      )).thenAnswer((_) async => AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: 'Biyometrik doğrulama başarısız. Lütfen tekrar deneyin.',
      ));

      // Attempt biometric authentication
      await tester.tap(find.text('Biyometrik Giriş'));
      await tester.pumpAndSettle();

      // Verify error is displayed
      expect(find.byType(AuthErrorWidget), findsOneWidget);

      // User can still use regular login
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Verify navigation to login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Registration error recovery', (WidgetTester tester) async {
      // Build app and navigate to register
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kayıt Ol'));
      await tester.pumpAndSettle();

      // Fill registration form
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'existing@example.com');
      await tester.enterText(textFields.at(2), 'Password123!');
      await tester.enterText(textFields.at(3), 'Password123!');
      await tester.pumpAndSettle();

      // Accept terms
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Setup email already exists error
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
      )).thenAnswer((_) async => AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: 'Bu e-posta adresi zaten kullanımda.',
      ));

      // Attempt registration
      await tester.tap(find.text('Hesap Oluştur'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Bu e-posta adresi zaten kullanımda.'), findsOneWidget);

      // Change email to a new one
      await tester.enterText(textFields.at(1), 'new@example.com');
      await tester.pumpAndSettle();

      // Setup successful registration
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
      )).thenAnswer((_) async => AuthResult.success(
        method: AuthMethod.emailPassword,
        metadata: {'userId': 'new-user-id', 'isNewUser': true},
      ));

      when(mockDataSyncService.syncUserProfile(any)).thenAnswer((_) async => SyncResult.success());

      // Retry registration
      await tester.tap(find.text('Hesap Oluştur'));
      await tester.pumpAndSettle();

      // Verify success
      verify(mockDataSyncService.syncUserProfile(any)).called(1);
    });

    testWidgets('Service initialization error recovery', (WidgetTester tester) async {
      // Setup service initialization failure
      when(mockBiometricService.isAvailable()).thenThrow(Exception('Service initialization failed'));

      // Build app
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify error is handled gracefully
      expect(find.byType(AuthErrorWidget), findsOneWidget);
      expect(find.text('Kimlik doğrulama servisleri başlatılamadı'), findsOneWidget);

      // Verify retry button is available
      expect(find.text('Tekrar Dene'), findsOneWidget);

      // Setup successful retry
      when(mockBiometricService.isAvailable()).thenAnswer((_) async => true);

      // Tap retry
      await tester.tap(find.text('Tekrar Dene'));
      await tester.pumpAndSettle();

      // Verify error is cleared and biometric is available
      expect(find.byType(AuthErrorWidget), findsNothing);
      expect(find.text('Biyometrik Giriş'), findsOneWidget);
    });

    testWidgets('Multiple consecutive errors are handled', (WidgetTester tester) async {
      // Build app and navigate to login
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      // First error: Network
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
      )).thenAnswer((_) async => AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: 'Network error',
      ));

      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();
      expect(find.text('Network error'), findsOneWidget);

      // Second error: Invalid credentials
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
      )).thenAnswer((_) async => AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: 'Invalid credentials',
      ));

      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();
      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.text('Network error'), findsNothing); // Previous error cleared

      // Third attempt: Success
      when(mockAuthOrchestrator.authenticate(
        AuthMethod.emailPassword,
        any,
      )).thenAnswer((_) async => AuthResult.success(
        method: AuthMethod.emailPassword,
        metadata: {'userId': 'test-user-id'},
      ));

      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();
      expect(find.text('Invalid credentials'), findsNothing); // Error cleared on success
    });

    testWidgets('Error dismissal works correctly', (WidgetTester tester) async {
      // Setup service initialization failure
      when(mockBiometricService.isAvailable()).thenThrow(Exception('Service error'));

      // Build app
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.byType(AuthErrorWidget), findsOneWidget);

      // Find and tap dismiss button
      final dismissButton = find.byIcon(Icons.close);
      expect(dismissButton, findsOneWidget);
      
      await tester.tap(dismissButton);
      await tester.pumpAndSettle();

      // Verify error is dismissed
      expect(find.byType(AuthErrorWidget), findsNothing);

      // Verify app is still functional
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('Kayıt Ol'), findsOneWidget);
    });

    testWidgets('Password reset error recovery', (WidgetTester tester) async {
      // Build app and navigate to login
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Tap forgot password
      await tester.tap(find.text('Şifremi Unuttum'));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byType(TextField), 'invalid-email');
      await tester.pumpAndSettle();

      // Setup password reset failure
      when(mockAuthOrchestrator.sendPasswordResetEmail(any))
          .thenAnswer((_) async => AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: 'Geçersiz e-posta adresi',
      ));

      // Attempt password reset
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      // Verify error is shown in snackbar
      expect(find.text('Geçerli bir e-posta adresi girin'), findsOneWidget);

      // Enter valid email
      await tester.enterText(find.byType(TextField), 'valid@example.com');
      await tester.pumpAndSettle();

      // Setup successful password reset
      when(mockAuthOrchestrator.sendPasswordResetEmail(any))
          .thenAnswer((_) async => AuthResult.success(
        method: AuthMethod.emailPassword,
        metadata: {'email': 'valid@example.com'},
      ));

      // Retry password reset
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.textContaining('Şifre sıfırlama bağlantısı'), findsOneWidget);
    });
  });
}