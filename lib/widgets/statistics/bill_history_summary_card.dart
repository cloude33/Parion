import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parion/core/design/app_colors.dart';
import 'package:parion/core/design/app_spacing.dart';
import 'package:parion/core/design/app_text_styles.dart';
import 'package:parion/models/bill_history_summary.dart';
import 'package:parion/widgets/statistics/statistics_empty_state.dart';

/// Displays a summary card of bill payment history per bill template.
///
/// Shows payment rate, last payment date, and next due date for each template.
/// Color-codes payment rates for quick visual assessment, with icons for
/// color-blind accessibility (Requirement 19.3).
class BillHistorySummaryCard extends StatelessWidget {
  final List<BillHistorySummary> summaries;

  /// Called when the user taps the "Add Bill" action in the empty state.
  final VoidCallback? onAddBill;

  const BillHistorySummaryCard({
    super.key,
    required this.summaries,
    this.onAddBill,
  });

  /// Returns the appropriate color for a given payment rate.
  ///
  /// - `rate >= 100` → [AppColors.success]
  /// - `50 <= rate < 100` → [AppColors.warning]
  /// - `rate < 50` → [AppColors.error]
  ///
  /// **Validates: Requirements 9.3**
  static Color colorForRate(double rate) {
    if (rate >= 100) return AppColors.success;
    if (rate >= 50) return AppColors.warning;
    return AppColors.error;
  }

  /// Returns an icon that conveys the same meaning as the color,
  /// supporting color-blind accessibility (Requirement 19.3).
  static IconData _iconForRate(double rate) {
    if (rate >= 100) return Icons.check_circle;
    if (rate >= 50) return Icons.warning_amber_rounded;
    return Icons.cancel;
  }

  /// Returns a semantic label for the rate status.
  static String _labelForRate(double rate) {
    if (rate >= 100) return 'Tam ödendi';
    if (rate >= 50) return 'Kısmen ödendi';
    return 'Düşük ödeme';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.md),
            if (summaries.isEmpty)
              _buildEmptyState()
            else
              _buildSummaryList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.receipt_long, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Fatura Ödeme Geçmişi',
          style: AppTextStyles.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return StatisticsEmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Fatura Şablonu Yok',
      message:
          'Fatura ödeme geçmişini takip etmek için fatura şablonu ekleyin.',
      actionLabel: onAddBill != null ? 'Fatura Ekle' : null,
      onAction: onAddBill,
    );
  }

  Widget _buildSummaryList(BuildContext context) {
    return Column(
      children: summaries
          .map((summary) => _BillSummaryRow(summary: summary))
          .toList(),
    );
  }
}

/// A single row displaying one bill template's payment summary.
class _BillSummaryRow extends StatelessWidget {
  final BillHistorySummary summary;

  const _BillSummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final color = BillHistorySummaryCard.colorForRate(summary.paymentRate);
    final icon = BillHistorySummaryCard._iconForRate(summary.paymentRate);
    final statusLabel =
        BillHistorySummaryCard._labelForRate(summary.paymentRate);
    final dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');

    return Semantics(
      label:
          '${summary.templateName}: ödeme oranı %${summary.paymentRate.toStringAsFixed(0)}, $statusLabel',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color + icon indicator (color-blind accessible)
            Semantics(
              label: statusLabel,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Bill name and dates
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.templateName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildDateRow(
                    context,
                    label: 'Son ödeme:',
                    date: summary.lastPaidDate != null
                        ? dateFormat.format(summary.lastPaidDate!)
                        : '—',
                  ),
                  _buildDateRow(
                    context,
                    label: 'Sonraki ödeme:',
                    date: summary.nextDueDate != null
                        ? dateFormat.format(summary.nextDueDate!)
                        : '—',
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Payment rate badge
            _PaymentRateBadge(
              rate: summary.paymentRate,
              paid: summary.paidPayments,
              total: summary.totalPayments,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(
    BuildContext context, {
    required String label,
    required String date,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          date,
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Badge showing the payment rate percentage and paid/total counts.
class _PaymentRateBadge extends StatelessWidget {
  final double rate;
  final int paid;
  final int total;
  final Color color;

  const _PaymentRateBadge({
    required this.rate,
    required this.paid,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '%${rate.toStringAsFixed(0)}',
          style: AppTextStyles.labelLarge.copyWith(color: color),
        ),
        Text(
          '$paid/$total',
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
