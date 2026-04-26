import 'package:flutter/material.dart';
import '../../services/theme_service.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// Builds ThemeData using AppColors, AppTextStyles and AppSpacing tokens.
/// Wraps ThemeService so the rest of the app can use AppTheme as the
/// single source of truth for theme construction.
class AppTheme {
  AppTheme._();

  /// Light theme built from design-system tokens.
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryVariant,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.onSurface,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF8E8E93),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.onSurface,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.onSurface,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.onSurface,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.onSurface,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.onSurface,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.onSurface,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.onSurface,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurface,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: const Color(0xFF8E8E93),
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.onSurface,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: const Color(0xFF8E8E93),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  /// Dark theme built from design-system tokens.
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        primaryContainer: AppColors.primaryVariantDark,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.errorDark,
        onPrimary: Colors.white,
        onSurface: AppColors.onSurfaceDark,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onSurfaceDark,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.onSurfaceDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: Color(0xFF8E8E93),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.onSurfaceDark,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.onSurfaceDark,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.onSurfaceDark,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.onSurfaceDark,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.onSurfaceDark,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.onSurfaceDark,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.onSurfaceDark,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: const Color(0xFFE5E5EA),
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: const Color(0xFFAAAAAA),
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.onSurfaceDark,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: const Color(0xFF8E8E93),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
        hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: const BorderSide(color: AppColors.errorDark, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: const BorderSide(color: AppColors.errorDark, width: 2),
        ),
      ),
      dividerColor: const Color(0xFF38383A),
      iconTheme: const IconThemeData(color: AppColors.onSurfaceDark),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.onSurfaceDark,
        iconColor: AppColors.onSurfaceDark,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.onSurfaceDark,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: const Color(0xFFE5E5EA),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2C2E),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurfaceDark,
        ),
      ),
    );
  }

  /// Convenience accessor — delegates to [ThemeService] for the current
  /// [ThemeMode] while using [AppTheme] themes for the actual [ThemeData].
  static ThemeService get service => ThemeService();
}
