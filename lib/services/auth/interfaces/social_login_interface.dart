import '../../../models/security/security_models.dart';

/// Interface for social login service
/// 
/// This interface defines the contract for social media authentication
/// including Google, Apple, and account linking functionality.
abstract class ISocialLoginService {
  /// Sign in with Google
  /// 
  /// Returns [AuthResult] containing authentication outcome
  Future<AuthResult> signInWithGoogle();
  
  /// Sign in with Apple
  /// 
  /// Returns [AuthResult] containing authentication outcome
  Future<AuthResult> signInWithApple();
  
  /// Check if Apple Sign-In is available on the device
  Future<bool> isAppleSignInAvailable();
  
  /// Link an account with the specified provider
  /// 
  /// [provider] - Social provider to link (google, apple)
  /// [credentials] - Provider-specific credentials
  /// 
  /// Returns [AuthResult] containing linking outcome
  Future<AuthResult> linkAccount(
    String provider, 
    Map<String, dynamic> credentials,
  );
  
  /// Unlink an account from the specified provider
  /// 
  /// [provider] - Social provider to unlink
  Future<void> unlinkAccount(String provider);
  
  /// Get list of linked providers for current user
  Future<List<String>> getLinkedProviders();
  
  /// Sign out from all social providers
  Future<void> signOutAll();
  
  /// Initialize the social login service
  Future<void> initialize();
  
  /// Dispose resources
  void dispose();
}