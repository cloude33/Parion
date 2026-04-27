import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:parion/models/asset_analysis.dart';
import 'package:parion/models/cash_flow_data.dart';
import 'package:parion/models/category.dart';
import 'package:parion/models/comparison_data.dart';
import 'package:parion/models/credit_analysis.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/screens/statistics_screen.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/statistics_service.dart';
import 'package:parion/widgets/statistics/time_filter_bar.dart';
import '../test_setup.dart';

/// **Validates: Requirements 1.1, 1.8, 2.3**
///
/// Unit tests for StatisticsScreen IndexedStack layout (Task 4.3):
/// - Tab count is 7
/// - Default tab is Özet (index 0)
/// - TimeFilterBar callback is triggered on filter change
void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('StatisticsScreen — IndexedStack düzeni (Task 4.3)', () {
    setUp(() async {
      await TestSetup.setupTest();
      GetIt.I.allowReassignment = true;
      GetIt.I.registerSingleton<DataService>(_FakeDataService());
      GetIt.I.registerSingleton<StatisticsService>(_FakeStatisticsService());
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    Widget _buildScreen() {
      return MaterialApp(
        home: StatisticsScreen(
          transactions: const [],
          wallets: const [],
          loans: const [],
          creditCardTransactions: const [],
        ),
      );
    }

    // ── Requirement 1.1: 7 sekme ──────────────────────────────────────────────

    testWidgets('sekme sayısı 7 olmalıdır', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      // TabBar should have exactly 7 tabs
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, equals(7),
          reason: 'StatisticsScreen must have exactly 7 tabs');
    });

    testWidgets('7 sekme başlığı görünür olmalıdır', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Özet'), findsOneWidget);
      expect(find.text('Harcama'), findsOneWidget);
      expect(find.text('Nakit Akışı'), findsOneWidget);
      expect(find.text('Varlıklar'), findsOneWidget);
      expect(find.text('Borç/Alacak'), findsOneWidget);
      expect(find.text('Kartlar'), findsOneWidget);
      expect(find.text('Tekrarlayan'), findsOneWidget);
    });

    testWidgets('TabBar kaydırılabilir (isScrollable: true) olmalıdır',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, isTrue,
          reason: 'TabBar must be scrollable for narrow screens');
    });

    // ── Requirement 1.8: Varsayılan sekme Özet (index 0) ─────────────────────

    testWidgets('varsayılan sekme Özet (index 0) olmalıdır', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      final tabController = DefaultTabController.maybeOf(
        tester.element(find.byType(TabBar)),
      );

      // Find the TabBar and check its controller
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller, isNotNull);
      expect(tabBar.controller!.index, equals(0),
          reason: 'Default tab must be Özet (index 0)');
    });

    testWidgets('IndexedStack varsayılan olarak index 0 göstermelidir',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      final indexedStack =
          tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(0),
          reason: 'IndexedStack must show index 0 (Özet) by default');
    });

    // ── Requirement 2.3: TimeFilterBar callback ───────────────────────────────

    testWidgets('TimeFilterBar filtre değişiminde callback tetiklenmelidir',
        (tester) async {
      TimeFilter? capturedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterBar(
              selectedFilter: TimeFilter.monthly,
              onFilterChanged: (f) => capturedFilter = f,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap on 'Haftalık' filter chip
      await tester.tap(find.text('Haftalık'));
      await tester.pump();

      expect(capturedFilter, equals(TimeFilter.weekly),
          reason: 'onFilterChanged must be called with TimeFilter.weekly');
    });

    testWidgets('TimeFilterBar tüm filtre seçeneklerini göstermelidir',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterBar(
              selectedFilter: TimeFilter.monthly,
              onFilterChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Günlük'), findsOneWidget);
      expect(find.text('Haftalık'), findsOneWidget);
      expect(find.text('Aylık'), findsOneWidget);
      expect(find.text('Yıllık'), findsOneWidget);
      expect(find.text('Özel'), findsOneWidget);
    });

    testWidgets(
        'TimeFilterBar seçili filtre değiştiğinde StatisticsScreen güncellenir',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      // Tap on 'Günlük' filter chip in the TimeFilterBar
      await tester.tap(find.text('Günlük'));
      await tester.pump();

      // After tapping, the TimeFilterBar should reflect the new selection
      // The chip for 'Günlük' should now be selected (no exception thrown)
      expect(tester.takeException(), isNull);
    });

    // ── IndexedStack kullanımı (Requirement 1.5) ──────────────────────────────

    testWidgets('build metodu IndexedStack kullanmalıdır (TabBarView değil)',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.byType(IndexedStack), findsOneWidget,
          reason: 'StatisticsScreen must use IndexedStack');
      expect(find.byType(TabBarView), findsNothing,
          reason: 'StatisticsScreen must NOT use TabBarView');
    });

    // ── RefreshIndicator (Requirement 15.5) ───────────────────────────────────

    testWidgets('RefreshIndicator ile pull-to-refresh desteği olmalıdır',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget,
          reason: 'StatisticsScreen must have RefreshIndicator');
    });

    // ── TimeFilterBar konumu (Requirement 2.1) ────────────────────────────────

    testWidgets('TimeFilterBar tüm sekmelerin üstünde görünmelidir',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.byType(TimeFilterBar), findsOneWidget,
          reason: 'TimeFilterBar must be present above all tabs');
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
      period1Label: period1Label ?? '',
      period2Label: period2Label ?? '',
      income: emptyMetric,
      expense: emptyMetric,
      netCashFlow: emptyMetric,
      categoryComparisons: [],
      overallTrend: TrendDirection.stable,
      insights: [],
    );
  }
}
