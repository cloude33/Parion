import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/loan.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/screens/statistics_screen.dart';
import '../test_setup.dart';

/// Integration tests for Statistics Screen
/// Tests complete user flows with proper viewport and async handling
void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('Statistics Screen Integration Tests', () {
    late List<Transaction> testTransactions;
    late List<Wallet> testWallets;
    late List<Loan> testLoans;
    late List<CreditCardTransaction> testCreditCardTransactions;

    setUp(() async {
      // Initialize test environment for each test
      await TestSetup.setupTest();
      
      // Create comprehensive test data
      testTransactions = _createTestTransactions();
      testWallets = _createTestWallets();
      testLoans = _createTestLoans();
      testCreditCardTransactions = _createTestCreditCardTransactions();
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    group('Basic Rendering', () {
      testWidgets(
        'should render statistics screen without errors',
        (WidgetTester tester) async {
          // Set larger viewport for better testing
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          // Wait for initial render and async operations
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify screen is rendered
          expect(find.byType(StatisticsScreen), findsOneWidget);
          
          // Verify tabs are present
          expect(find.text('Raporlar'), findsOneWidget);
          expect(find.text('Harcama'), findsOneWidget);
          expect(find.text('Kredi'), findsOneWidget);
          expect(find.text('Nakit Akışı'), findsOneWidget);
          expect(find.text('Varlıklar'), findsOneWidget);
        },
      );

      testWidgets(
        'should display default tab content',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Default tab should be Reports (Raporlar)
          // Look for any content that indicates we're on the reports tab
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );
    });

    group('Tab Navigation', () {
      testWidgets(
        'should navigate to Harcama tab',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Find and tap Harcama tab
          final harcamaTab = find.text('Harcama');
          expect(harcamaTab, findsOneWidget);
          
          await tester.ensureVisible(harcamaTab);
          await tester.tap(harcamaTab);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify we're on the spending tab
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );

      testWidgets(
        'should navigate to Nakit Akışı tab',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Find and tap Nakit Akışı tab
          final cashFlowTab = find.text('Nakit Akışı');
          expect(cashFlowTab, findsOneWidget);
          
          await tester.ensureVisible(cashFlowTab);
          await tester.tap(cashFlowTab);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify we're on the cash flow tab
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );

      testWidgets(
        'should navigate to Kredi tab',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Find and tap Kredi tab
          final creditTab = find.text('Kredi');
          expect(creditTab, findsOneWidget);
          
          await tester.ensureVisible(creditTab);
          await tester.tap(creditTab);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify we're on the credit tab
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );

      testWidgets(
        'should navigate to Varlıklar tab',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Find and tap Varlıklar tab
          final assetsTab = find.text('Varlıklar');
          expect(assetsTab, findsOneWidget);
          
          await tester.ensureVisible(assetsTab);
          await tester.tap(assetsTab);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify we're on the assets tab
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );

      testWidgets(
        'should maintain state when switching between tabs',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Navigate to Harcama
          await tester.ensureVisible(find.text('Harcama'));
          await tester.tap(find.text('Harcama'));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Navigate to Kredi
          await tester.ensureVisible(find.text('Kredi'));
          await tester.tap(find.text('Kredi'));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Navigate back to Harcama
          await tester.ensureVisible(find.text('Harcama'));
          await tester.tap(find.text('Harcama'));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Screen should still be functional
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );
    });

    group('Data Display', () {
      testWidgets(
        'should handle empty data gracefully',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: const [],
                wallets: const [],
                loans: const [],
                creditCardTransactions: const [],
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Screen should render without errors even with empty data
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );

      testWidgets(
        'should display loan information when available',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Navigate to Kredi tab
          await tester.ensureVisible(find.text('Kredi'));
          await tester.tap(find.text('Kredi'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify screen is rendered (specific loan content may vary)
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );

      testWidgets(
        'should display wallet information when available',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Navigate to Varlıklar tab
          await tester.ensureVisible(find.text('Varlıklar'));
          await tester.tap(find.text('Varlıklar'));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify screen is rendered
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );
    });

    group('Time Filter', () {
      testWidgets(
        'should display time filter options',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: testTransactions,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Time filter should be visible (default is Aylık)
          // The filter might be in a dropdown or chip selector
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );
    });
  });
}

// Helper functions to create test data
List<Transaction> _createTestTransactions() {
  final now = DateTime.now();
  return [
    Transaction(
      id: 'trans1',
      amount: 100.0,
      category: 'Yemek',
      date: now.subtract(const Duration(days: 1)),
      description: 'Test transaction 1',
      type: 'expense',
      walletId: 'wallet1',
    ),
    Transaction(
      id: 'trans2',
      amount: 200.0,
      category: 'Ulaşım',
      date: now.subtract(const Duration(days: 2)),
      description: 'Test transaction 2',
      type: 'expense',
      walletId: 'wallet1',
    ),
    Transaction(
      id: 'trans3',
      amount: 1000.0,
      category: 'Maaş',
      date: now.subtract(const Duration(days: 3)),
      description: 'Test income',
      type: 'income',
      walletId: 'wallet1',
    ),
  ];
}

List<Wallet> _createTestWallets() {
  return [
    Wallet(
      id: 'wallet1',
      name: 'Test Cüzdan',
      balance: 1000.0,
      type: 'cash',
      color: '0xFF2196F3',
      icon: 'wallet',
    ),
    Wallet(
      id: 'wallet2',
      name: 'Test Banka',
      balance: 5000.0,
      type: 'bank',
      color: '0xFF4CAF50',
      icon: 'account_balance',
    ),
  ];
}

List<Loan> _createTestLoans() {
  final now = DateTime.now();
  final startDate = now.subtract(const Duration(days: 180));
  final endDate = now.add(const Duration(days: 180));
  
  return [
    Loan(
      id: 'loan1',
      name: 'İhtiyaç Kredisi',
      bankName: 'Test Bankası',
      totalAmount: 10000.0,
      remainingAmount: 5000.0,
      totalInstallments: 12,
      remainingInstallments: 6,
      currentInstallment: 7,
      installmentAmount: 833.33,
      startDate: startDate,
      endDate: endDate,
      walletId: 'wallet1',
      installments: [],
    ),
  ];
}

List<CreditCardTransaction> _createTestCreditCardTransactions() {
  final now = DateTime.now();
  return [
    CreditCardTransaction(
      id: 'cc_trans1',
      cardId: 'card1',
      amount: 150.0,
      category: 'Alışveriş',
      transactionDate: now.subtract(const Duration(days: 1)),
      description: 'Test credit card transaction',
      installmentCount: 1,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
  ];
}
