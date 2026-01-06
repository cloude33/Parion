import 'dart:async';
import '../../../models/security/security_models.dart';

/// Interface for the main authentication orchestrator
/// 
/// This interface defines the contract for coordinating all authentication methods
/// and managing the overall authentication flow.
abstract class IAuthOrchestrator {
  /// Authentication state stream
  Stream<AuthState> get authStateStream;
  
  /// Current authentication state
  AuthState get currentAuthState;
  
  /// Authenticate using the specified method
  /// 
  /// [method] - The authentication method to use
  /// [credentials] - Authentication credentials (method-specific)
  /// 
  /// Returns [AuthResult] containing the authentication outcome
  Future<AuthResult> authenticate(
    AuthMethod method, 
    Map<String, dynamic> credentials,
  );
  
  /// Sign out from all authentication methods
  Future<void> logout();
  
  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email);
  
  /// Check if user is currently authenticated
  Future<bool> isAuthenticated();
  
  /// Check if sensitive operation authentication is required
  Future<bool> requiresSensitiveAuth();
  
  /// Authenticate for sensitive operations
  Future<AuthResult> authenticateForSensitiveOperation(
    AuthMethod method,
    Map<String, dynamic> credentials,
  );
  
  /// Record user activity to extend session
  Future<void> recordActivity();
  
  /// Handle app going to background
  Future<void> onAppBackground();
  
  /// Handle app coming to foreground
  Future<void> onAppForeground();
  
  /// Initialize the orchestrator
  Future<void> initialize();
  
  /// Dispose resources
  void dispose();
}