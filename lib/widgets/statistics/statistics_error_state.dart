import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';

/// Error state widget for statistics screens
class StatisticsErrorState extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color? iconColor;

  const StatisticsErrorState({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? Colors.red[300],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              message,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                details!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error widget for smaller components
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.red[900],
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRetry,
              iconSize: 20,
              color: Colors.red[700],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error snackbar utilities
class StatisticsErrorSnackbar {
  static void show(
    BuildContext context,
    String message, {
    String? details,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.onPrimary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.labelLarge,
                  ),
                ),
              ],
            ),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                details,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: SnackBarAction(
          label: 'Tamam',
          textColor: AppColors.onPrimary,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Success snackbar utilities
class StatisticsSuccessSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.onPrimary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.labelLarge,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }
}

/// Warning snackbar utilities
class StatisticsWarningSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: AppColors.onPrimary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.labelLarge,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }
}

/// Predefined error states for common scenarios
class StatisticsErrorStates {
  static Widget noData({VoidCallback? onRetry}) {
    return StatisticsErrorState(
      message: 'Veri Bulunamadı',
      details: 'Seçilen tarih aralığında veri bulunmuyor',
      icon: Icons.inbox_outlined,
      iconColor: AppColors.onSurface.withValues(alpha: 0.4),
      onRetry: onRetry,
    );
  }

  static Widget calculationError({VoidCallback? onRetry}) {
    return StatisticsErrorState(
      message: 'Hesaplama Hatası',
      details: 'İstatistikler hesaplanırken bir hata oluştu',
      icon: Icons.calculate_outlined,
      onRetry: onRetry,
    );
  }

  static Widget networkError({VoidCallback? onRetry}) {
    return StatisticsErrorState(
      message: 'Bağlantı Hatası',
      details: 'Veriler yüklenirken bir hata oluştu',
      icon: Icons.cloud_off_outlined,
      onRetry: onRetry,
    );
  }

  static Widget exportError({VoidCallback? onRetry}) {
    return StatisticsErrorState(
      message: 'Dışa Aktarma Hatası',
      details: 'Dosya oluşturulurken bir hata oluştu',
      icon: Icons.file_download_off_outlined,
      onRetry: onRetry,
    );
  }

  static Widget invalidDateRange({VoidCallback? onRetry}) {
    return StatisticsErrorState(
      message: 'Geçersiz Tarih Aralığı',
      details: 'Lütfen geçerli bir tarih aralığı seçin',
      icon: Icons.date_range_outlined,
      iconColor: Colors.orange[400],
      onRetry: onRetry,
    );
  }
}
