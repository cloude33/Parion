import 'package:flutter/material.dart';
import 'package:parion/core/design/app_colors.dart';
import 'package:parion/core/design/app_spacing.dart';
import 'package:parion/core/design/app_text_styles.dart';

/// A single page in the onboarding flow.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.backgroundColor,
  });

  final Widget icon;
  final String title;
  final String description;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.backgroundDark : AppColors.background);
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.huge,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            title,
            style: AppTextStyles.headlineLarge.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
