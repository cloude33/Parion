import '../../core/design/app_spacing.dart';
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
class StatisticsFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const StatisticsFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = selected
        ? theme.primaryColor
        : (isDark ? AppColors.surfaceDark : AppColors.background);

    final textColor = selected
        ? AppColors.onPrimary
        : theme.textTheme.bodyMedium?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(
                  color: isDark ? AppColors.onSurface.withValues(alpha: 0.8)! : AppColors.onSurfaceDark.withValues(alpha: 0.8)!,
                  width: 1,
                ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
