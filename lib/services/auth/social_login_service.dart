import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../models/security/security_models.dart';
import '../firebase_auth_service.dart';
import 'interfaces/social_login_interface.dart';

/// Unified Social Login Service
/// 
/// Implements Requirements:
/// - 3.1: Google Sign-In authentication
/// - 3.2: Apple Sign-In authentication  
/// - 3.3: Account linking capabilities
/// - 3.5: Multiple authentication methods for same user
class SocialLoginService implements ISocialLoginService {
  static final SocialLoginService _instance = SocialLoginService._internal();
  factory SocialLoginService() => _instance;
  SocialLoginService._internal();

  // Firebase Auth instance
  FirebaseAuth get _auth => FirebaseAuth.instance;
  
  // Firebase Auth Service for integration
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  
  // Google Sign-In instance
  late GoogleSignIn _googleSignIn;
  
  // Initialization flag
  bool _isInitialized = false;
  
  // Completer for initialization
  Completer<void>? _initCompleter;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // If already initializing, wait for completion
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    
    _initCompleter = Completer<void>();
    
    try {
      // Initialize Google Sign-In with proper configuration
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // Use the same server client ID as Firebase Auth Service
        serverClientId: '195092382674-ca5q05m7idrstrqpfb5bc6e00thqiu20.apps.googleusercontent.com',
      );
      
      _isInitialized = true;
      _initCompleter!.complete();
      
      debugPrint('✅ SocialLoginService initialized successfully');
    } catch (e) {
      debugPrint('❌ SocialLoginService initialization failed: $e');
      _initCompleter!.completeError(e);
      rethrow;
    }
  }

  /// Ensures service is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      
      debugPrint('🔄 Starting Google Sign-In via SocialLoginService...');
      
      // Use the existing Firebase Auth Service Google Sign-In implementation
      final userCredential = await _firebaseAuthService.signInWithGoogle();
      
      if (userCredential == null) {
        debugPrint('❌ Google Sign-In cancelled by user');
        return AuthResult.failure(
          method: AuthMethod.social,
          errorMessage: 'Google Sign-In iptal edildi',
        );
      }
      
      debugPrint('✅ Google Sign-In successful: ${userCredential.user?.email}');
      
      return AuthResult.success(
        method: AuthMethod.social,
        metadata: {
          'provider': 'google',
          'email': userCredential.user?.email,
          'displayName': userCredential.user?.displayName,
          'photoURL': userCredential.user?.photoURL,
          'uid': userCredential.user?.uid,
        },
      );
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error in Google Sign-In: ${e.code} - ${e.message}');
      return AuthResult.failure(
        method: AuthMethod.social,
        errorMessage: _handleFirebaseAuthException(e),
        metadata: {'provider': 'google', 'errorCode': e.code},
      );
    } on PlatformException catch (e) {
      debugPrint('❌ Platform Exception in Google Sign-In: ${e.code} - ${e.message}');
      return AuthResult.failure(
        method: AuthMethod.social,
        errorMessage: _handlePlatformException(e),
        metadata: {'provider': 'google', 'errorCode': e.code},
      );
    } catch (e) {
      debugPrint('❌ Unexpected error in Google Sign-In: $e');
      return AuthResult.failure(
        method: AuthMethod.social,
        errorMessage: 'Google Sign-In sırasında beklenmeyen bir hata oluştu',
        metadata: {'provider': 'google', 'error': e.toString()},
      );
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      await _ensureInitialized();
      
      debugPrint('🔄 Starting Apple Sign-In...');
      
      // Check if Apple Sign-In is available
      if (!await isAppleSignInAvailable()) {
        debugPrint('❌ Apple Sign-In not available on this device');
        return AuthResult.failure(
          method: AuthMethod.social,
          errorMessage: 'Apple Sign-In bu cihazda kullanılamıyor',
          metadata: {'provider': 'apple'},
        );
      }
      
      // Request Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: kIsWeb ? WebAuthenticationOptions(
          clientId: 'com.parion.app', // Replace with your actual client ID
          redirectUri: Uri.parse('https://your-app.firebaseapp.com/__/auth/handler'),
        ) : null,
      );
      
      debugPrint('✅ Apple credential received: ${appleCredential.userIdentifier}');
      
      // Create Firebase credential from Apple credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      
      // Sign in to Firebase with Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      // Update display name if provided and not already set
      if (appleCredential.givenName != null && 
          appleCredential.familyName != null &&
          userCredential.user?.displayName == null) {
        final displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
        await userCredential.user?.updateDisplayName(displayName);
      }
      
      debugPrint('✅ Apple Sign-In successful: ${userCredential.user?.email}');
      
      return AuthResult.success(
        method: AuthMethod.social,
        metadata: {
          'provider': 'apple',
          'email': userCredential.user?.email ?? appleCredential.email,
          'displayName': userCredential.user?.displayName,
          'uid': userCredential.user?.uid,
          'appleUserIdentifier': appleCredential.userIdentifier,
        },
      );
      
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('❌ Apple Sign-In Authorization Error: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          errorMessage = 'Apple Sign-In iptal edildi';
          break;
        case AuthorizationErrorCode.failed:
          errorMessage = 'Apple Sign-In başarısız oldu';
          break;
        case AuthorizationErrorCode.invalidResponse:
          errorMessage = 'Apple Sign-In geçersiz yanıt aldı';
          break;
        case AuthorizationErrorCode.notHandled:
          errorMessage = 'Apple Sign-In işlenemiyor';
          break;
        case AuthorizationErrorCode.unknown:
        default:
          errorMessage = 'Apple Sign-In bilinmeyen hata';
          break;
      }
      
      return AuthResult.failure(
        method: AuthMethod.social,
        errorMessage: errorMessage,
        metadata: {'provider': 'apple', 'errorCode': e.code.toString()},
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error in Apple Sign-In: ${e.code} - ${e.message}');
      return AuthResult.failure(
        method: AuthMethod.social,
        errorMessage: _handleFirebaseAuthException(e),
        metadata: {'provider': 'apple', 'errorCode': e.code},
      );
    } catch (e) {
      debugPrint('❌ Unexpected error in Apple Sign-In: $e');
      return AuthResult.failure(
        method: AuthMethod.social,
        errorMessage: 'Apple Sign-In sırasında beklenmeyen bir hata oluştu',
        metadata: {'provider': 'apple', 'error': e.toString()},
      );
    }
  }

  @override
  Future<bool> isAppleSignInAvailable() async {
    try {
      // On web, Apple Sign-In is available if configured properly
      if (kIsWeb) {
        return true; // Assume available on web if configured
      }
      
      // On iOS, check if Apple Sign-In is available
      if (Platform.isIOS) {
        return await SignInWithApple.isAvailable();
      }
      
      // Not available on other platforms
      return false;
    } catch (e) {
      debugPrint('❌ Error checking Apple Sign-In availability: $e');
      return false;
    }
  }

  @override
  Future<AuthResult> linkAccount(String provider, Map<String, dynamic> credentials) async {
    try {
      await _ensureInitialized();
      
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure(
          method: AuthMethod.social,
          errorMessage: 'Hesap bağlamak için önce giriş yapmalısınız',
          metadata: {'provider': provider},
        );
      }
      
      debugPrint('🔄 Linking account with provider: $provider');
      
      AuthCredential? credential;
      
      switch (provider.toLowerCase()) {
        case 'google':
          credential = await _createGoogleCredential();
          break;
        case 'apple':
          credential = await _createAppleCredential();
          break;
        default:
          return AuthResult.failure(
            method: AuthMethod.social,
            errorMessage: 'Desteklenmeyen sağlayıcı: $provider',
            metadata: {'provider': provider},
          );
      }
      
      if (credential == null) {
        return AuthResult.failure(
          method: AuthMethod.social,
          errorMessage: 'Kimlik bilgileri oluşturulamadı',
          metadata: {'provider': provider},
        );
      }
      
      // Link the credential to the current user
      final userCredential = await user.linkWithCredential(credential);
      
      debugPrint('✅ Account linked successfully with $provider');
      
      return AuthResult.success(
        method: AuthMethod.social,
        metadata: {
          'provider': provider,
          'linkedEmail': userCredential.user?.email,
          'operation': 'link',
        },
      );
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error in account linking: ${e.code} - ${e.message}');
      return AuthResult.failure(
        method: AuthMethod.social,
        errorMessage: _handleFirebaseAuthException(e),
        metadata: {'provider': provider, 'errorCode': e.code, 'operation': 'link'},
      );
    } catch (e) {
      debugPrint('❌ Unexpected error in account linking: $e');
      return AuthResult.failure(
        method: AuthMethod.social,
        errorMessage: 'Hesap bağlama sırasında beklenmeyen bir hata oluştu',
        metadata: {'provider': provider, 'error': e.toString(), 'operation': 'link'},
      );
    }
  }

  @override
  Future<void> unlinkAccount(String provider) async {
    try {
      await _ensureInitialized();
      
      final user = _auth.currentUser;
      if (user == null) {
        throw 'Hesap bağlantısını kesmek için önce giriş yapmalısınız';
      }
      
      debugPrint('🔄 Unlinking account from provider: $provider');
      
      String providerId;
      switch (provider.toLowerCase()) {
        case 'google':
          providerId = 'google.com';
          // Also sign out from Google Sign-In
          await _googleSignIn.signOut();
          break;
        case 'apple':
          providerId = 'apple.com';
          break;
        default:
          throw 'Desteklenmeyen sağlayıcı: $provider';
      }
      
      await user.unlink(providerId);
      
      debugPrint('✅ Account unlinked successfully from $provider');
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error in account unlinking: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error in account unlinking: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getLinkedProviders() async {
    try {
      await _ensureInitialized();
      
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }
      
      final providers = <String>[];
      
      for (final userInfo in user.providerData) {
        switch (userInfo.providerId) {
          case 'google.com':
            providers.add('google');
            break;
          case 'apple.com':
            providers.add('apple');
            break;
          case 'password':
            providers.add('email');
            break;
        }
      }
      
      debugPrint('📋 Linked providers: $providers');
      return providers;
      
    } catch (e) {
      debugPrint('❌ Error getting linked providers: $e');
      return [];
    }
  }

  @override
  Future<void> signOutAll() async {
    try {
      await _ensureInitialized();
      
      debugPrint('🔄 Signing out from all social providers...');
      
      // Sign out from Firebase
      await _auth.signOut();
      
      // Sign out from Google
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('⚠️ Google sign out error (ignorable): $e');
      }
      
      // Note: Apple doesn't have a sign out method
      // The user needs to revoke access from their Apple ID settings
      
      debugPrint('✅ Signed out from all providers');
      
    } catch (e) {
      debugPrint('❌ Error signing out from all providers: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _isInitialized = false;
    _initCompleter = null;
    debugPrint('🧹 SocialLoginService disposed');
  }

  /// Creates Google credential for account linking
  Future<AuthCredential?> _createGoogleCredential() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('❌ Google Sign-In cancelled for linking');
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Google auth tokens not available for linking');
        return null;
      }
      
      return GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } catch (e) {
      debugPrint('❌ Error creating Google credential: $e');
      return null;
    }
  }

  /// Creates Apple credential for account linking
  Future<AuthCredential?> _createAppleCredential() async {
    try {
      if (!await isAppleSignInAvailable()) {
        debugPrint('❌ Apple Sign-In not available for linking');
        return null;
      }
      
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      return OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
    } catch (e) {
      debugPrint('❌ Error creating Apple credential: $e');
      return null;
    }
  }

  /// Handles Firebase Auth exceptions with localized messages
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Bu e-posta adresi farklı bir giriş yöntemi ile kayıtlı. Lütfen o yöntemi kullanın.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri. Lütfen tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre.';
      case 'invalid-verification-code':
        return 'Geçersiz doğrulama kodu.';
      case 'invalid-verification-id':
        return 'Geçersiz doğrulama ID\'si.';
      case 'credential-already-in-use':
        return 'Bu kimlik bilgileri başka bir hesap tarafından kullanılıyor.';
      case 'provider-already-linked':
        return 'Bu sağlayıcı zaten hesabınıza bağlı.';
      case 'no-such-provider':
        return 'Bu sağlayıcı hesabınıza bağlı değil.';
      case 'requires-recent-login':
        return 'Bu işlem için yeniden giriş yapmanız gerekiyor.';
      case 'network-request-failed':
        return 'İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin.';
      case 'too-many-requests':
        return 'Çok fazla istek. Lütfen daha sonra tekrar deneyin.';
      default:
        return e.message ?? 'Bilinmeyen bir hata oluştu';
    }
  }

  /// Handles platform exceptions with localized messages
  String _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'sign_in_failed':
        if (e.message?.contains('10') == true) {
          return 'Google Sign-In yapılandırma hatası. Lütfen uygulamayı yeniden başlatın.';
        }
        return 'Giriş başarısız. Lütfen tekrar deneyin.';
      case 'network_error':
        return 'İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin.';
      case 'sign_in_canceled':
        return 'Giriş iptal edildi.';
      case 'sign_in_required':
        return 'Giriş gerekli.';
      default:
        return e.message ?? 'Platform hatası oluştu';
    }
  }
}