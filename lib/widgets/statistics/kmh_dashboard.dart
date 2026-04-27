import '../../core/design/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../models/credit_analysis.dart';
import '../../services/statistics_service.dart';
import '../../utils/currency_helper.dart';
import 'kmh_summary_cards.dart';
import 'kmh_utilization_indicator.dart';
import 'kmh_interest_card.dart';
import 'kmh_trend_charts.dart';
class KmhDashboard extends StatefulWidget {
  const KmhDashboard({super.key});

  @override
  State<KmhDashboard> createState() => _KmhDashboardState();
}

class _KmhDashboardState extends State<KmhDashboard> {
  final StatisticsService _statisticsService = GetIt.I<StatisticsService>();
  bool _isLoading = true;
  String? _error;
  CreditAnalysis? _creditAnalysis;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analysis = await _statisticsService.analyzeCreditAndKmh();
      if (mounted) {
        setState(() {
          _creditAnalysis = analysis;
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Veri yüklenirken hata oluştu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_creditAnalysis == null || _creditAnalysis!.kmhAccounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'KMH Hesabı Bulunamadı',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Henüz KMH hesabınız bulunmamaktadır.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          KmhSummaryCards(
            totalDebt: _creditAnalysis!.totalKmhDebt,
            totalLimit: _creditAnalysis!.totalKmhLimit,
            utilizationRate: _creditAnalysis!.kmhUtilization,
            accountCount: _creditAnalysis!.kmhAccounts.length,
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          KmhInterestCard(
            dailyInterest: _creditAnalysis!.dailyInterest,
            monthlyInterest: _creditAnalysis!.monthlyInterest,
            annualInterest: _creditAnalysis!.annualInterest,
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          if (_creditAnalysis!.debtTrend.isNotEmpty) ...[
            KmhTrendCharts(
              debtTrend: _creditAnalysis!.debtTrend,
              totalLimit: _creditAnalysis!.totalKmhLimit,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          _buildAccountsSection(),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KMH Hesapları',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._creditAnalysis!.kmhAccounts.map((account) => _buildAccountCard(account)),
      ],
    );
  }

  Widget _buildAccountCard(KmhSummary account) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isInDebt = account.balance < 0;
    final debt = isInDebt ? account.balance.abs() : 0.0;
    final availableCredit = account.limit - debt;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.bankName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isInDebt ? 'Borç' : 'Bakiye',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.formatAmountNoDecimal(isInDebt ? debt : account.balance),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isInDebt ? Colors.red : Colors.green,
                      ),
                    ),
                    if (isInDebt) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Limit: ${CurrencyHelper.formatAmountNoDecimal(account.limit)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            
            if (isInDebt) ...[
              const SizedBox(height: AppSpacing.lg),
              KmhUtilizationIndicator(
                utilizationRate: account.utilizationRate,
                usedAmount: debt,
                totalLimit: account.limit,
                showLabel: true,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.grey[850] 
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.percent,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Faiz Oranı',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '%${account.interestRate.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Günlük Faiz',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyHelper.formatAmount(account.dailyInterest),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Kullanılabilir Kredi',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyHelper.formatAmountNoDecimal(availableCredit),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Bu hesapta borç bulunmamaktadır',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


