import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth/google_sign_in_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isInitialized = false;

  AuthService._internal();

  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Tek GoogleSignIn instance — tüm akışlar GoogleSignInHelper üzerinden
  // yapılır (platform tarafı singleton'dur, birden fazla instance sessiz
  // başarısızlığa yol açar).
  GoogleSignIn get _googleSignIn => GoogleSignInHelper.instance.googleSignIn;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    debugPrint('✅ AuthService: initialized');
  }

  Future<void> savePinCode(String pin) async {
    await _secureStorage.write(key: 'pin_code', value: pin);
  }

  Future<String?> getPinCode() async {
    return await _secureStorage.read(key: 'pin_code');
  }

  Future<bool> verifyPinCode(String pin) async {
    final savedPin = await getPinCode();
    return savedPin == pin;
  }

  Future<bool> hasPinCode() async {
    final pin = await getPinCode();
    return pin != null && pin.isNotEmpty;
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw PlatformException(
          code: 'NotAvailable',
          message: 'Biyometrik özellik kullanılamıyor',
        );
      }
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        throw PlatformException(
          code: 'NotEnabled',
          message: 'Biyometrik doğrulama etkin değil',
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Uygulamaya giriş yapmak için kimliğinizi doğrulayın',
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' ||
          e.code == 'NotEnrolled' ||
          e.code == 'LockedOut' ||
          e.code == 'PermanentlyLockedOut') {
        rethrow;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      if (!_isInitialized) await init();
      debugPrint('🔄 AuthService: Starting Google Sign-In...');

      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        debugPrint('⚠️ AuthService: Google Sign-In cancelled');
        return null;
      }

      debugPrint('✅ AuthService: Google Sign-In successful: ${account.email}');
      await _prefs?.setString('google_email', account.email);
      await _prefs?.setString('google_name', account.displayName ?? '');
      await _prefs?.setString('google_photo', account.photoUrl ?? '');
      return account;
    } on PlatformException catch (e) {
      debugPrint('❌ AuthService: Platform Exception: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ AuthService: Unexpected error: $e');
      return null;
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('✅ AuthService: Signed out from Google');
    } catch (e) {
      debugPrint('⚠️ AuthService: Google sign out error (ignorable): $e');
    }
    await _prefs?.remove('google_email');
    await _prefs?.remove('google_name');
    await _prefs?.remove('google_photo');
  }

  // Apple Sign In
  Future<AuthorizationCredentialAppleID?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.email != null) {
        await _prefs?.setString('apple_email', credential.email!);
      }
      if (credential.givenName != null || credential.familyName != null) {
        final fullName =
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim();
        await _prefs?.setString('apple_name', fullName);
      }
      if (credential.userIdentifier != null) {
        await _prefs?.setString('apple_user_id', credential.userIdentifier!);
      }

      return credential;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOutApple() async {
    await _prefs?.remove('apple_email');
    await _prefs?.remove('apple_name');
    await _prefs?.remove('apple_user_id');
  }

  Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }

  Future<bool> isLoggedIn() async {
    final googleEmail = _prefs?.getString('google_email');
    final appleUserId = _prefs?.getString('apple_user_id');
    final hasPin = await hasPinCode();

    return googleEmail != null || appleUserId != null || hasPin;
  }

  Future<String?> getCurrentAuthMethod() async {
    if (_prefs?.getString('google_email') != null) return 'google';
    if (_prefs?.getString('apple_user_id') != null) return 'apple';
    if (await hasPinCode()) return 'pin';
    return null;
  }

  Future<void> logoutAll() async {
    await signOutGoogle();
    await signOutApple();
    await _secureStorage.delete(key: 'pin_code');
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: 'biometric_enabled',
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: 'biometric_enabled');
    return value == 'true';
  }
}
