import 'package:flutter/material.dart';

/// Shared loading widget for authentication screens
class AuthLoadingWidget extends StatelessWidget {
  final String message;
  final bool showProgress;
  final Color? backgroundColor;
  final Color? progressColor;

  const AuthLoadingWidget({
    super.key,
    this.message = 'Yükleniyor...',
    this.showProgress = true,
    this.backgroundColor,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress) ...[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressColor ?? const Color(0xFFFDB32A),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1C1E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading overlay that can be shown on top of existing content
class AuthLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String loadingMessage;

  const AuthLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage = 'Yükleniyor...',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          AuthLoadingWidget(
            message: loadingMessage,
          ),
      ],
    );
  }
}

/// Progress indicator for buttons
class AuthButtonProgress extends StatelessWidget {
  final Color? color;
  final double size;

  const AuthButtonProgress({
    super.key,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
}

