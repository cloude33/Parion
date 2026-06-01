import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../firebase_options.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Enhanced Firebase Authentication Service with improved error handling,
/// retry mechanisms, and proper credential validation
/// 
/// Implements Requirements:
/// - 2.1: Email/password authentication via Firebase
/// - 2.2: Proper error handling with localized messages
/// - 2.3: Password reset functionality
/// - 2.4: Real-time validation and retry mechanisms
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Retry configuration
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _networkTimeout = Duration(seconds: 30);

  // Rate limiting for failed attempts
  final Map<String, DateTime> _lastFailedAttempts = {};
  final Map<String, int> _failedAttemptCounts = {};
  static const Duration _rateLimitWindow = Duration(minutes: 5);
  static const int _maxFailedAttemptsPerWindow = 5;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Validates email format
  /// 
  /// Returns null if valid, error message if invalid
  /// Implements Requirement 2.4: Real-time validation
  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'E-posta adresi gereklidir';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    
    return null;
  }

  /// Validates password strength
  /// 
  /// Returns null if valid, error message if invalid
  /// Implements Requirement 2.4: Real-time validation
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Şifre gereklidir';
    }
    
    if (password.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    
    return null;
  }

  /// Validates display name
  /// 
  /// Returns null if valid, error message if invalid
  String? validateDisplayName(String displayName) {
    if (displayName.isEmpty) {
      return 'Ad soyad gereklidir';
    }
    
    if (displayName.length < 2) {
      return 'Ad soyad en az 2 karakter olmalıdır';
    }
    
    if (displayName.length > 50) {
      return 'Ad soyad en fazla 50 karakter olabilir';
    }
    
    return null;
  }

  /// Checks if email is rate limited due to failed attempts
  /// 
  /// Implements security measure against brute force attacks
  @visibleForTesting
  bool isRateLimited(String email) {
    final now = DateTime.now();
    final lastAttempt = _lastFailedAttempts[email];
    final failedCount = _failedAttemptCounts[email] ?? 0;
    
    if (lastAttempt == null) return false;
    
    // Reset counter if window has passed
    if (now.difference(lastAttempt) > _rateLimitWindow) {
      _lastFailedAttempts.remove(email);
      _failedAttemptCounts.remove(email);
      return false;
    }
    
    return failedCount >= _maxFailedAttemptsPerWindow;
  }

  /// Records a failed authentication attempt
  @visibleForTesting
  void recordFailedAttempt(String email) {
    final now = DateTime.now();
    _lastFailedAttempts[email] = now;
    _failedAttemptCounts[email] = (_failedAttemptCounts[email] ?? 0) + 1;
  }

  /// Clears failed attempts for successful authentication
  @visibleForTesting
  void clearFailedAttempts(String email) {
    _lastFailedAttempts.remove(email);
    _failedAttemptCounts.remove(email);
  }

  /// Creates a new user account with email and password
  /// 
  /// Implements Requirements:
  /// - 2.1: Email/password authentication via Firebase
  /// - 2.2: Proper error handling with localized messages
  /// - 2.4: Real-time validation and retry mechanisms
  /// 
  /// [email] User's email address
  /// [password] User's password
  /// [displayName] User's display name
  /// 
  /// Returns [UserCredential] on success
  /// Throws localized error message on failure
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Validate inputs
    final emailError = validateEmail(email);
    if (emailError != null) throw emailError;
    
    final passwordError = validatePassword(password);
    if (passwordError != null) throw passwordError;
    
    final nameError = validateDisplayName(displayName);
    if (nameError != null) throw nameError;

    // Check rate limiting
    if (isRateLimited(email)) {
      throw 'Çok fazla başarısız deneme. ${_rateLimitWindow.inMinutes} dakika sonra tekrar deneyin.';
    }

    return await _executeWithRetry<UserCredential?>(
      operation: () async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await credential.user?.updateDisplayName(displayName);
        await credential.user?.reload();

        // Clear failed attempts on success
        clearFailedAttempts(email);
        
        debugPrint('User registration successful: ${credential.user?.email}');
        return credential;
      },
      onError: (error) {
        recordFailedAttempt(email);
        debugPrint('Registration failed for $email: $error');
      },
      operationName: 'User Registration',
    );
  }

  /// Signs in user with email and password
  /// 
  /// Implements Requirements:
  /// - 2.1: Email/password authentication via Firebase
  /// - 2.2: Proper error handling with localized messages
  /// - 2.4: Real-time validation and retry mechanisms
  /// 
  /// [email] User's email address
  /// [password] User's password
  /// 
  /// Returns [UserCredential] on success
  /// Throws localized error message on failure
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    final emailError = validateEmail(email);
    if (emailError != null) throw emailError;
    
    if (password.isEmpty) {
      throw 'Şifre gereklidir';
    }

    // Check rate limiting
    if (isRateLimited(email)) {
      throw 'Çok fazla başarısız deneme. ${_rateLimitWindow.inMinutes} dakika sonra tekrar deneyin.';
    }

    return await _executeWithRetry<UserCredential?>(
      operation: () async {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Clear failed attempts on success
        clearFailedAttempts(email);
        
        debugPrint('User sign in successful: ${credential.user?.email}');
        return credential;
      },
      onError: (error) {
        recordFailedAttempt(email);
        debugPrint('Sign in failed for $email: $error');
      },
      operationName: 'User Sign In',
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔄 Google Sign-In başlatılıyor...');

      // Firebase'in başlatıldığından emin ol
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 10));
          debugPrint('✅ Firebase lazily initialized for Google Sign-In');
        }
      } catch (initError) {
        debugPrint('❌ Firebase initialization in signInWithGoogle failed: $initError');
      }

      if (kIsWeb) {
        // Web için Google Identity Services (GIS) veya signInWithPopup kullan
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope(
          'https://www.googleapis.com/auth/userinfo.profile',
        );

        debugPrint(
          '🌐 Web platformu algılandı, signInWithPopup kullanılıyor...',
        );
        final userCredential = await _auth.signInWithPopup(googleProvider);
        debugPrint('✅ Google Sign-In başarılı: ${userCredential.user?.email}');
        return userCredential;
      } else {
        // Mobil için mevcut GoogleSignIn akışını kullan
        
        // Initialize GoogleSignIn
        await GoogleSignIn.instance.initialize(
          serverClientId: '195092382674-ca5q05m7idrstrqpfb5bc6e00thqiu20.apps.googleusercontent.com',
        );
        
        // Önce mevcut oturumu temizle
        try {
          await GoogleSignIn.instance.signOut();
          await _auth.signOut();
        } catch (e) {
          debugPrint('⚠️ Sign out error (ignorable): $e');
        }
        
        debugPrint('🔄 Google Sign-In başlatılıyor...');
        
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
        
        debugPrint('✅ Google kullanıcısı seçildi: ${googleUser.email}');

        // Google kimlik doğrulama detaylarını al
        final auth = await googleUser.authorizationClient.authorizeScopes(['email']);
        final googleAuth = googleUser.authentication;

        debugPrint('Access Token: ${auth.accessToken.isNotEmpty ? 'OK' : 'EMPTY'}');
        debugPrint('ID Token: ${googleAuth.idToken?.isNotEmpty ?? false ? 'OK' : 'EMPTY'}');

        debugPrint('✅ Google auth tokens alındı');

        // Firebase credential oluştur
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: googleAuth.idToken,
        );

        debugPrint('🔄 Firebase ile giriş yapılıyor...');
        debugPrint('   Firebase Auth proje: ${_auth.app.options.projectId}');
        debugPrint('   Credential provider: ${credential.providerId}');
        
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          debugPrint('✅ Google Sign-In başarılı: ${userCredential.user?.email}');
          return userCredential;
        } on FirebaseAuthException catch (e) {
          debugPrint('❌ Firebase signInWithCredential failed: ${e.code}');
          debugPrint('   Message: ${e.message}');
          debugPrint('   Credential: accessToken=${auth.accessToken.isNotEmpty ? 'OK' : 'EMPTY'}, idToken=${googleAuth.idToken?.isNotEmpty ?? false ? 'OK' : 'EMPTY'}');
          
          // Özel olarak network-request-failed için daha açıklayıcı hata
          if (e.code == 'network-request-failed') {
            throw 'Firebase sunucularına bağlanılamadı (network-request-failed).\n'
                'Muhtemel nedenler:\n'
                '• Firebase Console\'da Authentication > Sign-in method > Google oturum açma etkinleştirilmemiş\n'
                '• Firebase Console\'da Authentication ayarlarında Destek E-postası belirtilmemiş\n'
                '• google-services.json güncel değil (flutterfire configure komutunu çalıştırın)\n'
                '• Cihaz Firebase sunucularına erişemiyor (VPN, güvenlik duvarı veya DNS sorunu)';
          }
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw handleAuthException(e);
    } on PlatformException catch (e) {
      debugPrint('❌ Platform Exception: ${e.code} - ${e.message}');
      debugPrint('❌ Platform Exception Details: ${e.details}');
      
      if (e.code == 'sign_in_failed') {
        final msg = e.message ?? '';
        if (msg.contains('12500') || msg.contains('10')) {
          throw 'Google Sign-In yapılandırma hatası (${msg.contains('12500') ? '12500' : '10'}). Muhtemel nedenler:\n'
              '• SHA-1 sertifika parmak izi Firebase konsoluna eklenmemiş\n'
              '• google-services.json dosyası güncel değil\n'
              '• Firebase projesinde Destek E-postası ayarlanmamış';
        }
        throw 'Google Sign-In başarısız. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.';
      }
      throw 'Google Sign-In hatası: ${e.message ?? e.code}';
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      if (e is String && e.isNotEmpty) {
        rethrow;
      }
      throw 'Google Sign-In sırasında beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await _auth.signOut();
      } else {
        await Future.wait([_auth.signOut(), GoogleSignIn.instance.signOut()]);
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Sends password reset email to user
  /// 
  /// Implements Requirements:
  /// - 2.3: Password reset functionality
  /// - 2.2: Proper error handling with localized messages
  /// - 2.4: Email validation for reset requests
  /// 
  /// [email] User's email address
  /// 
  /// Throws localized error message on failure
  Future<void> sendPasswordResetEmail(String email) async {
    // Validate email
    final emailError = validateEmail(email);
    if (emailError != null) throw emailError;

    // Check rate limiting
    if (isRateLimited(email)) {
      throw 'Çok fazla şifre sıfırlama talebi. ${_rateLimitWindow.inMinutes} dakika sonra tekrar deneyin.';
    }

    return await _executeWithRetry<void>(
      operation: () async {
        await _auth.sendPasswordResetEmail(email: email);
        debugPrint('Password reset email sent to: $email');
      },
      onError: (error) {
        recordFailedAttempt(email);
        debugPrint('Password reset failed for $email: $error');
      },
      operationName: 'Password Reset',
    );
  }

  /// Confirms password reset with the provided code and new password
  /// 
  /// Implements Requirement 2.3: Complete password reset flow
  /// 
  /// [code] Password reset code from email
  /// [newPassword] New password to set
  /// 
  /// Throws localized error message on failure
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    // Validate new password
    final passwordError = validatePassword(newPassword);
    if (passwordError != null) throw passwordError;

    if (code.isEmpty) {
      throw 'Doğrulama kodu gereklidir';
    }

    return await _executeWithRetry<void>(
      operation: () async {
        await _auth.confirmPasswordReset(
          code: code,
          newPassword: newPassword,
        );
        debugPrint('Password reset confirmed successfully');
      },
      onError: (error) {
        debugPrint('Password reset confirmation failed: $error');
      },
      operationName: 'Password Reset Confirmation',
    );
  }

  /// Verifies password reset code without resetting password
  /// 
  /// Implements Requirement 2.3: Password reset flow validation
  /// 
  /// [code] Password reset code from email
  /// 
  /// Returns email address associated with the code
  /// Throws localized error message on failure
  Future<String> verifyPasswordResetCode(String code) async {
    if (code.isEmpty) {
      throw 'Doğrulama kodu gereklidir';
    }

    return await _executeWithRetry<String>(
      operation: () async {
        final email = await _auth.verifyPasswordResetCode(code);
        debugPrint('Password reset code verified for: $email');
        return email;
      },
      onError: (error) {
        debugPrint('Password reset code verification failed: $error');
      },
      operationName: 'Password Reset Code Verification',
    );
  }

  /// Checks if password reset code is valid
  /// 
  /// [code] Password reset code from email
  /// 
  /// Returns true if code is valid, false otherwise
  Future<bool> isPasswordResetCodeValid(String code) async {
    try {
      await verifyPasswordResetCode(code);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generic retry mechanism for Firebase operations
  /// 
  /// [operation] The Firebase operation to execute
  /// [onError] Callback for error handling
  /// [operationName] Name for logging purposes
  /// 
  /// Returns result of the operation
  /// Implements Requirement 2.4: Retry mechanisms for network issues
  Future<T> _executeWithRetry<T>({
    required Future<T> Function() operation,
    required void Function(dynamic error) onError,
    required String operationName,
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts < _maxRetryAttempts) {
      attempts++;
      
      try {
        // Add timeout to prevent hanging
        return await operation().timeout(_networkTimeout);
      } catch (e) {
        lastError = e;

        // On Flutter Web, FirebaseAuthException may not be caught by typed catch blocks
        // due to JS interop. Check the type explicitly.
        if (e is FirebaseAuthException) {
          final errorMessage = handleAuthException(e);
          
          if (shouldNotRetry(e.code)) {
            onError(errorMessage);
            throw errorMessage;
          }
          
          debugPrint('$operationName attempt $attempts failed: ${e.code} - ${e.message}');
          
          if (attempts >= _maxRetryAttempts) {
            onError(errorMessage);
            throw errorMessage;
          }
          
          await Future.delayed(_retryDelay * attempts);
        } else if (e is TimeoutException) {
          debugPrint('$operationName attempt $attempts timed out');
          
          if (attempts >= _maxRetryAttempts) {
            const errorMessage = 'İşlem zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';
            onError(errorMessage);
            throw errorMessage;
          }
          
          await Future.delayed(_retryDelay * attempts);
        } else if (e is SocketException) {
          debugPrint('$operationName attempt $attempts failed: Network error');
          
          if (attempts >= _maxRetryAttempts) {
            const errorMessage = 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
            onError(errorMessage);
            throw errorMessage;
          }
          
          await Future.delayed(_retryDelay * attempts);
        } else if (e is String) {
          // Already a localized error message thrown from within operation
          onError(e);
          rethrow;
        } else {
          debugPrint('$operationName attempt $attempts failed: $e');
          
          if (attempts >= _maxRetryAttempts) {
            final errorMessage = 'Beklenmeyen bir hata oluştu: ${e.toString()}';
            onError(errorMessage);
            throw errorMessage;
          }
          
          await Future.delayed(_retryDelay * attempts);
        }
      }
    }

    // This should never be reached, but just in case
    final errorMessage = 'İşlem başarısız oldu: ${lastError.toString()}';
    onError(errorMessage);
    throw errorMessage;
  }

  /// Determines if an error should not be retried
  /// 
  /// [errorCode] Firebase auth error code
  /// 
  /// Returns true if the error should not be retried
  @visibleForTesting
  bool shouldNotRetry(String errorCode) {
    const nonRetryableErrors = {
      'user-not-found',
      'wrong-password',
      'email-already-in-use',
      'weak-password',
      'invalid-email',
      'user-disabled',
      'invalid-credential',
      'operation-not-allowed',
      'account-exists-with-different-credential',
      'credential-already-in-use',
    };
    
    return nonRetryableErrors.contains(errorCode);
  }

  Future<void> reauthenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu açık değil');

      if (user.email != email) {
        throw Exception('Girilen e-posta adresi mevcut kullanıcı ile eşleşmiyor');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      debugPrint('Re-authentication successful for: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('Re-authentication error: ${e.code} - ${e.message}');
      throw handleAuthException(e);
    } catch (e) {
      debugPrint('Re-authentication error: $e');
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu açık değil');

      final email = user.email;
      if (email == null) throw Exception('E-posta adresi bulunamadı');

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      debugPrint('Update password error: ${e.code} - ${e.message}');
      throw handleAuthException(e);
    } catch (e) {
      debugPrint('Update password error: $e');
      rethrow;
    }
  }

  bool get isSignedIn => _auth.currentUser != null;

  /// Handles Firebase Auth exceptions and returns localized error messages
  /// 
  /// Implements Requirement 2.2: Proper error handling with localized messages
  /// 
  /// [e] Firebase auth exception
  /// 
  /// Returns localized error message
  @visibleForTesting
  String handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      // User authentication errors
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı. Lütfen e-posta adresinizi kontrol edin veya yeni hesap oluşturun.';
      case 'wrong-password':
        return 'Hatalı şifre girdiniz. Lütfen şifrenizi kontrol edin veya şifre sıfırlama seçeneğini kullanın.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri. Lütfen e-posta ve şifrenizi kontrol edin.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış. Destek ekibi ile iletişime geçin.';
      
      // Registration errors
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda. Giriş yapmayı deneyin veya farklı bir e-posta adresi kullanın.';
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen en az 6 karakter içeren, harf ve rakam kombinasyonu olan güçlü bir şifre seçin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi formatı. Lütfen geçerli bir e-posta adresi girin.';
      
      // Network and service errors
      case 'network-request-failed':
        return 'Firebase sunucularına bağlanılamadı. Lütfen internet bağlantınızı kontrol edin,'
            ' VPN varsa kapatın ve Firebase Console\'da Authentication ayarlarını doğrulayın.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme yapıldı. Güvenlik nedeniyle geçici olarak engellendiniz. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor. Lütfen daha sonra tekrar deneyin.';
      case 'internal-error':
        return 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.';
      
      // Password reset specific errors
      case 'missing-email':
        return 'E-posta adresi gereklidir.';
      case 'invalid-continue-uri':
        return 'Geçersiz devam URL\'si.';
      case 'unauthorized-continue-uri':
        return 'Yetkisiz devam URL\'si.';
      case 'expired-action-code':
        return 'Şifre sıfırlama kodu süresi dolmuş. Lütfen yeni bir kod talep edin.';
      case 'invalid-action-code':
        return 'Geçersiz şifre sıfırlama kodu. Lütfen kodu kontrol edin veya yeni bir kod talep edin.';
      case 'missing-action-code':
        return 'Şifre sıfırlama kodu eksik.';
      
      // Account linking errors
      case 'account-exists-with-different-credential':
        return 'Bu e-posta adresi farklı bir giriş yöntemi ile kayıtlı. Lütfen o yöntemi kullanın.';
      case 'credential-already-in-use':
        return 'Bu kimlik bilgileri başka bir hesap tarafından kullanılıyor.';
      
      // Session and token errors
      case 'requires-recent-login':
        return 'Bu işlem için yeniden giriş yapmanız gerekiyor. Lütfen çıkış yapıp tekrar giriş yapın.';
      case 'user-token-expired':
        return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
      case 'invalid-user-token':
        return 'Geçersiz kullanıcı oturumu. Lütfen tekrar giriş yapın.';
      
      // Default case
      default:
        debugPrint('Unhandled Firebase Auth error: ${e.code} - ${e.message}');
        return e.message ?? 'Bilinmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
