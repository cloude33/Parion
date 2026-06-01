import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isInitialized = false;

  AuthService._internal();

  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    if (_isInitialized) return;
    _isInitialized = true;

    unawaited(() async {
      try {
        debugPrint('AuthService: Pre-loading Google Sign-In library...');
        if (kIsWeb) {
          await GoogleSignIn.instance.initialize(
            clientId: '195092382674-ca5q05m7idrstrqpfb5bc6e00thqiu20.apps.googleusercontent.com',
          ).timeout(const Duration(seconds: 5));
        } else {
          await GoogleSignIn.instance.initialize(
            serverClientId: '195092382674-ca5q05m7idrstrqpfb5bc6e00thqiu20.apps.googleusercontent.com',
          ).timeout(const Duration(seconds: 5));
        }
        debugPrint('✅ AuthService: Google Sign-In library pre-loaded');
      } catch (e) {
        debugPrint('⚠️ AuthService: Google Sign-In pre-load failed (will retry on first sign-in): $e');
      }
    }());
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
      // Ensure initialization
      if (!_isInitialized) {
        await init();
      }
      
      debugPrint('🔄 AuthService: Starting Google Sign-In...');
      
      // Clear any existing session to prevent conflicts
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('⚠️ AuthService: Sign out error (ignorable): $e');
      }
      
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      
      debugPrint('✅ AuthService: Google Sign-In successful: ${account.email}');
      
      // Save user data
      await _prefs?.setString('google_email', account.email);
      await _prefs?.setString('google_name', account.displayName ?? '');
      await _prefs?.setString('google_photo', account.photoUrl ?? '');
      
      return account;
    } on PlatformException catch (e) {
      debugPrint('❌ AuthService: Platform Exception in Google Sign-In: ${e.code} - ${e.message}');
      
      // Handle specific platform errors
      if (e.code == 'sign_in_failed') {
        if (e.message?.contains('10') == true) {
          debugPrint('❌ AuthService: Google Play Services configuration error');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ AuthService: Unexpected error in Google Sign-In: $e');
      return null;
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await GoogleSignIn.instance.signOut();
      debugPrint('✅ AuthService: Signed out from Google');
    } catch (e) {
      debugPrint('⚠️ AuthService: Google sign out error (ignorable): $e');
    }
    
    // Clear stored data regardless of sign-out success
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
