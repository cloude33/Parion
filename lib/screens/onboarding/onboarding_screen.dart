import 'package:flutter/material.dart';
import 'package:parion/core/design/app_colors.dart';
import 'package:parion/core/design/app_spacing.dart';
import 'package:parion/core/design/app_text_styles.dart';
import 'package:parion/screens/home_screen.dart';
import 'package:parion/services/onboarding_service.dart';
import 'package:parion/widgets/common/app_button.dart';
import 'onboarding_page.dart';

/// 3-step onboarding flow shown only on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  int _currentPage = 0;

  static const int _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await _onboardingService.markOnboardingCompleted();
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  List<OnboardingPage> _buildPages(bool isDark) {
    final iconColor = isDark ? AppColors.primaryDark : AppColors.primary;

    return [
      // Step 1: Welcome
      OnboardingPage(
        icon: Column(
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                size: 80, color: iconColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Parion',
              style: AppTextStyles.displayLarge.copyWith(color: iconColor),
            ),
          ],
        ),
        title: 'Hoş Geldiniz',
        description:
            'Finansal özgürlüğünüze giden yolda akıllı para yönetimi.',
      ),
      // Step 2: Feature introduction
      OnboardingPage(
        icon: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FeatureRow(
              icon: Icons.pie_chart_rounded,
              label: 'Bütçe Takibi',
              color: iconColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            _FeatureRow(
              icon: Icons.credit_card_rounded,
              label: 'Kredi Kartı Yönetimi',
              color: iconColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            _FeatureRow(
              icon: Icons.account_balance_rounded,
              label: 'KMH Taksit Takibi',
              color: iconColor,
            ),
          ],
        ),
        title: 'Her Şey Bir Arada',
        description:
            'Bütçenizi, kredi kartlarınızı ve KMH hesaplarınızı tek yerden yönetin.',
      ),
      // Step 3: Initial setup
      OnboardingPage(
        icon: Icon(Icons.rocket_launch_rounded, size: 80, color: iconColor),
        title: 'Hemen Başlayın',
        description:
            'İlk cüzdanınızı veya kredi kartınızı ekleyerek finansal takibinize başlayın.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _buildPages(isDark);
    final isLastPage = _currentPage == _pageCount - 1;
    final dotActiveColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final dotInactiveColor = dotActiveColor.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  right: AppSpacing.lg,
                ),
                child: AppButton(
                  label: 'Atla',
                  variant: AppButtonVariant.text,
                  onPressed: _complete,
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                children: pages,
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pageCount, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs),
                  width: _currentPage == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? dotActiveColor
                        : dotInactiveColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: isLastPage
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Cüzdan Ekle',
                            onPressed: _complete,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Kredi Kartı Ekle',
                            variant: AppButtonVariant.secondary,
                            onPressed: _complete,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Şimdilik Atla',
                          variant: AppButtonVariant.text,
                          onPressed: _complete,
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Devam',
                        onPressed: _nextPage,
                      ),
                    ),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: AppTextStyles.titleMedium.copyWith(color: textColor),
        ),
      ],
    );
  }
}
