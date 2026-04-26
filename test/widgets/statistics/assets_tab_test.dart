/// Widget tests for the Assets Tab (Task 9.2)
///
/// **Validates: Requirements 11.1, 11.7**
///
/// Tests:
/// - Cüzdan yokken `Statistics_Empty_State` gösterildiğini doğrula
/// - KMH ve normal cüzdanların ayrı bölümlerde gösterildiğini doğrula
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
import 'package:parion/widgets/statistics/statistics_empty_state.dart';
import 'package:parion/widgets/statistics/kmh_asset_card.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('Varlıklar Sekmesi Widget Testleri (Task 9.2)', () {
    setUp(() async {
      await TestSetup.setupTest();
      GetIt.I.allowReassignment = true;
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    Widget _buildScreen({
      List<Wallet> wallets = const [],
      List<Transaction> transactions = const [],
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

    Future<void> _navigateToAssetsTab(WidgetTester tester) async {
      // Tap the "Varlıklar" tab (index 3)
      await tester.tap(find.text('Varlıklar'));
      await tester.pumpAndSettle();
    }

    // ── Requirement 11.7: Cüzdan yokken StatisticsEmptyState ─────────────────

    testWidgets(
        'Cüzdan yokken StatisticsEmptyState gösterilmelidir (Req 11.7)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      await tester.pumpWidget(_buildScreen(wallets: const []));
      await tester.pumpAndSettle();

      await _navigateToAssetsTab(tester);

      expect(
        find.byType(StatisticsEmptyState),
        findsOneWidget,
        reason:
            'StatisticsEmptyState must be shown when there are no wallets (Req 11.7)',
      );
    });

    testWidgets(
        'Cüzdan yokken "Cüzdan Bulunamadı" başlığı gösterilmelidir (Req 11.7)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      await tester.pumpWidget(_buildScreen(wallets: const []));
      await tester.pumpAndSettle();

      await _navigateToAssetsTab(tester);

      expect(
        find.text('Cüzdan Bulunamadı'),
        findsOneWidget,
        reason: 'Empty state title must be "Cüzdan Bulunamadı" (Req 11.7)',
      );
    });

    // ── Requirement 11.1: Normal ve KMH cüzdanlar ayrı bölümlerde ────────────

    testWidgets(
        'Normal cüzdanlar "Cüzdanlar" bölümünde gösterilmelidir (Req 11.1)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      final wallets = [
        Wallet(
          id: 'w1',
          name: 'Nakit Cüzdanım',
          balance: 500,
          type: 'cash',
          color: '0xFF4CAF50',
          icon: 'money',
          creditLimit: 0,
        ),
        Wallet(
          id: 'w2',
          name: 'Banka Hesabım',
          balance: 2000,
          type: 'bank',
          color: '0xFF2196F3',
          icon: 'account_balance',
          creditLimit: 0,
        ),
      ];

      await tester.pumpWidget(_buildScreen(wallets: wallets));
      await tester.pumpAndSettle();

      await _navigateToAssetsTab(tester);

      expect(
        find.text('Cüzdanlar'),
        findsOneWidget,
        reason:
            'Normal wallets section must be labeled "Cüzdanlar" (Req 11.1)',
      );
    });

    testWidgets(
        'KMH hesapları KmhAssetCard ile gösterilmelidir (Req 11.1, 11.6)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      final wallets = [
        Wallet(
          id: 'kmh1',
          name: 'KMH Hesabım',
          balance: -1000,
          type: 'overdraft',
          color: '0xFF9C27B0',
          icon: 'account_balance',
          creditLimit: 5000,
        ),
      ];

      await tester.pumpWidget(_buildScreen(wallets: wallets));
      await tester.pumpAndSettle();

      await _navigateToAssetsTab(tester);

      expect(
        find.byType(KmhAssetCard),
        findsOneWidget,
        reason:
            'KMH accounts must be shown using KmhAssetCard widget (Req 11.1, 11.6)',
      );
    });

    testWidgets(
        'Normal ve KMH cüzdanlar aynı anda ayrı bölümlerde gösterilmelidir (Req 11.1)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      final wallets = [
        Wallet(
          id: 'w1',
          name: 'Nakit Cüzdanım',
          balance: 500,
          type: 'cash',
          color: '0xFF4CAF50',
          icon: 'money',
          creditLimit: 0,
        ),
        Wallet(
          id: 'kmh1',
          name: 'KMH Hesabım',
          balance: -1000,
          type: 'overdraft',
          color: '0xFF9C27B0',
          icon: 'account_balance',
          creditLimit: 5000,
        ),
      ];

      await tester.pumpWidget(_buildScreen(wallets: wallets));
      await tester.pumpAndSettle();

      await _navigateToAssetsTab(tester);

      // Normal cüzdanlar bölümü
      expect(
        find.text('Cüzdanlar'),
        findsOneWidget,
        reason: 'Normal wallets section must be present (Req 11.1)',
      );

      // KMH bölümü
      expect(
        find.byType(KmhAssetCard),
        findsOneWidget,
        reason: 'KMH section must be present (Req 11.1)',
      );
    });

    // ── Requirement 11.2: Özet kartlar ───────────────────────────────────────

    testWidgets(
        'Toplam varlık özet kartı gösterilmelidir (Req 11.2)',
        (tester) async {
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());

      final wallets = [
        Wallet(
          id: 'w1',
          name: 'Nakit',
          balance: 1000,
          type: 'cash',
          color: '0xFF4CAF50',
          icon: 'money',
          creditLimit: 0,
        ),
      ];

      await tester.pumpWidget(_buildScreen(wallets: wallets));
      await tester.pumpAndSettle();

      await _navigateToAssetsTab(tester);

      expect(
        find.text('Toplam Varlık'),
        findsOneWidget,
        reason: 'Total assets summary card must be shown (Req 11.2)',
      );
      expect(
        find.text('Net Varlık'),
        findsOneWidget,
        reason: 'Net worth summary card must be shown (Req 11.2)',
      );
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
