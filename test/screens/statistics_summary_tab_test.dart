import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'package:parion/models/asset_analysis.dart';
import 'package:parion/models/cash_flow_data.dart';
import 'package:parion/models/comparison_data.dart';
import 'package:parion/models/credit_analysis.dart';
import 'package:parion/models/category.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/screens/statistics_screen.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/statistics_service.dart';
import 'package:parion/widgets/statistics/statistics_loading_state.dart';
import 'package:parion/widgets/statistics/statistics_empty_state.dart';
import 'package:parion/widgets/statistics/statistics_error_state.dart';
import '../test_setup.dart';

/// Widget tests for the Summary Tab (Task 8.2)
///
/// **Validates: Requirements 3.7, 3.8, 3.9, 14.1, 14.2, 14.3**
void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('Özet Sekmesi — Durum Yönetimi (Task 8.2)', () {
    setUp(() async {
      await TestSetup.setupTest();
      GetIt.I.allowReassignment = true;
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    // Helper to build the screen with given services
    Widget _buildScreen({
      List<Transaction> transactions = const [],
      List<Wallet> wallets = const [],
    }) {
      return MaterialApp(
        home: StatisticsScreen(
          transactions: transactions,
          wallets: wallets,
          loans: const [],
          creditCardTransactions: const [],
        ),
      );
    }

    // ── Requirement 3.8, 14.1: Loading state ─────────────────────────────────

    testWidgets(
        'Yükleme durumunda StatisticsLoadingState gösterilmelidir (Req 3.8, 14.1)',
        (tester) async {
      // Register a slow statistics service that never completes during the test
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_SlowStatisticsService());

      // Provide some transactions so the tab renders content (not empty state)
      final transactions = [
        Transaction(
          id: '1',
          description: 'Test Gelir',
          amount: 1000,
          type: 'income',
          category: 'Maaş',
          date: DateTime.now(),
          walletId: 'w1',
        ),
      ];

      await tester.pumpWidget(_buildScreen(transactions: transactions));
      // Only pump once — don't settle futures — to catch loading state
      await tester.pump();

      // The summary tab is shown by default (index 0)
      // StatisticsLoadingState should appear while futures are pending
      expect(find.byType(StatisticsLoadingState), findsWidgets,
          reason:
              'StatisticsLoadingState must be shown while data is loading (Req 3.8, 14.1)');
    });

    // ── Requirement 3.7, 14.2: Empty state ───────────────────────────────────

    testWidgets(
        'Boş veri durumunda StatisticsEmptyState gösterilmelidir (Req 3.7, 14.2)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      // No transactions → empty state
      await tester.pumpWidget(_buildScreen(transactions: const []));
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsEmptyState), findsWidgets,
          reason:
              'StatisticsEmptyState must be shown when there are no transactions (Req 3.7, 14.2)');
    });

    testWidgets('Boş veri durumunda "Veri Bulunamadı" mesajı gösterilmelidir',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      await tester.pumpWidget(_buildScreen(transactions: const []));
      await tester.pumpAndSettle();

      expect(find.text('Veri Bulunamadı'), findsOneWidget,
          reason: 'Empty state title must be "Veri Bulunamadı"');
    });

    // ── Requirement 3.9, 14.3: Error state with retry button ─────────────────

    testWidgets(
        'Hata durumunda StatisticsErrorState ve "Tekrar Dene" butonu gösterilmelidir (Req 3.9, 14.3)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_ErrorStatisticsService());

      // Provide transactions so the tab renders (not empty state)
      final transactions = [
        Transaction(
          id: '1',
          description: 'Test Gelir',
          amount: 1000,
          type: 'income',
          category: 'Maaş',
          date: DateTime.now(),
          walletId: 'w1',
        ),
      ];

      await tester.pumpWidget(_buildScreen(transactions: transactions));
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsErrorState), findsWidgets,
          reason:
              'StatisticsErrorState must be shown when a service call fails (Req 3.9, 14.3)');
      expect(find.text('Tekrar Dene'), findsWidgets,
          reason:
              '"Tekrar Dene" button must be shown in error state (Req 3.9, 14.3)');
    });

    testWidgets('"Tekrar Dene" butonuna basıldığında yeniden yükleme tetiklenmelidir',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_ErrorStatisticsService());

      final transactions = [
        Transaction(
          id: '1',
          description: 'Test Gelir',
          amount: 1000,
          type: 'income',
          category: 'Maaş',
          date: DateTime.now(),
          walletId: 'w1',
        ),
      ];

      await tester.pumpWidget(_buildScreen(transactions: transactions));
      await tester.pumpAndSettle();

      // Tap the first "Tekrar Dene" button
      final retryButton = find.text('Tekrar Dene').first;
      await tester.tap(retryButton);
      await tester.pump();

      // No exception should be thrown
      expect(tester.takeException(), isNull,
          reason: 'Tapping "Tekrar Dene" must not throw an exception');
    });

    // ── Requirement 3.1: Summary cards shown when data is available ───────────

    testWidgets(
        'Veri mevcut olduğunda özet kartlar gösterilmelidir (Req 3.1)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      final transactions = [
        Transaction(
          id: '1',
          description: 'Test Gelir',
          amount: 5000,
          type: 'income',
          category: 'Maaş',
          date: DateTime.now(),
          walletId: 'w1',
        ),
        Transaction(
          id: '2',
          description: 'Test Gider',
          amount: 2000,
          type: 'expense',
          category: 'Market',
          date: DateTime.now(),
          walletId: 'w1',
        ),
      ];

      await tester.pumpWidget(_buildScreen(transactions: transactions));
      await tester.pumpAndSettle();

      // Summary cards should show income/expense labels
      expect(find.text('Toplam Gelir'), findsWidgets,
          reason: 'Toplam Gelir card must be shown (Req 3.1)');
      expect(find.text('Toplam Gider'), findsOneWidget,
          reason: 'Toplam Gider card must be shown (Req 3.1)');
      expect(find.text('Net Nakit Akışı'), findsOneWidget,
          reason: 'Net Nakit Akışı card must be shown (Req 3.1)');
    });

    testWidgets(
        'Veri mevcut olduğunda tasarruf oranı gösterilmelidir (Req 3.2)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      final transactions = [
        Transaction(
          id: '1',
          description: 'Test Gelir',
          amount: 5000,
          type: 'income',
          category: 'Maaş',
          date: DateTime.now(),
          walletId: 'w1',
        ),
      ];

      await tester.pumpWidget(_buildScreen(transactions: transactions));
      await tester.pumpAndSettle();

      expect(find.text('Tasarruf Oranı'), findsOneWidget,
          reason: 'Tasarruf Oranı card must be shown (Req 3.2)');
    });
  });
}

// ── Fake service implementations ─────────────────────────────────────────────

class _FakeDataService extends Fake implements DataService {
  @override
  Future<List<Category>> getCategories() async => [];

  @override
  Future<List<Wallet>> getWallets() async => [];

  @override
  Future<List<Transaction>> getTransactions() async => [];
}

class _FakeStatisticsService extends Fake implements StatisticsService {
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
          liquidityScore: 75,
          debtManagementScore: 80,
          savingsScore: 60,
          investmentScore: 50,
          overallScore: 66,
          recommendations: ['Tasarruf oranınızı artırın'],
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
  Future<SpendingAnalysis> analyzeSpending({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categories,
    Map<String, double>? budgets,
  }) async =>
      SpendingAnalysis(
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
  Future<CashFlowData> calculateCashFlow({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String? category,
    bool includePreviousPeriod = false,
  }) async =>
      CashFlowData(
        totalIncome: 0,
        totalExpense: 0,
        netCashFlow: 0,
        averageDaily: 0,
        averageMonthly: 0,
        monthlyData: [],
        trend: TrendDirection.stable,
      );

  @override
  Future<ComparisonData> comparePeriods({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
    String? period1Label,
    String? period2Label,
    String? walletId,
    String? category,
  }) async {
    final emptyMetric = ComparisonMetric(
      label: '',
      period1Value: 0,
      period2Value: 0,
      absoluteChange: 0,
      percentageChange: 0,
      trend: TrendDirection.stable,
    );
    return ComparisonData(
      period1Start: period1Start,
      period1End: period1End,
      period2Start: period2Start,
      period2End: period2End,
      period1Label: period1Label ?? 'Önceki Dönem',
      period2Label: period2Label ?? 'Bu Dönem',
      income: emptyMetric,
      expense: emptyMetric,
      netCashFlow: emptyMetric,
      categoryComparisons: [],
      overallTrend: TrendDirection.stable,
      insights: [],
    );
  }
}

/// A statistics service that never completes its futures (simulates loading).
class _SlowStatisticsService extends Fake implements StatisticsService {
  @override
  Future<AssetAnalysis> analyzeAssets() => Completer<AssetAnalysis>().future;

  @override
  Future<CreditAnalysis> analyzeCreditAndKmh() =>
      Completer<CreditAnalysis>().future;

  @override
  Future<SpendingAnalysis> analyzeSpending({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categories,
    Map<String, double>? budgets,
  }) =>
      Completer<SpendingAnalysis>().future;

  @override
  Future<CashFlowData> calculateCashFlow({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String? category,
    bool includePreviousPeriod = false,
  }) =>
      Completer<CashFlowData>().future;

  @override
  Future<ComparisonData> comparePeriods({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
    String? period1Label,
    String? period2Label,
    String? walletId,
    String? category,
  }) =>
      Completer<ComparisonData>().future;
}

/// A statistics service that always throws errors.
class _ErrorStatisticsService extends Fake implements StatisticsService {
  @override
  Future<AssetAnalysis> analyzeAssets() async =>
      throw Exception('Servis hatası: analyzeAssets');

  @override
  Future<CreditAnalysis> analyzeCreditAndKmh() async =>
      throw Exception('Servis hatası: analyzeCreditAndKmh');

  @override
  Future<SpendingAnalysis> analyzeSpending({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categories,
    Map<String, double>? budgets,
  }) async =>
      throw Exception('Servis hatası: analyzeSpending');

  @override
  Future<CashFlowData> calculateCashFlow({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String? category,
    bool includePreviousPeriod = false,
  }) async =>
      throw Exception('Servis hatası: calculateCashFlow');

  @override
  Future<ComparisonData> comparePeriods({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
    String? period1Label,
    String? period2Label,
    String? walletId,
    String? category,
  }) async =>
      throw Exception('Servis hatası: comparePeriods');
}
