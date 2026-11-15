import 'package:flutter/material.dart';
import 'package:parion/core/design/app_colors.dart';
import 'package:parion/core/design/app_text_styles.dart';

/// Standard page scaffold widget that standardizes AppBar, body,
/// and optional FAB areas across all screens.
///
/// Mobile-first: body is wrapped in [SafeArea] so iOS notch / home
/// indicator safe areas are respected on web PWA. On tablet and
/// desktop the content is constrained to a readable max-width so lines
/// don't over-stretch.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.contentMaxWidth,
  });

  final String title;
  final Widget body;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  /// Optional max-width for the content column. Defaults to 480px on
  /// screens wider than 768px (tablet+), otherwise full width.
  final double? contentMaxWidth;

  static const _tabletBreakpoint = 768.0;
  static const _defaultMaxWidth = 520.0;
  static const _mobilePadding = 20.0;
  static const _widePadding = 32.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > _tabletBreakpoint;
    final maxWidth = contentMaxWidth ?? (isWide ? _defaultMaxWidth : double.infinity);
    final horizontalPadding = isWide ? _widePadding : _mobilePadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            color: Theme.of(context).appBarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onSurface,
          ),
        ),
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton && Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: AppColors.primary,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: actions,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: body,
            ),
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
