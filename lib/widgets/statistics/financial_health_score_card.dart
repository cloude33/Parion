import 'package:flutter/material.dart';
import '../../core/design/app_spacing.dart';
import '../../models/asset_analysis.dart';

class FinancialHealthScoreCard extends StatelessWidget {
  final FinancialHealthScore healthScore;
  final VoidCallback? onTap;

  const FinancialHealthScoreCard({
    super.key,
    required this.healthScore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: _getScoreColor(healthScore.overallScore),
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finansal Sağlık Skoru',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getScoreLabel(healthScore.overallScore),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _getScoreColor(healthScore.overallScore),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(
                        healthScore.overallScore,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getScoreColor(healthScore.overallScore),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '${healthScore.overallScore.toStringAsFixed(0)}/100',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _getScoreColor(healthScore.overallScore),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),
              _buildScoreRow(
                context,
                'Likidite',
                healthScore.liquidityScore,
                Icons.water_drop,
                'Kısa vadeli yükümlülükleri karşılama kapasitesi',
              ),

              const SizedBox(height: AppSpacing.lg),

              _buildScoreRow(
                context,
                'Borç Yönetimi',
                healthScore.debtManagementScore,
                Icons.account_balance,
                'Borç seviyeleri ve geri ödeme kapasitesi',
              ),

              const SizedBox(height: AppSpacing.lg),

              _buildScoreRow(
                context,
                'Tasarruf',
                healthScore.savingsScore,
                Icons.savings,
                'Tasarruf oranı ve net varlık büyümesi',
              ),

              const SizedBox(height: AppSpacing.lg),

              _buildScoreRow(
                context,
                'Yatırım',
                healthScore.investmentScore,
                Icons.trending_up,
                'Yatırım çeşitlendirmesi ve dağılımı',
              ),
              if (healthScore.recommendations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                const Divider(),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Öneriler',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                ...healthScore.recommendations.map((recommendation) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: AppSpacing.xs),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildScoreRow(
    BuildContext context,
    String label,
    double score,
    IconData icon,
    String description,
  ) {
    final theme = Theme.of(context);
    final scoreColor = _getScoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: scoreColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${score.toStringAsFixed(0)}/100',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: scoreColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.lightGreen;
    } else if (score >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  String _getScoreLabel(double score) {
    if (score >= 80) {
      return 'Mükemmel';
    } else if (score >= 60) {
      return 'İyi';
    } else if (score >= 40) {
      return 'Orta';
    } else {
      return 'Dikkat Gerekli';
    }
  }
}


