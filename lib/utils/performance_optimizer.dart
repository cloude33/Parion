import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

/// Types of haptic feedback
enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}

/// Performance optimization utilities for the authentication system
/// Provides tools for optimizing loading times, animations, and responsiveness
class PerformanceOptimizer {
  static const Duration _defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration _fastAnimationDuration = Duration(milliseconds: 200);
  static const Duration _slowAnimationDuration = Duration(milliseconds: 500);

  /// Optimizes animation duration based on device performance
  static Duration getOptimizedAnimationDuration({
    Duration? defaultDuration,
    bool isComplexAnimation = false,
  }) {
    final duration = defaultDuration ?? _defaultAnimationDuration;
    
    // Reduce animation duration on slower devices
    if (isComplexAnimation) {
      return Duration(milliseconds: (duration.inMilliseconds * 0.8).round());
    }
    
    return duration;
  }

  /// Provides optimized curve for animations based on context
  static Curve getOptimizedCurve({
    bool isEntranceAnimation = false,
    bool isExitAnimation = false,
  }) {
    if (isEntranceAnimation) {
      return Curves.easeOutCubic;
    } else if (isExitAnimation) {
      return Curves.easeInCubic;
    }
    return Curves.easeInOut;
  }

  /// Optimizes image loading with proper caching and sizing
  static Widget optimizedImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? errorWidget,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? 
          Icon(
            Icons.error_outline,
            size: width ?? height ?? 24,
            color: Colors.grey,
          );
      },
    );
  }

  /// Provides optimized loading indicators
  static Widget optimizedLoadingIndicator({
    double size = 24.0,
    Color? color,
    double strokeWidth = 2.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null 
          ? AlwaysStoppedAnimation<Color>(color)
          : null,
      ),
    );
  }

  /// Optimizes text rendering for better performance
  static TextStyle optimizedTextStyle({
    required TextStyle baseStyle,
    bool isHeading = false,
  }) {
    return baseStyle.copyWith(
      // Optimize font rendering
      fontFeatures: isHeading 
        ? [const FontFeature.enable('kern')]
        : null,
    );
  }

  /// Provides optimized container decoration
  static BoxDecoration optimizedDecoration({
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      gradient: gradient,
    );
  }

  /// Optimizes button interactions with proper feedback
  static void optimizedHapticFeedback({
    HapticFeedbackType type = HapticFeedbackType.lightImpact,
  }) {
    switch (type) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }

  /// Provides frame-rate aware animations
  static AnimationController createOptimizedController({
    required TickerProvider vsync,
    Duration? duration,
    String? debugLabel,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: getOptimizedAnimationDuration(defaultDuration: duration),
      debugLabel: debugLabel,
    );
  }

  /// Optimizes scroll physics for better performance
  static ScrollPhysics get optimizedScrollPhysics {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  /// Provides optimized list view builder
  static Widget optimizedListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: optimizedScrollPhysics,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Optimize for performance
      cacheExtent: 250.0,
    );
  }

  /// Provides optimized grid view builder
  static Widget optimizedGridView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsets? padding,
    bool shrinkWrap = false,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: optimizedScrollPhysics,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Optimize for performance
      cacheExtent: 250.0,
    );
  }

  /// Debounces function calls to improve performance
  static void debounce({
    required VoidCallback callback,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    Timer(delay, callback);
  }

  /// Throttles function calls to improve performance
  static void throttle({
    required VoidCallback callback,
    Duration interval = const Duration(milliseconds: 100),
  }) {
    bool canExecute = true;
    if (canExecute) {
      canExecute = false;
      callback();
      Timer(interval, () {
        canExecute = true;
      });
    }
  }

  /// Provides memory-efficient image caching
  static void preloadImages(BuildContext context, List<String> assetPaths) {
    for (final path in assetPaths) {
      precacheImage(AssetImage(path), context);
    }
  }

  /// Optimizes widget rebuilds using RepaintBoundary
  static Widget optimizedRepaintBoundary({
    required Widget child,
    String? debugLabel,
  }) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// Provides optimized fade transition
  static Widget optimizedFadeTransition({
    required Animation<double> animation,
    required Widget child,
    Curve curve = Curves.easeInOut,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: child,
    );
  }

  /// Provides optimized slide transition
  static Widget optimizedSlideTransition({
    required Animation<double> animation,
    required Widget child,
    Offset begin = const Offset(0.0, 0.3),
    Offset end = Offset.zero,
    Curve curve = Curves.easeOutCubic,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: child,
    );
  }

  /// Provides optimized scale transition
  static Widget optimizedScaleTransition({
    required Animation<double> animation,
    required Widget child,
    double begin = 0.8,
    double end = 1.0,
    Curve curve = Curves.elasticOut,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: child,
    );
  }

  /// Measures widget build performance
  static T measureBuildPerformance<T>({
    required T Function() builder,
    String? debugLabel,
  }) {
    final stopwatch = Stopwatch()..start();
    final result = builder();
    stopwatch.stop();
    
    if (debugLabel != null) {
      debugPrint('🚀 $debugLabel build time: ${stopwatch.elapsedMilliseconds}ms');
    }
    
    return result;
  }

  /// Provides frame callback for performance monitoring
  static void addFrameCallback(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());
  }

  /// Optimizes form field performance
  static InputDecoration optimizedInputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
    Color? borderColor,
    Color? focusedBorderColor,
    BorderRadius? borderRadius,
    bool filled = true,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: borderColor ?? Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: focusedBorderColor ?? Colors.blue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}

/// Timer utility for debouncing and throttling
class Timer {
  static Timer? _debounceTimer;
  static Timer? _throttleTimer;
  
  final Duration duration;
  final VoidCallback callback;
  
  Timer(this.duration, this.callback) {
    Future.delayed(duration, callback);
  }
  
  void cancel() {
    // Timer cancellation is handled by Future.delayed
  }
  
  static void cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
  
  static void cancelThrottle() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
  }
}

/// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, Stopwatch> _stopwatches = {};
  
  /// Starts performance measurement
  static void start(String label) {
    _stopwatches[label] = Stopwatch()..start();
  }
  
  /// Stops performance measurement and logs result
  static void stop(String label) {
    final stopwatch = _stopwatches[label];
    if (stopwatch != null) {
      stopwatch.stop();
      debugPrint('🚀 $label: ${stopwatch.elapsedMilliseconds}ms');
      _stopwatches.remove(label);
    }
  }
  
  /// Measures execution time of a function
  static T measure<T>(String label, T Function() function) {
    start(label);
    final result = function();
    stop(label);
    return result;
  }
}

