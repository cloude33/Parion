import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/security/biometric_setup_screen.dart';

/// Navigation utilities for authentication flow
class AuthNavigation {
  /// Navigate to welcome screen (app entry point)
  static void toWelcome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      _createSlideRoute(const WelcomeScreen()),
      (route) => false,
    );
  }

  /// Navigate to login screen
  static void toLogin(BuildContext context) {
    Navigator.push(
      context,
      _createSlideRoute(const LoginScreen()),
    );
  }

  /// Navigate to register screen
  static void toRegister(BuildContext context) {
    Navigator.push(
      context,
      _createSlideRoute(const RegisterScreen()),
    );
  }

  /// Navigate to home screen (authenticated state)
  static void toHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      _createFadeRoute(const HomeScreen()),
      (route) => false,
    );
  }

  /// Navigate to biometric setup screen
  static Future<bool?> toBiometricSetup(BuildContext context) {
    return Navigator.push<bool>(
      context,
      _createSlideRoute(const BiometricSetupScreen()),
    );
  }

  /// Navigate back to previous screen
  static void back(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Navigate back with result
  static void backWithResult<T>(BuildContext context, T result) {
    Navigator.pop(context, result);
  }

  /// Replace current screen with new screen
  static void replace(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      _createSlideRoute(screen),
    );
  }

  /// Create slide transition route
  static PageRouteBuilder<T> _createSlideRoute<T>(Widget screen) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Create fade transition route
  static PageRouteBuilder<T> _createFadeRoute<T>(Widget screen) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }
}

/// Extension methods for easier navigation
extension AuthNavigationExtension on BuildContext {
  /// Navigate to welcome screen
  void toWelcome() => AuthNavigation.toWelcome(this);

  /// Navigate to login screen
  void toLogin() => AuthNavigation.toLogin(this);

  /// Navigate to register screen
  void toRegister() => AuthNavigation.toRegister(this);

  /// Navigate to home screen
  void toHome() => AuthNavigation.toHome(this);

  /// Navigate to biometric setup screen
  Future<bool?> toBiometricSetup() => AuthNavigation.toBiometricSetup(this);

  /// Navigate back
  void goBack() => AuthNavigation.back(this);

  /// Navigate back with result
  void goBackWithResult<T>(T result) => AuthNavigation.backWithResult(this, result);
}