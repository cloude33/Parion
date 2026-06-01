import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import '../../models/family/family_export.dart';
import '../common/app_card.dart';
import 'member_avatar.dart';

class FamilyGroupCard extends StatelessWidget {
  const FamilyGroupCard({
    super.key,
    required this.group,
    required this.totalExpenses,
    required this.pendingDebts,
    required this.onTap,
  });

  final FamilyGroup group;
  final double totalExpenses;
  final int pendingDebts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(group.colorHex) ?? AppColors.primary;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Icon(Icons.groups_rounded, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (group.description != null &&
                        group.description!.isNotEmpty)
                      Text(
                        group.description!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurface,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  icon: Icons.payments_outlined,
                  label: 'Bu ay',
                  value:
                      '${group.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalExpenses)}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStat(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Açık borç',
                  value: '$pendingDebts',
                  valueColor: pendingDebts > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              MemberStack(
                members: group.activeMembers,
                size: 32,
              ),
              const Spacer(),
              Text(
                '${group.activeMemberCount} üye',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null) return null;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return null;
    }
  }
}
