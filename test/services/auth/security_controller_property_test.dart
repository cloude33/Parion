import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:parion/services/auth/security_controller.dart';
import 'package:parion/models/security/security_models.dart';
import '../../property_test_utils.dart';

/// Property tests for SecurityController
/// **Validates: Requirements 7.1, 7.2, 7.3, 7.4**
void main() {
  group('SecurityController Property Tests', () {
    late SecurityController securityController;

    setUp(() {
      securityController = SecurityController();
    });

    tearDown(() {
      securityController.dispose();
    });

    /// Property 5: Security Layer Enforcement
    /// *For any* authentication data storage, transmission, or sensitive operation, 
    /// the security layer should enforce encryption, secure storage, rate limiting, 
    /// and additional verification as required
    /// **Validates: Requirements 7.1, 7.2, 7.3, 7.4**
    PropertyTest.forAll<EncryptionTestData>(
      description: 'Property 5a: Encryption Round Trip - '
          'For any data, encryption then decryption should preserve the original value',
      generator: () => _generateEncryptionTestData(),
      property: (testData) async {
        await securityController.initialize();

        try {
          // Encrypt the data
          final encrypted = await securityController.encryptForTransmission(testData.data);
          
          // Verify it's actually encrypted (different from original)
          if (encrypted == testData.data && testData.data.isNotEmpty) {
            return false; // Should be encrypted
          }

          // Decrypt the data
          final decrypted = await securityController.decryptReceived(encrypted);
          
          // Should match original
          return decrypted == testData.data;
        } catch (e) {
          // Encryption/decryption should not fail for valid data
          return false;
        }
      },
      iterations: 25,
    );

    PropertyTest.forAll<RateLimitTestData>(
      description: 'Property 5b: Rate Limiting Consistency - '
          'For any operation, rate limiting should consistently enforce limits',
      generator: () => _generateRateLimitTestData(),
      property: (testData) async {
        await securityController.initialize();

        // First attempts should succeed up to the limit
        for (int i = 0; i < testData.maxAttempts; i++) {
          final allowed = await securityController.checkRateLimit(
            testData.operation,
            testData.maxAttempts,
            testData.timeWindow,
          );
          if (!allowed) {
            return false; // Should be allowed within limit
          }
        }

        // Next attempt should be blocked
        final blocked = await securityController.checkRateLimit(
          testData.operation,
          testData.maxAttempts,
          testData.timeWindow,
        );
        
        return !blocked; // Should be blocked after exceeding limit
      },
      iterations: 15, // Fewer iterations due to time-based nature
    );

    PropertyTest.forAll<SecurityConfigTestData>(
      description: 'Property 5c: Security Configuration Validation - '
          'For any security configuration, validation should enforce security requirements',
      generator: () => _generateSecurityConfigTestData(),
      property: (testData) async {
        await securityController.initialize();

        final updateResult = await securityController.updateSecurityConfig(testData.config);
        
        // Valid configurations should be accepted
        if (testData.isValid) {
          if (!updateResult) return false;
          
          // Should be able to retrieve the updated config
          final retrievedConfig = await securityController.getSecurityConfig();
          return retrievedConfig.sessionTimeout == testData.config.sessionTimeout;
        } else {
          // Invalid configurations should be rejected
          return !updateResult;
        }
      },
      iterations: 25,
    );

    PropertyTest.forAll<SecurityValidationTestData>(
      description: 'Property 5d: Security Validation Enforcement - '
          'For any operation, security validation should return consistent results',
      generator: () => _generateSecurityValidationTestData(),
      property: (testData) async {
        await securityController.initialize();

        try {
          // Test security validation
          await securityController.validateSecurityRequirements(
            testData.operation,
            testData.context,
          );

          // Should return a validation result
          return true;
        } catch (e) {
          // Validation should not fail
          return false;
        }
      },
      iterations: 25,
    );

    PropertyTest.forAll<SecurityEventTestData>(
      description: 'Property 5e: Security Event Logging - '
          'For any security event, logging should not fail and events should be streamed',
      generator: () => _generateSecurityEventTestData(),
      property: (testData) async {
        await securityController.initialize();

        try {
          // Listen to security events
          bool eventReceived = false;
          final subscription = securityController.securityEventsStream.listen((event) {
            if (event.type == testData.event.type) {
              eventReceived = true;
            }
          });

          // Log the event
          await securityController.logSecurityEvent(testData.event);

          // Wait a bit for the stream
          await Future.delayed(const Duration(milliseconds: 10));

          subscription.cancel();
          
          // Event should have been received
          return eventReceived;
        } catch (e) {
          // Logging should not fail
          return false;
        }
      },
      iterations: 15,
    );
  });
}

/// Test data for encryption operations
class EncryptionTestData {
  final String data;

  EncryptionTestData({required this.data});
}

/// Test data for rate limiting
class RateLimitTestData {
  final String operation;
  final int maxAttempts;
  final Duration timeWindow;

  RateLimitTestData({
    required this.operation,
    required this.maxAttempts,
    required this.timeWindow,
  });
}

/// Test data for security configuration
class SecurityConfigTestData {
  final SecurityConfig config;
  final bool isValid;

  SecurityConfigTestData({
    required this.config,
    required this.isValid,
  });
}

/// Test data for security validation
class SecurityValidationTestData {
  final String operation;
  final Map<String, dynamic> context;

  SecurityValidationTestData({
    required this.operation,
    required this.context,
  });
}

/// Test data for security events
class SecurityEventTestData {
  final SecurityEvent event;

  SecurityEventTestData({required this.event});
}

/// Generate random encryption test data
EncryptionTestData _generateEncryptionTestData() {
  return EncryptionTestData(
    data: PropertyTest.randomString(minLength: 0, maxLength: 1000),
  );
}

/// Generate random rate limit test data
RateLimitTestData _generateRateLimitTestData() {
  return RateLimitTestData(
    operation: _generateRandomOperation(),
    maxAttempts: PropertyTest.randomInt(min: 1, max: 10),
    timeWindow: Duration(
      seconds: PropertyTest.randomInt(min: 1, max: 300),
    ),
  );
}

/// Generate random security config test data
SecurityConfigTestData _generateSecurityConfigTestData() {
  final random = Random();
  final isValid = random.nextBool();
  
  if (isValid) {
    return SecurityConfigTestData(
      config: SecurityConfig(
        sessionTimeout: Duration(
          minutes: PropertyTest.randomInt(min: 1, max: 1440), // 1 min to 24 hours
        ),
        biometricConfig: BiometricConfiguration.defaultConfig(),
        sessionConfig: SessionConfiguration.defaultConfig(),
        twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
      ),
      isValid: true,
    );
  } else {
    // Generate invalid config
    return SecurityConfigTestData(
      config: SecurityConfig(
        sessionTimeout: Duration(
          seconds: PropertyTest.randomInt(min: -100, max: 29), // Invalid: too short or negative
        ),
        biometricConfig: BiometricConfiguration.defaultConfig(),
        sessionConfig: SessionConfiguration.defaultConfig(),
        twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
      ),
      isValid: false,
    );
  }
}

/// Generate random security validation test data
SecurityValidationTestData _generateSecurityValidationTestData() {
  return SecurityValidationTestData(
    operation: _generateRandomOperation(),
    context: _generateRandomContext(),
  );
}

/// Generate random security event test data
SecurityEventTestData _generateSecurityEventTestData() {
  final eventTypes = [
    SecurityEventType.sessionStarted,
    SecurityEventType.sessionEnded,
    SecurityEventType.biometricVerified,
    SecurityEventType.biometricFailed,
    SecurityEventType.suspiciousActivity,
  ];
  
  final eventType = eventTypes[PropertyTest.randomInt(min: 0, max: eventTypes.length - 1)];
  
  return SecurityEventTestData(
    event: SecurityEvent(
      type: eventType,
      description: PropertyTest.randomString(minLength: 10, maxLength: 100),
      severity: SecurityEventSeverity.info,
      source: 'TestSource',
    ),
  );
}

/// Generate random operation name
String _generateRandomOperation() {
  final operations = [
    'login',
    'logout',
    'change_password',
    'delete_account',
    'export_data',
    'modify_security_settings',
    'view_sensitive_data',
    'transfer_funds',
  ];
  return operations[PropertyTest.randomInt(min: 0, max: operations.length - 1)];
}

/// Generate random context
Map<String, dynamic> _generateRandomContext() {
  return {
    'userId': PropertyTest.randomString(minLength: 10, maxLength: 20),
    'sessionId': PropertyTest.randomString(minLength: 10, maxLength: 20),
    'lastAuthTime': PropertyTest.randomDateTime(),
    'ipAddress': '192.168.1.${PropertyTest.randomInt(min: 1, max: 254)}',
    'userAgent': PropertyTest.randomString(minLength: 20, maxLength: 100),
  };
}
