import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/security/security_models.dart';
import '../firebase_auth_service.dart';
import 'interfaces/auth_orchestrator_interface.dart';
import 'interfaces/session_manager_interface.dart';
import 'interfaces/biometric_auth_interface.dart';
import 'interfaces/social_login_interface.dart';
import 'interfaces/security_controller_interface.dart';
import 'interfaces/data_sync_interface.dart';

/// Main authentication orchestrator implementation
/// 
/// Coordinates all authentication methods and manages the overall auth flow.
/// This is the primary entry point for all authentication operations.
class AuthOrchestrator implements IAuthOrchestrator {
  final ISessionManager _sessionManager;
  final IBiometricAuthService _biometricService;
  final ISocialLoginService _socialLoginService;
  final ISecurityController _securityController;
  final DataSyncInterface _dataSyncService;
  final FirebaseAuthService _firebaseAuthService;
  
  final StreamController<AuthState> _authStateController = 
      StreamController<AuthState>.broadcast();
  
  AuthState _currentAuthState = AuthState.unauthenticated();
  bool _isInitialized = false;

  AuthOrchestrator({
    required ISessionManager sessionManager,
    required IBiometricAuthService biometricService,
    required ISocialLoginService socialLoginService,
    required ISecurityController securityController,
    required DataSyncInterface dataSyncService,
    FirebaseAuthService? firebaseAuthService,
  }) : _sessionManager = sessionManager,
       _biometricService = biometricService,
       _socialLoginService = socialLoginService,
       _securityController = securityController,
       _dataSyncService = dataSyncService,
       _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService();

  @override
  Stream<AuthState> get authStateStream => _authStateController.stream;

  @override
  AuthState get currentAuthState => _currentAuthState;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize all services
      await _sessionManager.initialize();
      await _biometricService.initialize();
      await _socialLoginService.initialize();
      await _securityController.initialize();

      // Listen to session state changes
      _sessionManager.sessionStateStream.listen(_onSessionStateChanged);

      // Load initial auth state
      await _loadInitialAuthState();

      _isInitialized = true;
      debugPrint('✅ AuthOrchestrator initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize AuthOrchestrator: $e');
      rethrow;
    }
  }

  @override
  Future<AuthResult> authenticate(
    AuthMethod method, 
    Map<String, dynamic> credentials,
  ) async {
    try {
      await _ensureInitialized();

      // Log authentication attempt
      await _securityController.logSecurityEvent(
        SecurityEvent.authenticationAttempt(
          method: method,
          timestamp: DateTime.now(),
          metadata: {'credentials_provided': credentials.keys.toList()},
        ),
      );

      // Check rate limiting
      final rateLimitOk = await _securityController.checkRateLimit(
        'auth_${method.name}',
        5, // Max 5 attempts
        const Duration(minutes: 15), // Per 15 minutes
      );

      if (!rateLimitOk) {
        final result = AuthResult.failure(
          method: method,
          errorMessage: 'Too many authentication attempts. Please try again later.',
        );
        
        await _securityController.logSecurityEvent(
          SecurityEvent.rateLimitExceeded(
            operation: 'auth_${method.name}',
            timestamp: DateTime.now(),
          ),
        );
        
        return result;
      }

      AuthResult result;

      switch (method) {
        case AuthMethod.emailPassword:
          result = await _authenticateWithEmailPassword(credentials);
          break;
        case AuthMethod.biometric:
          result = await _authenticateWithBiometric(credentials);
          break;
        case AuthMethod.social:
          result = await _authenticateWithSocial(credentials);
          break;
        case AuthMethod.twoFactor:
          result = AuthResult.failure(
            method: method,
            errorMessage: 'Two-factor authentication not yet implemented',
          );
          break;
        case AuthMethod.securityQuestions:
          result = AuthResult.failure(
            method: method,
            errorMessage: 'Security questions authentication not yet implemented',
          );
          break;
      }

      if (result.isSuccess) {
        await _onAuthenticationSuccess(method, result.metadata);
        
        await _securityController.logSecurityEvent(
          SecurityEvent.authenticationSuccess(
            method: method,
            timestamp: DateTime.now(),
            sessionId: _currentAuthState.sessionId,
          ),
        );
      } else {
        await _securityController.logSecurityEvent(
          SecurityEvent.authenticationFailure(
            method: method,
            timestamp: DateTime.now(),
            reason: result.errorMessage ?? 'Unknown error',
          ),
        );
      }

      return result;
    } catch (e) {
      debugPrint('❌ Authentication error: $e');
      
      await _securityController.logSecurityEvent(
        SecurityEvent.authenticationError(
          method: method,
          timestamp: DateTime.now(),
          error: e.toString(),
        ),
      );
      
      return AuthResult.failure(
        method: method,
        errorMessage: _getLocalizedErrorMessage(e),
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _ensureInitialized();

      // Log logout event
      await _securityController.logSecurityEvent(
        SecurityEvent.logout(
          timestamp: DateTime.now(),
          sessionId: _currentAuthState.sessionId,
        ),
      );

      // Sign out from Firebase
      await _firebaseAuthService.signOut();

      // Invalidate session
      await _sessionManager.invalidateSession();

      // Sign out from social providers
      await _socialLoginService.signOutAll();

      // Update auth state
      _currentAuthState = AuthState.unauthenticated();
      _authStateController.add(_currentAuthState);

      debugPrint('✅ Logout completed successfully');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      // Even if logout fails, update local state
      _currentAuthState = AuthState.unauthenticated();
      _authStateController.add(_currentAuthState);
    }
  }

  @override
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _ensureInitialized();

      if (email.isEmpty || !_isValidEmail(email)) {
        return AuthResult.failure(
          method: AuthMethod.emailPassword,
          errorMessage: 'Geçersiz e-posta adresi',
        );
      }

      await _firebaseAuthService.sendPasswordResetEmail(email);

      await _securityController.logSecurityEvent(
        SecurityEvent.passwordResetRequested(
          email: email,
          timestamp: DateTime.now(),
        ),
      );

      return AuthResult.success(
        method: AuthMethod.emailPassword,
        metadata: {'email': email, 'action': 'password_reset_sent'},
      );
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      
      await _securityController.logSecurityEvent(
        SecurityEvent.passwordResetFailed(
          email: email,
          timestamp: DateTime.now(),
          error: e.toString(),
        ),
      );
      
      return AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: _getLocalizedErrorMessage(e),
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      await _ensureInitialized();
      return await _sessionManager.isSessionValid();
    } catch (e) {
      debugPrint('❌ Authentication check error: $e');
      return false;
    }
  }

  @override
  Future<bool> requiresSensitiveAuth() async {
    try {
      await _ensureInitialized();
      return await _sessionManager.requiresReauth();
    } catch (e) {
      debugPrint('❌ Sensitive auth check error: $e');
      return true;
    }
  }

  @override
  Future<AuthResult> authenticateForSensitiveOperation(
    AuthMethod method,
    Map<String, dynamic> credentials,
  ) async {
    try {
      await _ensureInitialized();

      // Validate security requirements for sensitive operation
      final validation = await _securityController.validateSecurityRequirements(
        'sensitive_operation',
        {'method': method.name},
      );

      if (!validation.isValid) {
        return AuthResult.failure(
          method: method,
          errorMessage: validation.errorMessage ?? 'Security validation failed',
        );
      }

      // Perform authentication based on method
      AuthResult result;
      switch (method) {
        case AuthMethod.emailPassword:
          // For sensitive operations, we need to prompt for credentials again
          // For sensitive operations, we need to prompt for credentials again
          final email = credentials['email'] as String?;
          final password = credentials['password'] as String?;
          
          if (email != null && password != null) {
            try {
              await _firebaseAuthService.reauthenticateWithEmailAndPassword(
                email: email, 
                password: password
              );
              result = AuthResult.success(
                method: method,
                metadata: {'sensitive_verified': true},
              );
            } catch (e) {
              result = AuthResult.failure(
                method: method,
                errorMessage: _getLocalizedErrorMessage(e),
              );
            }
          } else {
            result = AuthResult.failure(
              method: method,
              errorMessage: 'E-posta ve şifre gereklidir',
            );
          }
          break;
        case AuthMethod.biometric:
          result = await _biometricService.authenticate(
            reason: 'Authenticate for sensitive operation',
            localizedFallbackTitle: 'Use PIN',
            cancelButtonText: 'Cancel',
          );
          break;
        case AuthMethod.social:
          // For sensitive operations, we might require re-entering credentials
          result = AuthResult.failure(
            method: method,
            errorMessage: 'Social re-authentication not yet implemented',
          );
          break;
        case AuthMethod.twoFactor:
          result = AuthResult.failure(
            method: method,
            errorMessage: 'Two-factor re-authentication not yet implemented',
          );
          break;
        case AuthMethod.securityQuestions:
          result = AuthResult.failure(
            method: method,
            errorMessage: 'Security questions not yet implemented',
          );
          break;
      }

      if (result.isSuccess) {
        // Update session with sensitive auth timestamp
        await _sessionManager.extendSession();
        
        await _securityController.logSecurityEvent(
          SecurityEvent.sensitiveOperationAuth(
            method: method,
            timestamp: DateTime.now(),
            sessionId: _currentAuthState.sessionId,
          ),
        );
      }

      return result;
    } catch (e) {
      debugPrint('❌ Sensitive operation auth error: $e');
      return AuthResult.failure(
        method: method,
        errorMessage: 'Sensitive operation authentication failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> recordActivity() async {
    try {
      await _ensureInitialized();
      await _sessionManager.recordActivity();
    } catch (e) {
      debugPrint('❌ Record activity error: $e');
    }
  }

  @override
  Future<void> onAppBackground() async {
    try {
      await _ensureInitialized();
      await _sessionManager.onAppBackground();
      
      await _securityController.logSecurityEvent(
        SecurityEvent.appBackground(
          timestamp: DateTime.now(),
          sessionId: _currentAuthState.sessionId,
        ),
      );
    } catch (e) {
      debugPrint('❌ App background handling error: $e');
    }
  }

  @override
  Future<void> onAppForeground() async {
    try {
      await _ensureInitialized();
      await _sessionManager.onAppForeground();
      
      await _securityController.logSecurityEvent(
        SecurityEvent.appForeground(
          timestamp: DateTime.now(),
          sessionId: _currentAuthState.sessionId,
        ),
      );
    } catch (e) {
      debugPrint('❌ App foreground handling error: $e');
    }
  }

  @override
  void dispose() {
    _sessionManager.dispose();
    _biometricService.dispose();
    _socialLoginService.dispose();
    _securityController.dispose();
    
    if (!_authStateController.isClosed) {
      _authStateController.close();
    }
    
    debugPrint('✅ AuthOrchestrator disposed');
  }

  // Private methods

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> _loadInitialAuthState() async {
    try {
      final isSessionValid = await _sessionManager.isSessionValid();
      final sessionState = _sessionManager.currentSessionState;
      
      if (isSessionValid && sessionState.isActive && sessionState.sessionData != null) {
        _currentAuthState = AuthState.authenticated(
          sessionId: sessionState.sessionData!.sessionId,
          authMethod: sessionState.authMethod!,
          authTime: sessionState.sessionData!.createdAt,
          metadata: sessionState.metadata,
        );
      } else {
        _currentAuthState = AuthState.unauthenticated();
      }
      
      _authStateController.add(_currentAuthState);
    } catch (e) {
      debugPrint('❌ Failed to load initial auth state: $e');
      _currentAuthState = AuthState.unauthenticated();
      _authStateController.add(_currentAuthState);
    }
  }

  Future<AuthResult> _authenticateWithEmailPassword(Map<String, dynamic> credentials) async {
    try {
      final email = credentials['email'] as String?;
      final password = credentials['password'] as String?;
      final isSignUp = credentials['isSignUp'] as bool? ?? false;
      final displayName = credentials['displayName'] as String?;

      if (email == null || email.isEmpty) {
        return AuthResult.failure(
          method: AuthMethod.emailPassword,
          errorMessage: 'E-posta adresi gerekli',
        );
      }

      if (password == null || password.isEmpty) {
        return AuthResult.failure(
          method: AuthMethod.emailPassword,
          errorMessage: 'Şifre gerekli',
        );
      }

      // Validate email format
      if (!_isValidEmail(email)) {
        return AuthResult.failure(
          method: AuthMethod.emailPassword,
          errorMessage: 'Geçersiz e-posta adresi formatı',
        );
      }

      // Validate password strength for sign up
      if (isSignUp && !_isValidPassword(password)) {
        return AuthResult.failure(
          method: AuthMethod.emailPassword,
          errorMessage: 'Şifre en az 6 karakter olmalı ve güçlü olmalıdır',
        );
      }

      final userCredential = isSignUp
          ? await _firebaseAuthService.signUpWithEmailAndPassword(
              email: email,
              password: password,
              displayName: displayName ?? '',
            )
          : await _firebaseAuthService.signInWithEmailAndPassword(
              email: email,
              password: password,
            );

      if (userCredential?.user != null) {
        return AuthResult.success(
          method: AuthMethod.emailPassword,
          metadata: {
            'userId': userCredential!.user!.uid,
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'isNewUser': isSignUp,
          },
        );
      } else {
        return AuthResult.failure(
          method: AuthMethod.emailPassword,
          errorMessage: 'Kimlik doğrulama başarısız',
        );
      }
    } catch (e) {
      debugPrint('❌ Email/Password authentication error: $e');
      return AuthResult.failure(
        method: AuthMethod.emailPassword,
        errorMessage: _getLocalizedErrorMessage(e),
      );
    }
  }

  Future<AuthResult> _authenticateWithBiometric(Map<String, dynamic> credentials) async {
    final reason = credentials['reason'] as String? ?? 'Authenticate to access the app';
    final fallbackTitle = credentials['fallbackTitle'] as String?;
    final cancelText = credentials['cancelText'] as String?;

    try {
      return await _biometricService.authenticate(
        reason: reason,
        localizedFallbackTitle: fallbackTitle,
        cancelButtonText: cancelText,
      );
    } catch (e) {
      debugPrint('❌ Biometric authentication error: $e');
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: _getLocalizedErrorMessage(e),
      );
    }
  }

  Future<AuthResult> _authenticateWithSocial(Map<String, dynamic> credentials) async {
    final provider = credentials['provider'] as String?;
    
    try {
      switch (provider) {
        case 'google':
          final userCredential = await _firebaseAuthService.signInWithGoogle();
          if (userCredential?.user != null) {
            return AuthResult.success(
              method: AuthMethod.social,
              metadata: {
                'provider': 'google',
                'userId': userCredential!.user!.uid,
                'email': userCredential.user!.email,
                'displayName': userCredential.user!.displayName,
                'photoUrl': userCredential.user!.photoURL,
              },
            );
          } else {
            return AuthResult.failure(
              method: AuthMethod.social,
              errorMessage: 'Google girişi iptal edildi',
            );
          }
        case 'apple':
          return await _socialLoginService.signInWithApple();
        default:
          return AuthResult.failure(
            method: AuthMethod.social,
            errorMessage: 'Desteklenmeyen sosyal medya sağlayıcısı: $provider',
          );
      }
    } catch (e) {
      debugPrint('❌ Social authentication error: $e');
      return AuthResult.failure(
        method: AuthMethod.social,
        errorMessage: _getLocalizedErrorMessage(e),
      );
    }
  }

  /// Validates email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Validates password strength
  bool _isValidPassword(String password) {
    // At least 6 characters
    if (password.length < 6) return false;
    
    // Contains at least one letter and one number
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    
    return hasLetter && hasNumber;
  }

  /// Gets localized error message for exceptions
  String _getLocalizedErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('dns') ||
        errorString.contains('socket')) {
      return 'Bağlantı sorunu yaşanıyor. Lütfen internet bağlantınızı kontrol edin.';
    }
    
    // Firebase Auth errors
    if (errorString.contains('user-not-found')) {
      return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
    }
    if (errorString.contains('wrong-password')) {
      return 'Hatalı şifre girdiniz.';
    }
    if (errorString.contains('email-already-in-use')) {
      return 'Bu e-posta adresi zaten kullanımda.';
    }
    if (errorString.contains('weak-password')) {
      return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
    }
    if (errorString.contains('invalid-email')) {
      return 'Geçersiz e-posta adresi.';
    }
    if (errorString.contains('user-disabled')) {
      return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
    }
    if (errorString.contains('too-many-requests') || errorString.contains('rate limit')) {
      return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
    }
    if (errorString.contains('invalid-credential')) {
      return 'Geçersiz kimlik bilgileri.';
    }
    
    // Biometric errors
    if (errorString.contains('biometric')) {
      if (errorString.contains('not available')) {
        return 'Biyometrik doğrulama bu cihazda mevcut değil.';
      }
      if (errorString.contains('not enrolled')) {
        return 'Biyometrik doğrulama ayarlanmamış. Lütfen cihaz ayarlarından biyometrik doğrulamayı etkinleştirin.';
      }
      if (errorString.contains('cancelled')) {
        return 'Biyometrik doğrulama iptal edildi.';
      }
      return 'Biyometrik doğrulama başarısız. Lütfen tekrar deneyin.';
    }
    
    // Google Sign-In errors
    if (errorString.contains('google')) {
      if (errorString.contains('cancelled') || errorString.contains('aborted')) {
        return 'Google girişi iptal edildi.';
      }
      if (errorString.contains('network')) {
        return 'Google girişi için internet bağlantısı gerekli.';
      }
      return 'Google girişi sırasında bir hata oluştu. Lütfen tekrar deneyin.';
    }
    
    // Session and authentication errors
    if (errorString.contains('session') && errorString.contains('expired')) {
      return 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';
    }
    
    // Generic fallback - ensure it's user-friendly and in Turkish
    if (error is String && error.isNotEmpty && !_containsTechnicalTerms(error)) {
      // If the error is already user-friendly, ensure it ends with punctuation
      final cleanError = error.trim();
      if (!cleanError.endsWith('.') && !cleanError.endsWith('!') && !cleanError.endsWith('?')) {
        return '$cleanError.';
      }
      return cleanError;
    }
    
    // Try to extract a meaningful temporary error code or message for debugging
    String debugInfo = '';
    final codeRegex = RegExp(r'\[(.*?)\]');
    final match = codeRegex.firstMatch(error.toString());
    if (match != null) {
      debugInfo = ' (${match.group(1)})';
    } else if (errorString.contains('code:')) {
       // Extract simple code
       final parts = errorString.split('code:');
       if (parts.length > 1) {
         debugInfo = ' (${parts[1].trim().split(' ').first})';
       }
    }

    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.$debugInfo';
  }

  /// Check if error contains technical terms that should be hidden from users
  bool _containsTechnicalTerms(String error) {
    final technicalTerms = [
      'firebase', 'auth/', 'exception', 'stack trace', 
      'internal', 'debug', 'api', 'token', 'credential', 'socket',
      'dns', 'timeout', 'null', 'undefined'
    ];
    
    final lowerError = error.toLowerCase();
    return technicalTerms.any((term) => lowerError.contains(term));
  }

  Future<void> _onAuthenticationSuccess(
    AuthMethod method, 
    Map<String, dynamic>? metadata,
  ) async {
    try {
      // Generate session ID
      final sessionId = _generateSessionId();
      
      // Create session data
      final sessionData = SessionData.create(
        sessionId: sessionId,
        authMethod: method,
        metadata: metadata,
      );
      
      // Create session
      final sessionCreated = await _sessionManager.createSession(
        sessionData: sessionData,
        authMethod: method,
        metadata: metadata,
      );
      
      if (sessionCreated) {
        // Update auth state
        _currentAuthState = AuthState.authenticated(
          sessionId: sessionId,
          authMethod: method,
          metadata: metadata,
        );
        
        _authStateController.add(_currentAuthState);
        
        // Sync user data
        final userId = metadata?['userId'] as String? ?? _firebaseAuthService.currentUser?.uid;
        if (userId != null) {
          try {
            await _dataSyncService.syncAllUserData(userId);
          } catch (e) {
            debugPrint('⚠️ Initial data sync failed (non-critical): $e');
          }
        }
        
        debugPrint('✅ Authentication successful, session created: $sessionId');
      } else {
        throw Exception('Failed to create session after successful authentication');
      }
    } catch (e) {
      debugPrint('❌ Post-authentication setup failed: $e');
      rethrow;
    }
  }

  void _onSessionStateChanged(SessionState sessionState) {
    try {
      if (!sessionState.isActive && _currentAuthState.isAuthenticated) {
        // Session became inactive, update auth state
        _currentAuthState = AuthState.unauthenticated();
        _authStateController.add(_currentAuthState);
        debugPrint('🔄 Session became inactive, auth state updated');
      } else if (sessionState.isActive && !_currentAuthState.isAuthenticated) {
        // Session became active, update auth state
        if (sessionState.sessionData != null && sessionState.authMethod != null) {
          _currentAuthState = AuthState.authenticated(
            sessionId: sessionState.sessionData!.sessionId,
            authMethod: sessionState.authMethod!,
            authTime: sessionState.sessionData!.createdAt,
            metadata: sessionState.metadata,
          );
          _authStateController.add(_currentAuthState);
          debugPrint('🔄 Session became active, auth state updated');
        }
      }
    } catch (e) {
      debugPrint('❌ Session state change handling error: $e');
    }
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 1000000;
    return '${timestamp}_$random';
  }
}