import 'package:shared_preferences/shared_preferences.dart';

/// Manages onboarding completion state using SharedPreferences.
class OnboardingService {
  static const String _key = 'onboarding_completed';

  /// Returns true if the user has already completed onboarding.
  /// Returns false on any SharedPreferences access error (safe default).
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Persists onboarding completion so it is not shown again.
  Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Silently ignore; onboarding may be shown again on next launch.
    }
  }
}
