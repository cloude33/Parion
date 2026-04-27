import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/widgets/statistics/spending_tab.dart';
import 'package:parion/widgets/statistics/statistics_empty_state.dart';
import 'package:parion/services/statistics_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/models/cash_flow_data.dart';
import 'package:parion/models/asset_analysis.dart';
import 'package:parion/models/credit_analysis.dart';
import 'package:parion/models/transaction.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import '../test_setup.dart';

class FakeStatisticsService extends Fake implements StatisticsService {
  @override
  Future<SpendingAnalysis> analyzeSpending({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categories,
    Map<String, double>? budgets,
  }) async => SpendingAnalysis(
    totalSpending: 0,
    categoryBreakdown: {},
    paymentMethodBreakdown: {},
    categoryTrends: [],
    budgetComparisons: {},
    topCategory: '',
    topCategoryAmount: 0,
    mostSpendingDay: DayOfWeek.monday,
    mostSpendingHour: 0,
    dailySpending: {},
    hourlySpending: {},
  );

  @override
  Future<AssetAnalysis> analyzeAssets() async => AssetAnalysis(
    totalAssets: 0,
    totalLiabilities: 0,
    netWorth: 0,
    liquidityRatio: 0,
    assetBreakdown: {},
    netWorthTrend: [],
    cashAndEquivalents: 0,
    bankAccounts: 0,
    positiveKmhBalances: 0,
    investments: 0,
    healthScore: FinancialHealthScore(
      liquidityScore: 0,
      debtManagementScore: 0,
      savingsScore: 0,
      investmentScore: 0,
      overallScore: 0,
      recommendations: [],
    ),
  );

  @override
  Future<CreditAnalysis> analyzeCreditAndKmh() async => CreditAnalysis(
    totalCreditCardDebt: 0,
    totalCreditLimit: 0,
    creditUtilization: 0,
    creditCards: [],
    totalKmhDebt: 0,
    totalKmhLimit: 0,
    kmhUtilization: 0,
    kmhAccounts: [],
    dailyInterest: 0,
    monthlyInterest: 0,
    annualInterest: 0,
    totalDebt: 0,
    debtTrend: [],
  );

  @override
  Future<CashFlowData> calculateCashFlow({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String? category,
    bool includePreviousPeriod = false,
  }) async => CashFlowData(
    totalIncome: 0,
    totalExpense: 0,
    netCashFlow: 0,
    averageDaily: 0,
    averageMonthly: 0,
    monthlyData: [],
    trend: TrendDirection.stable,
  );
}

/// Fake DataService that returns configurable transactions
class FakeDataService extends Fake implements DataService {
  final List<Transaction> _transactions;

  FakeDataService({List<Transaction>? transactions})
      : _transactions = transactions ?? [];

  @override
  Future<List<Transaction>> getTransactions() async => _transactions;
}

/// Helper to create a test Transaction
Transaction _makeTransaction({
  required String id,
  required String type,
  required double amount,
  required String category,
  required DateTime date,
}) {
  return Transaction(
    id: id,
    type: type,
    amount: amount,
    description: 'Test',
    category: category,
    walletId: 'wallet1',
    date: date,
  );
}

void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('SpendingTab Widget Tests', () {
    setUp(() async {
      await TestSetup.setupTest();
      GetIt.I.allowReassignment = true;
      GetIt.I.registerSingleton<StatisticsService>(FakeStatisticsService());
      GetIt.I.registerSingleton<DataService>(FakeDataService());
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should complete loading and show content', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );

      // Wait for the widget to finish loading
      await tester.pumpAndSettle();

      // Assert - Widget should complete loading and show some content
      // The loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
      
      // Should have the SpendingTab widget
      expect(find.byType(SpendingTab), findsOneWidget);
    });

    testWidgets('should rebuild when date range changes', (WidgetTester tester) async {
      // Arrange
      final startDate1 = DateTime(2024, 1, 1);
      final endDate1 = DateTime(2024, 1, 31);
      final startDate2 = DateTime(2024, 2, 1);
      final endDate2 = DateTime(2024, 2, 29);

      // Act - First render
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              key: const ValueKey('tab1'),
              startDate: startDate1,
              endDate: endDate1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Update with new dates
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              key: const ValueKey('tab2'),
              startDate: startDate2,
              endDate: endDate2,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert - Widget should rebuild with new key
      expect(find.byKey(const ValueKey('tab2')), findsOneWidget);
    });

    testWidgets('should accept optional categories filter', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final categories = ['Market', 'Restoran'];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
              categories: categories,
            ),
          ),
        ),
      );

      // Assert - Widget should render without errors
      expect(find.byType(SpendingTab), findsOneWidget);
    });

    testWidgets('should accept optional budgets parameter', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final budgets = {
        'Market': 1000.0,
        'Restoran': 500.0,
      };

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
              budgets: budgets,
            ),
          ),
        ),
      );

      // Assert - Widget should render without errors
      expect(find.byType(SpendingTab), findsOneWidget);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Widget should render successfully
      expect(find.byType(SpendingTab), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // Gereksinim 7.8: Yetersiz veri (< 10 işlem) uyarı mesajı
    testWidgets('should show insufficient data warning when fewer than 10 transactions', (WidgetTester tester) async {
      // Arrange: 5 transactions (< 10)
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final fewTransactions = List.generate(
        5,
        (i) => _makeTransaction(
          id: 'tx$i',
          type: 'expense',
          amount: 100.0,
          category: 'Market',
          date: DateTime(2024, 1, i + 1),
        ),
      );
      GetIt.I.allowReassignment = true;
      GetIt.I.registerSingleton<DataService>(
        FakeDataService(transactions: fewTransactions),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: warning message is visible
      expect(
        find.textContaining('Yeterli veri bulunmamaktadır'),
        findsOneWidget,
      );
    });

    // Gereksinim 7.8: 10+ işlem varsa uyarı gösterilmemeli
    testWidgets('should NOT show insufficient data warning when 10 or more transactions', (WidgetTester tester) async {
      // Arrange: 10 transactions
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final enoughTransactions = List.generate(
        10,
        (i) => _makeTransaction(
          id: 'tx$i',
          type: 'expense',
          amount: 100.0,
          category: 'Market',
          date: DateTime(2024, 1, i + 1),
        ),
      );
      GetIt.I.allowReassignment = true;
      GetIt.I.registerSingleton<DataService>(
        FakeDataService(transactions: enoughTransactions),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: no warning
      expect(
        find.textContaining('Yeterli veri bulunmamaktadır'),
        findsNothing,
      );
    });

    // Gereksinim 8.6: Gelir yoksa StatisticsEmptyState gösterilmeli
    testWidgets('should show StatisticsEmptyState for income sources when no income transactions', (WidgetTester tester) async {
      // Arrange: only expense transactions, no income
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final expenseOnly = List.generate(
        3,
        (i) => _makeTransaction(
          id: 'tx$i',
          type: 'expense',
          amount: 200.0,
          category: 'Market',
          date: DateTime(2024, 1, i + 1),
        ),
      );
      GetIt.I.allowReassignment = true;
      GetIt.I.registerSingleton<DataService>(
        FakeDataService(transactions: expenseOnly),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpendingTab(
                startDate: startDate,
                endDate: endDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: StatisticsEmptyState is shown for income sources
      expect(find.byType(StatisticsEmptyState), findsOneWidget);
    });
  });

  group('SpendingTab Integration Tests', () {
    setUp(() async {
      await TestSetup.setupTest();
      GetIt.I.allowReassignment = true;
      GetIt.I.registerSingleton<StatisticsService>(FakeStatisticsService());
      GetIt.I.registerSingleton<DataService>(FakeDataService());
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    testWidgets('should render complete widget tree', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingTab(
              startDate: startDate,
              endDate: endDate,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Widget should render without throwing exceptions
      expect(tester.takeException(), isNull);
      expect(find.byType(SpendingTab), findsOneWidget);
    });
  });
}
