import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guest/Demo Mode Service
///
/// Provides a way for users (including Google Play reviewers) to explore
/// the app without creating an account. This is required by Google Play
/// policies when the app has a login wall.
class GuestModeService {
  static const String _guestModeKey = 'is_guest_mode';
  static const String _guestSessionKey = 'guest_session_id';

  static GuestModeService? _instance;
  GuestModeService._internal();

  factory GuestModeService() {
    _instance ??= GuestModeService._internal();
    return _instance!;
  }

  /// Check if the app is currently in guest/demo mode
  Future<bool> isGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_guestModeKey) ?? false;
    } catch (e) {
      debugPrint('GuestModeService: isGuestMode error: $e');
      return false;
    }
  }

  /// Activate guest/demo mode
  Future<void> enableGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setBool(_guestModeKey, true);
      await prefs.setString(_guestSessionKey, sessionId);
      debugPrint('GuestModeService: Guest mode enabled, session: $sessionId');
    } catch (e) {
      debugPrint('GuestModeService: enableGuestMode error: $e');
    }
  }

  /// Deactivate guest/demo mode (on logout or sign-in)
  Future<void> disableGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestModeKey);
      await prefs.remove(_guestSessionKey);
      debugPrint('GuestModeService: Guest mode disabled');
    } catch (e) {
      debugPrint('GuestModeService: disableGuestMode error: $e');
    }
  }

  /// Get current guest session ID
  Future<String?> getGuestSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_guestSessionKey);
    } catch (e) {
      return null;
    }
  }
}
