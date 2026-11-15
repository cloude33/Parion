import 'package:flutter/material.dart';

/// Responsive breakpoint constants for the Parion design system.
///
/// Values follow the `adapt` reference: content-driven breakpoints
/// rather than device-model checks. Mobile-first: base styles target
/// narrow screens, complexity layers on wider viewports.
class AppResponsive {
  AppResponsive._();

  /// Mobile portrait max width (exclusive): 320px – 767px
  static const double mobileMax = 767.0;

  /// Tablet range: 768px – 1023px
  static const double tabletMax = 1023.0;

  /// Desktop starts at 1024px
  static const double desktopMin = 1024.0;

  /// Convenience: is the current context a mobile-width screen?
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= mobileMax;

  /// Convenience: is the current context a tablet-width screen?
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > mobileMax && width <= tabletMax;
  }

  /// Convenience: is the current context a desktop-width screen?
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMin;

  /// Returns a column max-width appropriate for the current screen.
  /// Mobile: full width. Tablet/desktop: constrained for readability.
  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 640.0;
    if (isTablet(context)) return 560.0;
    return double.infinity;
  }

  /// Horizontal padding appropriate for the current screen size.
  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 40.0;
    if (isTablet(context)) return 32.0;
    return 20.0;
  }
}
