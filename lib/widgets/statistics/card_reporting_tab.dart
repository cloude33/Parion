import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/credit_card.dart';
import '../../services/card_reporting_service.dart';
import '../../services/credit_card_service.dart';
import '../../utils/currency_helper.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import 'statistics_loading_state.dart';
import 'statistics_empty_state.dart';
import 'statistics_error_state.dart';

/// Wrapper widget for card reporting content.
/// Wraps card_reporting_screen.dart content with NestedScrollView for inner tabs.
class CardReportingTab extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const CardReportingTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<CardReportingTab> createState() => _CardReportingTabState();
}

class _CardReportingTabState extends State<CardReportingTab>
    with SingleTickerProviderStateMixin {
  final CardReportingService _reportingService = CardReportingService();
  final CreditCardService _cardService = CreditCardService();

  late TabController _tabController;
  List<CreditCard> _cards = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCardId;
  int _selectedMonths = 6;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CardReportingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cards = await _cardService.getAllCards();
      if (mounted) {
        setState(() {
          _cards = cards;
          if (_cards.isNotEmpty && _selectedCardId == null) {
            _selectedCardId = _cards.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    if (_isLoading) {
      return const StatisticsLoadingState(
        message: 'Kart verileri yükleniyor...',
      );
    }

    if (_error != null) {
      return StatisticsErrorState(
        message: 'Veriler yüklenemedi',
        details: _error,
        onRetry: _loadData,
      );
    }

    if (_cards.isEmpty) {
      return StatisticsEmptyStates.noCreditCards(
        onAddCard: () {},
      );
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: _buildCardSelector(primaryColor),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: primaryColor,
                labelColor: primaryColor,
                unselectedLabelColor: isDark
                    ? AppColors.onSurfaceDark.withValues(alpha: 0.6)
                    : AppColors.onSurface.withValues(alpha: 0.6),
                labelStyle: AppTextStyles.labelLarge,
                unselectedLabelStyle: AppTextStyles.bodyMedium,
                tabs: const [
                  Tab(text: 'Genel Bakış'),
                  Tab(text: 'Harcama Trendi'),
                  Tab(text: 'Kategori Analizi'),
                  Tab(text: 'Faiz Raporu'),
                  Tab(text: 'Kart Karşılaştırma'),
                ],
              ),
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(primaryColor),
          _buildSpendingTrendTab(primaryColor),
          _buildCategoryAnalysisTab(),
          _buildInterestReportTab(),
          _buildCardComparisonTab(primaryColor),
        ],
      ),
    );
  }

  Widget _buildCardSelector(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: DropdownButtonFormField<String>(
        value: _selectedCardId,
        decoration: InputDecoration(
          labelText: 'Kart Seçin',
          border: const OutlineInputBorder(),
          prefixIcon: Icon(Icons.credit_card, color: primaryColor),
        ),
        items: _cards.map((card) {
          return DropdownMenuItem(
            value: card.id,
            child: Text('${card.bankName} ${card.cardName}'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedCardId = value);
        },
      ),
    );
  }

  Widget _buildOverviewTab(Color primaryColor) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportingService.getMostUsedCard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const StatisticsLoadingState();
        }
        if (snapshot.hasError) {
          return StatisticsErrorState(
            message: 'Genel bakış yüklenemedi',
            details: snapshot.error.toString(),
          );
        }

        final data = snapshot.data ?? {};

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildCard(
              title: 'En Çok Kullanılan Kart',
              child: data['hasCard'] == true
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.credit_card,
                                  color: primaryColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['cardName'] ?? '',
                                      style: AppTextStyles.titleLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '${data['transactionCount']} işlem',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Divider(),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Toplam Harcama:',
                                style: AppTextStyles.bodyLarge,
                              ),
                              Text(
                                CurrencyHelper.formatAmount(
                                  data['totalSpending'] ?? 0,
                                ),
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Henüz işlem yapılmamış',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildCard(
              title: 'Kart Kullanım Özeti',
              child: FutureBuilder<Map<String, dynamic>>(
                future: _reportingService.compareCardUsage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final usageData = snapshot.data ?? {};
                  final cards =
                      usageData['cards'] as Map<String, dynamic>? ?? {};

                  if (cards.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text('Veri yok', style: AppTextStyles.bodyMedium),
                    );
                  }

                  return Column(
                    children: cards.entries.map((entry) {
                      final cardData = entry.value as Map<String, dynamic>;
                      return ListTile(
                        leading: Icon(Icons.credit_card, color: primaryColor),
                        title: Text(
                          cardData['cardName'] ?? '',
                          style: AppTextStyles.bodyMedium,
                        ),
                        subtitle: Text(
                          '${cardData['transactionCount']} işlem',
                          style: AppTextStyles.bodySmall,
                        ),
                        trailing: Text(
                          CurrencyHelper.formatAmount(
                            cardData['totalSpending'] ?? 0,
                          ),
                          style: AppTextStyles.labelLarge,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpendingTrendTab(Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: Theme.of(context).cardColor,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 3, label: Text('3 Ay')),
              ButtonSegment(value: 6, label: Text('6 Ay')),
              ButtonSegment(value: 12, label: Text('12 Ay')),
            ],
            selected: {_selectedMonths},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() => _selectedMonths = newSelection.first);
            },
          ),
        ),
        Expanded(
          child: _selectedCardId == null
              ? Center(
                  child: Text(
                    'Lütfen bir kart seçin',
                    style: AppTextStyles.bodyLarge,
                  ),
                )
              : FutureBuilder<Map<String, dynamic>>(
                  future: _reportingService.getMonthlySpendingTrend(
                    _selectedCardId!,
                    _selectedMonths,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const StatisticsLoadingState();
                    }
                    if (snapshot.hasError) {
                      return StatisticsErrorState(
                        message: 'Trend verisi yüklenemedi',
                        details: snapshot.error.toString(),
                      );
                    }

                    final data = snapshot.data ?? {};
                    final trendData =
                        data['trendData'] as Map<DateTime, double>? ?? {};

                    if (trendData.isEmpty) {
                      return StatisticsEmptyStates.noTransactions();
                    }

                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        _buildCard(
                          title: 'Aylık Harcama Trendi',
                          child: Container(
                            height: 300,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: _buildTrendChart(trendData, primaryColor),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildCard(
                          title: 'Aylık Detaylar',
                          child: Column(
                            children: trendData.entries.map((entry) {
                              return ListTile(
                                leading: Icon(
                                  Icons.calendar_month,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                                title: Text(
                                  DateFormat('MMMM yyyy', 'tr_TR')
                                      .format(entry.key),
                                  style: AppTextStyles.bodyMedium,
                                ),
                                trailing: Text(
                                  CurrencyHelper.formatAmount(entry.value),
                                  style: AppTextStyles.titleMedium,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(Map<DateTime, double> trendData, Color primaryColor) {
    if (trendData.isEmpty) {
      return Center(
        child: Text('Veri yok', style: AppTextStyles.bodyMedium),
      );
    }

    final sortedEntries = trendData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value));
    }

    final maxY = sortedEntries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < sortedEntries.length) {
                  final month = sortedEntries[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      DateFormat('MMM', 'tr_TR').format(month),
                      style: AppTextStyles.labelSmall,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₺${NumberFormat.compact().format(value)}',
                  style: AppTextStyles.labelSmall,
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (sortedEntries.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildCard(
          title: 'Kategori Bazlı Kart Kullanımı',
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Her kategoride hangi kartın ne kadar kullanıldığını gösterir',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildCard(
          title: 'Kart Bazlı Harcama Dağılımı',
          child: Column(
            children: _cards.map((card) {
              return ExpansionTile(
                leading: const Icon(Icons.credit_card),
                title: Text(
                  '${card.bankName} ${card.cardName}',
                  style: AppTextStyles.bodyMedium,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Kategori detayları burada gösterilecek',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestReportTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: Theme.of(context).cardColor,
          child: DropdownButtonFormField<int>(
            value: _selectedYear,
            decoration: const InputDecoration(
              labelText: 'Yıl Seçin',
              border: OutlineInputBorder(),
            ),
            items: List.generate(5, (index) {
              final year = DateTime.now().year - index;
              return DropdownMenuItem(
                value: year,
                child: Text(year.toString()),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedYear = value);
              }
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildCard(
                title: 'Yıllık Faiz Raporu',
                child: Column(
                  children: _cards.map((card) {
                    return FutureBuilder<double>(
                      future: _reportingService.getTotalInterestPaidYearly(
                        card.id,
                        _selectedYear,
                      ),
                      builder: (context, snapshot) {
                        final interest = snapshot.data ?? 0;
                        return ListTile(
                          leading: Icon(Icons.credit_card, color: errorColor),
                          title: Text(
                            '${card.bankName} ${card.cardName}',
                            style: AppTextStyles.bodyMedium,
                          ),
                          subtitle: Text(
                            '$_selectedYear yılı toplam faiz',
                            style: AppTextStyles.bodySmall,
                          ),
                          trailing: Text(
                            CurrencyHelper.formatAmount(interest),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: errorColor,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FutureBuilder<double>(
                future: _calculateTotalInterestAllCards(),
                builder: (context, snapshot) {
                  final totalInterest = snapshot.data ?? 0;
                  return _buildCard(
                    title: 'Toplam Faiz Ödemesi',
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 48,
                            color: errorColor,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            CurrencyHelper.formatAmount(totalInterest),
                            style: AppTextStyles.displayMedium.copyWith(
                              color: errorColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '$_selectedYear yılında ödenen toplam faiz',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<double> _calculateTotalInterestAllCards() async {
    double total = 0;
    for (var card in _cards) {
      final interest = await _reportingService.getTotalInterestPaidYearly(
        card.id,
        _selectedYear,
      );
      total += interest;
    }
    return total;
  }

  Widget _buildCardComparisonTab(Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final warningColor = isDark ? AppColors.warningDark : AppColors.warning;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportingService.getCardsSortedBySpending(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const StatisticsLoadingState();
        }
        if (snapshot.hasError) {
          return StatisticsErrorState(
            message: 'Kart karşılaştırması yüklenemedi',
            details: snapshot.error.toString(),
          );
        }

        final sortedCards = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildCard(
              title: 'Harcama Sıralaması',
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCards.length,
                itemBuilder: (context, index) {
                  final cardData = sortedCards[index];
                  final isTop = index == 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: isTop
                          ? primaryColor.withValues(alpha: 0.1)
                          : null,
                      border: isTop
                          ? Border.all(color: primaryColor, width: 2)
                          : null,
                      borderRadius:
                          isTop ? BorderRadius.circular(8) : null,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isTop
                            ? primaryColor
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isTop
                                ? AppColors.onPrimary
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                          ),
                        ),
                      ),
                      title: Text(
                        cardData['cardName'] ?? '',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isTop
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${cardData['transactionCount']} işlem',
                        style: AppTextStyles.bodySmall,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyHelper.formatAmount(
                              cardData['totalSpending'] ?? 0,
                            ),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isTop ? primaryColor : null,
                            ),
                          ),
                          if (isTop)
                            Text(
                              'En Çok Kullanılan',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: primaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<Map<String, dynamic>>(
              future: _reportingService.getCardUtilizationComparison(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data ?? {};
                final cards =
                    data['cards'] as Map<String, dynamic>? ?? {};

                return _buildCard(
                  title: 'Limit Kullanım Oranları',
                  child: Column(
                    children: cards.entries.map((entry) {
                      final cardData =
                          entry.value as Map<String, dynamic>;
                      final utilization =
                          (cardData['utilizationPercentage'] ?? 0.0)
                              as double;
                      final color = utilization > 80
                          ? errorColor
                          : (utilization > 50
                              ? warningColor
                              : successColor);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    cardData['cardName'] ?? '',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${utilization.toStringAsFixed(1)}%',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            LinearProgressIndicator(
                              value: utilization / 100,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              color: color,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Borç: ${CurrencyHelper.formatAmount(cardData['currentDebt'] ?? 0)}',
                                  style: AppTextStyles.bodySmall,
                                ),
                                Text(
                                  'Limit: ${CurrencyHelper.formatAmount(cardData['creditLimit'] ?? 0)}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(title, style: AppTextStyles.titleLarge),
          ),
          child,
        ],
      ),
    );
  }
}

/// SliverPersistentHeaderDelegate for pinning the TabBar inside NestedScrollView.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;

  _TabBarDelegate(this.tabBar, {required this.color});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: color,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || color != oldDelegate.color;
  }
}
