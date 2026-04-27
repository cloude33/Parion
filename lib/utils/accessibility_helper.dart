import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'dart:math' show pow;

/// Accessibility helper utilities for the authentication system
/// Ensures compliance with WCAG 2.1 AA standards and platform accessibility guidelines
class AccessibilityHelper {
  
  /// Minimum touch target size (44x44 dp for iOS, 48x48 dp for Android)
  static const double minTouchTargetSize = 48.0;
  
  /// Minimum color contrast ratios
  static const double minContrastRatioNormal = 4.5;
  static const double minContrastRatioLarge = 3.0;
  
  /// Creates accessible button with proper semantics
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    bool excludeSemantics = false,
    EdgeInsets? padding,
    double? minWidth,
    double? minHeight,
    ButtonStyle? style,
  }) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );
    
    // Ensure minimum touch target size
    button = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth ?? minTouchTargetSize,
        minHeight: minHeight ?? minTouchTargetSize,
      ),
      child: button,
    );
    
    // Add tooltip if provided
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }
    
    // Add semantic label if provided
    if (semanticLabel != null && !excludeSemantics) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: button,
      );
    }
    
    return button;
  }
  
  /// Creates accessible text field with proper semantics
  static Widget accessibleTextField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    String? semanticLabel,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
    FormFieldValidator<String>? validator,
    bool enabled = true,
    bool readOnly = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    InputDecoration? decoration,
  }) {
    return Semantics(
      label: semanticLabel ?? labelText,
      textField: true,
      enabled: enabled,
      readOnly: readOnly,
      obscured: obscureText,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        enabled: enabled,
        readOnly: readOnly,
        decoration: decoration ?? InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: errorText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
  
  /// Creates accessible icon button with proper semantics
  static Widget accessibleIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String semanticLabel,
    String? tooltip,
    double? iconSize,
    Color? color,
    double? splashRadius,
    EdgeInsets? padding,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip ?? semanticLabel,
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          iconSize: iconSize,
          color: color,
          splashRadius: splashRadius,
          padding: padding ?? const EdgeInsets.all(8.0),
          constraints: const BoxConstraints(
            minWidth: minTouchTargetSize,
            minHeight: minTouchTargetSize,
          ),
        ),
      ),
    );
  }
  
  /// Creates accessible checkbox with proper semantics
  static Widget accessibleCheckbox({
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required String label,
    String? semanticLabel,
    bool tristate = false,
    Color? activeColor,
    Color? checkColor,
    MaterialTapTargetSize? materialTapTargetSize,
  }) {
    return Semantics(
      label: semanticLabel ?? label,
      checked: value,
      enabled: onChanged != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: minTouchTargetSize,
            height: minTouchTargetSize,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              tristate: tristate,
              activeColor: activeColor,
              checkColor: checkColor,
              materialTapTargetSize: materialTapTargetSize,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onTap: onChanged != null ? () => onChanged(!value) : null,
              child: Text(
                label,
                style: TextStyle(
                  color: onChanged != null ? null : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Creates accessible loading indicator with proper semantics
  static Widget accessibleLoadingIndicator({
    String? semanticLabel,
    double? size,
    Color? color,
    double strokeWidth = 2.0,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Yükleniyor',
      liveRegion: true,
      child: SizedBox(
        width: size ?? 24.0,
        height: size ?? 24.0,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: color != null 
            ? AlwaysStoppedAnimation<Color>(color)
            : null,
        ),
      ),
    );
  }
  
  /// Creates accessible error message with proper semantics
  static Widget accessibleErrorMessage({
    required String message,
    String? semanticLabel,
    IconData? icon,
    Color? color,
    VoidCallback? onDismiss,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Hata: $message',
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? Colors.red).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? Colors.red).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: color ?? Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color ?? Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
            if (onDismiss != null)
              accessibleIconButton(
                icon: Icons.close,
                onPressed: onDismiss,
                semanticLabel: 'Hatayı kapat',
                iconSize: 18,
                color: color ?? Colors.red,
              ),
          ],
        ),
      ),
    );
  }
  
  /// Creates accessible success message with proper semantics
  static Widget accessibleSuccessMessage({
    required String message,
    String? semanticLabel,
    IconData? icon,
    Color? color,
    VoidCallback? onDismiss,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Başarılı: $message',
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? Colors.green).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? Colors.green).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: color ?? Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color ?? Colors.green,
                  fontSize: 14,
                ),
              ),
            ),
            if (onDismiss != null)
              accessibleIconButton(
                icon: Icons.close,
                onPressed: onDismiss,
                semanticLabel: 'Mesajı kapat',
                iconSize: 18,
                color: color ?? Colors.green,
              ),
          ],
        ),
      ),
    );
  }
  
  /// Creates accessible navigation announcement
  static void announceNavigation(String destination) {
    // ignore: deprecated_member_use
    SemanticsService.announce(
      '$destination sayfasına gidiliyor',
      TextDirection.ltr,
    );
  }
  
  /// Creates accessible state change announcement
  static void announceStateChange(String state) {
    // ignore: deprecated_member_use
    SemanticsService.announce(
      state,
      TextDirection.ltr,
    );
  }
  
  /// Checks if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }
  
  /// Checks if reduce motion is enabled
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  
  /// Gets accessible text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }
  
  /// Creates accessible divider with semantic meaning
  static Widget accessibleDivider({
    String? semanticLabel,
    double? height,
    double? thickness,
    Color? color,
  }) {
    return Semantics(
      label: semanticLabel,
      child: Divider(
        height: height,
        thickness: thickness,
        color: color,
      ),
    );
  }
  
  /// Creates accessible card with proper semantics
  static Widget accessibleCard({
    required Widget child,
    String? semanticLabel,
    VoidCallback? onTap,
    Color? color,
    double? elevation,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    Widget card = Card(
      color: color,
      elevation: elevation,
      margin: margin,
      shape: borderRadius != null 
        ? RoundedRectangleBorder(borderRadius: borderRadius)
        : null,
      child: padding != null 
        ? Padding(padding: padding, child: child)
        : child,
    );
    
    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: card,
      );
    }
    
    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: card,
      );
    }
    
    return card;
  }
  
  /// Creates accessible list tile with proper semantics
  static Widget accessibleListTile({
    Widget? leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    String? semanticLabel,
    bool enabled = true,
    bool selected = false,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: enabled,
      selected: selected,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        enabled: enabled,
        selected: selected,
      ),
    );
  }
  
  /// Validates color contrast ratio
  static bool hasValidContrast({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
  }) {
    final ratio = _calculateContrastRatio(foreground, background);
    final minRatio = isLargeText ? minContrastRatioLarge : minContrastRatioNormal;
    return ratio >= minRatio;
  }
  
  /// Calculates color contrast ratio
  static double _calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _calculateLuminance(color1);
    final luminance2 = _calculateLuminance(color2);
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Calculates relative luminance of a color
  static double _calculateLuminance(Color color) {
    final r = _linearizeColorComponent(color.r);
    final g = _linearizeColorComponent(color.g);
    final b = _linearizeColorComponent(color.b);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  
  /// Linearizes color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }
  
  /// Creates accessible focus scope
  static Widget accessibleFocusScope({
    required Widget child,
    FocusNode? focusNode,
    bool autofocus = false,
    String? debugLabel,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      debugLabel: debugLabel,
      child: child,
    );
  }
  
  /// Creates accessible modal barrier
  static Widget accessibleModalBarrier({
    required Widget child,
    String? semanticLabel,
    bool dismissible = true,
    VoidCallback? onDismiss,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Modal dialog',
      child: GestureDetector(
        onTap: dismissible ? onDismiss : null,
        child: child,
      ),
    );
  }
}

/// Extension for adding accessibility helpers to existing widgets
extension AccessibilityExtensions on Widget {
  /// Adds semantic label to any widget
  Widget withSemanticLabel(String label) {
    return Semantics(
      label: label,
      child: this,
    );
  }
  
  /// Adds live region semantics
  Widget withLiveRegion({
    bool assertive = false,
  }) {
    return Semantics(
      liveRegion: true,
      child: this,
    );
  }
  
  /// Adds button semantics
  Widget asButton({
    String? label,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: this,
    );
  }
  
  /// Adds heading semantics
  Widget asHeading({
    String? label,
  }) {
    return Semantics(
      label: label,
      header: true,
      child: this,
    );
  }
  
  /// Excludes from semantics tree
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }
}

/// Accessibility constants and guidelines
class AccessibilityConstants {
  static const double minTouchTarget = 48.0;
  static const double recommendedTouchTarget = 56.0;
  static const double minTextSize = 12.0;
  static const double recommendedTextSize = 16.0;
  static const double largeTextSize = 18.0;
  
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration reducedAnimationDuration = Duration(milliseconds: 150);
  
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets compactPadding = EdgeInsets.all(8.0);
  static const EdgeInsets spaciousPadding = EdgeInsets.all(24.0);
}

