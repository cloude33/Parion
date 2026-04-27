import 'dart:async';
import '../../../models/security/security_models.dart';

/// Interface for security controller
/// 
/// This interface defines the contract for security enforcement,
/// including secure storage, encryption, and security policies.
abstract class ISecurityController {
  /// Security events stream
  Stream<SecurityEvent> get securityEventsStream;
  
  /// Store data securely
  /// 
  /// [key] - Storage key
  /// [value] - Value to store
  /// [encrypted] - Whether to encrypt the value
  Future<void> storeSecurely(
    String key, 
    String value, {
    bool encrypted = true,
  });
  
  /// Retrieve data securely
  /// 
  /// [key] - Storage key
  /// [encrypted] - Whether the value is encrypted
  /// 
  /// Returns the stored value or null if not found
  Future<String?> retrieveSecurely(
    String key, {
    bool encrypted = true,
  });
  
  /// Delete stored data
  /// 
  /// [key] - Storage key to delete
  Future<void> deleteSecurely(String key);
  
  /// Encrypt data for transmission
  /// 
  /// [data] - Data to encrypt
  /// 
  /// Returns encrypted data
  Future<String> encryptForTransmission(String data);
  
  /// Decrypt received data
  /// 
  /// [encryptedData] - Encrypted data to decrypt
  /// 
  /// Returns decrypted data
  Future<String> decryptReceived(String encryptedData);
  
  /// Check rate limiting for operation
  /// 
  /// [operation] - Operation identifier
  /// [maxAttempts] - Maximum attempts allowed
  /// [timeWindow] - Time window for rate limiting
  /// 
  /// Returns true if operation is allowed
  Future<bool> checkRateLimit(
    String operation,
    int maxAttempts,
    Duration timeWindow,
  );
  
  /// Log security event
  /// 
  /// [event] - Security event to log
  Future<void> logSecurityEvent(SecurityEvent event);
  
  /// Get security configuration
  Future<SecurityConfig> getSecurityConfig();
  
  /// Update security configuration
  /// 
  /// [config] - New security configuration
  Future<bool> updateSecurityConfig(SecurityConfig config);
  
  /// Validate security requirements for operation
  /// 
  /// [operation] - Operation to validate
  /// [context] - Operation context
  /// 
  /// Returns validation result
  Future<SecurityValidationResult> validateSecurityRequirements(
    String operation,
    Map<String, dynamic> context,
  );
  
  /// Initialize the security controller
  Future<void> initialize();
  
  /// Dispose resources
  void dispose();
}

/// Security validation result
class SecurityValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> requiredActions;
  final SecurityLevel requiredLevel;

  const SecurityValidationResult({
    required this.isValid,
    this.errorMessage,
    this.requiredActions = const [],
    this.requiredLevel = SecurityLevel.medium,
  });

  factory SecurityValidationResult.valid() {
    return const SecurityValidationResult(isValid: true);
  }

  factory SecurityValidationResult.invalid({
    required String errorMessage,
    List<String> requiredActions = const [],
    SecurityLevel requiredLevel = SecurityLevel.medium,
  }) {
    return SecurityValidationResult(
      isValid: false,
      errorMessage: errorMessage,
      requiredActions: requiredActions,
      requiredLevel: requiredLevel,
    );
  }
}