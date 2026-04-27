import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parion/screens/welcome_screen.dart';
import 'package:parion/screens/login_screen.dart';
import 'package:parion/screens/register_screen.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('Simple Authentication Flow Integration Tests', () {
    testWidgets('Welcome screen displays correctly', (WidgetTester tester) async {
      // Build the app without full DI setup
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pump();

      // Verify welcome screen elements are displayed
      expect(find.text('Parion'), findsOneWidget);
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('Kayıt Ol'), findsOneWidget);
    });

    testWidgets('Login screen displays correctly', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      // Verify login screen elements are displayed
      expect(find.text('Hoş Geldiniz'), findsOneWidget);
      expect(find.text('E-posta'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);
      expect(find.text('Giriş Yap'), findsWidgets);
    });

    testWidgets('Register screen displays correctly', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pump();

      // Verify register screen elements are displayed
      expect(find.text('Hesap Oluştur'), findsOneWidget);
      expect(find.text('Ad Soyad'), findsOneWidget);
      expect(find.text('E-posta'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);
    });

    testWidgets('Login screen has social login options', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      // Verify social login buttons are displayed
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('Register screen has terms checkbox', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pump();

      // Verify terms and conditions checkbox is displayed
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.textContaining('Kullanım Koşulları'), findsOneWidget);
    });

    testWidgets('Form fields are interactive', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      // Test text input
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.pump();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Navigation between screens works', (WidgetTester tester) async {
      // Build app with navigation
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
        },
      ));
      await tester.pump();

      // Test navigation to login
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);

      // Test navigation to register
      await tester.tap(find.text('Kayıt Ol'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('UI components render without errors', (WidgetTester tester) async {
      // Test that all screens can be rendered without crashing
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pump();
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });
}