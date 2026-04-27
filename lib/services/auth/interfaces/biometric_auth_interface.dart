import '../../../models/security/security_models.dart';

/// Interface for biometric authentication service
/// 
/// This interface defines the contract for biometric authentication
/// operations including availability checks and authentication.
abstract class IBiometricAuthService {
  /// Check if biometric authentication is available on the device
  Future<bool> isAvailable();
  
  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableTypes();
  
  /// Authenticate using biometric
  /// 
  /// [reason] - Localized reason for authentication
  /// [localizedFallbackTitle] - Title for fallback authentication
  /// [cancelButtonText] - Text for cancel button
  /// 
  /// Returns [AuthResult] containing authentication outcome
  Future<AuthResult> authenticate({
    required String reason,
    String? localizedFallbackTitle,
    String? cancelButtonText,
  });
  
  /// Enable biometric authentication for the current user
  Future<void> enableBiometric();
  
  /// Disable biometric authentication for the current user
  Future<void> disableBiometric();
  
  /// Check if biometric is enabled for the current user
  Future<bool> isBiometricEnabled();
  
  /// Initialize the biometric service
  Future<void> initialize();
  
  /// Dispose resources
  void dispose();
}