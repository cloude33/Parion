import 'package:flutter/material.dart';
import 'package:parion/core/design/app_spacing.dart';

/// Displays a loading skeleton with animated shimmer-like effect.
/// Uses [AnimatedContainer] with theme colors since the shimmer package
/// is not available. Falls back to [CircularProgressIndicator] for
/// single-item loading.
/// Colors are sourced from [Theme.of(context)] for dark/light theme support.
class AppLoadingState extends StatefulWidget {
  const AppLoadingState({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 72.0,
  });

  final int itemCount;
  final double itemHeight;

  @override
  State<AppLoadingState> createState() => _AppLoadingStateState();
}

class _AppLoadingStateState extends State<AppLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 0) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final highlightColor = colorScheme.onSurface.withValues(alpha: 0.18);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final shimmerColor =
            Color.lerp(baseColor, highlightColor, _animation.value)!;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _SkeletonItem(
            height: widget.itemHeight,
            color: shimmerColor,
            surfaceColor: colorScheme.surface,
          ),
        );
      },
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem({
    required this.height,
    required this.color,
    required this.surfaceColor,
  });

  final double height;
  final Color color;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar placeholder
            Container(
              width: height - AppSpacing.md * 2,
              height: height - AppSpacing.md * 2,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
