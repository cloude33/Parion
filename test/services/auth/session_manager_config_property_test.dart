import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/session_manager.dart';
import 'package:parion/models/security/session_data.dart';
import 'package:parion/models/security/auth_state.dart';
import 'package:parion/models/security/security_models.dart';
import '../../property_test_utils.dart';

/// Property-based tests for SessionManager Configuration Management
/// 
/// **Feature: modern-auth-system, Property 12: Configuration and Migration Handling**
/// **Validates: Requirements 5.5, 9.5**
void main() {
  group('SessionManager Configuration Property Tests', () {
    late SessionManager sessionManager;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      sessionManager = SessionManager();
      sessionManager.resetForTesting();
    });

    tearDown(() {
      sessionManager.dispose();
    });

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 12: Configuration and Migration Handling - For any session timeout configuration '
                  'or existing user data migration, the system should apply settings correctly and handle '
                  'data migration seamlessly',
      generator: () => {
        'sessionTimeout': Duration(
          seconds: PropertyTest.randomInt(min: 30, max: 3600), // 30 seconds to 1 hour
        ),
        'sensitiveTimeout': Duration(
          seconds: PropertyTest.randomInt(min: 30, max: 1800), // 30 seconds to 30 minutes
        ),
        'backgroundLockDelay': Duration(
          seconds: PropertyTest.randomInt(min: 0, max: 300), // 0 to 5 minutes
        ),
        'enableBackgroundLock': PropertyTest.randomBool(),
        'biometricEnabled': PropertyTest.randomBool(),
        'twoFactorEnabled': PropertyTest.randomBool(),
      },
      property: (testData) async {
        final sessionTimeout = testData['sessionTimeout'] as Duration;
        final sensitiveTimeout = testData['sensitiveTimeout'] as Duration;
        final backgroundLockDelay = testData['backgroundLockDelay'] as Duration;
        final enableBackgroundLock = testData['enableBackgroundLock'] as bool;
        final biometricEnabled = testData['biometricEnabled'] as bool;
        final twoFactorEnabled = testData['twoFactorEnabled'] as bool;

        try {
          // Create a valid security configuration
          final config = SecurityConfig(
            isBiometricEnabled: biometricEnabled,
            isTwoFactorEnabled: twoFactorEnabled,
            sessionTimeout: sessionTimeout,
            biometricConfig: BiometricConfiguration.defaultConfig(),
            sessionConfig: SessionConfiguration(
              sessionTimeout: sessionTimeout,
              sensitiveOperationTimeout: sensitiveTimeout,
              enableBackgroundLock: enableBackgroundLock,
              backgroundLockDelay: backgroundLockDelay,
            ),
            twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
          );

          // Validate configuration first
          final validation = config.validate();
          if (validation != null) {
            // Invalid configuration should be rejected
            final updateResult = await sessionManager.updateSecurityConfig(config);
            return !updateResult; // Should return false for invalid config
          }

          // Valid configuration should be accepted
          final updateResult = await sessionManager.updateSecurityConfig(config);
          if (!updateResult) return false;

          // Test that configuration is applied correctly by creating a session
          final sessionData = SessionData.create(
            sessionId: PropertyTest.randomString(minLength: 8, maxLength: 16),
            authMethod: AuthMethod.emailPassword,
          );

          final sessionCreated = await sessionManager.createSession(
            sessionData: sessionData,
            authMethod: AuthMethod.emailPassword,
          );

          if (!sessionCreated) return false;

          // Verify session is created and active
          final isActive = await sessionManager.isSessionValid();
          if (!isActive) return false;

          // Test that timeout configuration is respected
          final remainingTime = await sessionManager.getSessionRemainingTime();
          if (remainingTime == null) return false;

          // Remaining time should be less than or equal to configured timeout
          if (remainingTime > sessionTimeout) return false;

          return true;
        } catch (e) {
          // Configuration errors should be handled gracefully
          return false;
        }
      },
      iterations: 15,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 12.1: Configuration Validation - For any security configuration, '
                  'invalid configurations should be rejected and valid ones should be accepted',
      generator: () => {
        'sessionTimeoutSeconds': PropertyTest.randomInt(min: -100, max: 86400), // Include invalid values
        'sensitiveTimeoutSeconds': PropertyTest.randomInt(min: -100, max: 7200),
        'backgroundDelaySeconds': PropertyTest.randomInt(min: -100, max: 3600),
        'biometricEnabled': PropertyTest.randomBool(),
        'twoFactorEnabled': PropertyTest.randomBool(),
      },
      property: (testData) async {
        final sessionTimeoutSeconds = testData['sessionTimeoutSeconds'] as int;
        final sensitiveTimeoutSeconds = testData['sensitiveTimeoutSeconds'] as int;
        final backgroundDelaySeconds = testData['backgroundDelaySeconds'] as int;
        final biometricEnabled = testData['biometricEnabled'] as bool;
        final twoFactorEnabled = testData['twoFactorEnabled'] as bool;

        try {
          final config = SecurityConfig(
            isBiometricEnabled: biometricEnabled,
            isTwoFactorEnabled: twoFactorEnabled,
            sessionTimeout: Duration(seconds: sessionTimeoutSeconds),
            biometricConfig: BiometricConfiguration.defaultConfig(),
            sessionConfig: SessionConfiguration(
              sessionTimeout: Duration(seconds: sessionTimeoutSeconds),
              sensitiveOperationTimeout: Duration(seconds: sensitiveTimeoutSeconds),
              enableBackgroundLock: true,
              backgroundLockDelay: Duration(seconds: backgroundDelaySeconds),
            ),
            twoFactorConfig: TwoFactorConfiguration.defaultConfig(),
          );

          final validation = config.validate();
          final updateResult = await sessionManager.updateSecurityConfig(config);

          // If validation failed, update should return false
          if (validation != null) {
            return !updateResult;
          }

          // If validation passed, update should return true
          return updateResult;
        } catch (e) {
          // Exceptions during configuration should result in failure
          return false;
        }
      },
      iterations: 15,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 12.2: Configuration Persistence - For any valid configuration update, '
                  'the configuration should persist and be applied to new sessions',
      generator: () => {
        'sessionTimeout': Duration(
          minutes: PropertyTest.randomInt(min: 1, max: 60), // 1 to 60 minutes
        ),
        'enableBackgroundLock': PropertyTest.randomBool(),
      },
      property: (testData) async {
        final sessionTimeout = testData['sessionTimeout'] as Duration;
        final enableBackgroundLock = testData['enableBackgroundLock'] as bool;

        try {
          // Create first configuration
          final config1 = SecurityConfig.defaultConfig().copyWith(
            sessionConfig: SessionConfiguration.defaultConfig().copyWith(
              sessionTimeout: sessionTimeout,
              enableBackgroundLock: enableBackgroundLock,
            ),
          );

          final updateResult1 = await sessionManager.updateSecurityConfig(config1);
          if (!updateResult1) return false;

          // Create a session with first configuration
          final sessionData1 = SessionData.create(
            sessionId: PropertyTest.randomString(minLength: 8, maxLength: 16),
            authMethod: AuthMethod.emailPassword,
          );

          final sessionCreated1 = await sessionManager.createSession(
            sessionData: sessionData1,
            authMethod: AuthMethod.emailPassword,
          );

          if (!sessionCreated1) return false;

          // Stop the session
          await sessionManager.invalidateSession();

          // Create second configuration with different timeout
          final newTimeout = Duration(
            minutes: PropertyTest.randomInt(min: 1, max: 60),
          );

          final config2 = config1.copyWith(
            sessionConfig: config1.sessionConfig.copyWith(
              sessionTimeout: newTimeout,
            ),
          );

          final updateResult2 = await sessionManager.updateSecurityConfig(config2);
          if (!updateResult2) return false;

          // Create a new session with updated configuration
          final sessionData2 = SessionData.create(
            sessionId: PropertyTest.randomString(minLength: 8, maxLength: 16),
            authMethod: AuthMethod.biometric,
          );

          final sessionCreated2 = await sessionManager.createSession(
            sessionData: sessionData2,
            authMethod: AuthMethod.biometric,
          );

          if (!sessionCreated2) return false;

          // Verify the new session uses the updated configuration
          final remainingTime = await sessionManager.getSessionRemainingTime();
          if (remainingTime == null) return false;

          // The remaining time should be consistent with the new timeout
          return remainingTime <= newTimeout;
        } catch (e) {
          return false;
        }
      },
      iterations: 25,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 12.3: Migration Handling - For any existing session data, '
                  'configuration changes should not break existing sessions but apply to new ones',
      generator: () => {
        'initialTimeout': Duration(
          minutes: PropertyTest.randomInt(min: 5, max: 30),
        ),
        'newTimeout': Duration(
          minutes: PropertyTest.randomInt(min: 1, max: 60),
        ),
      },
      property: (testData) async {
        final initialTimeout = testData['initialTimeout'] as Duration;
        final newTimeout = testData['newTimeout'] as Duration;

        try {
          // Set initial configuration
          final initialConfig = SecurityConfig.defaultConfig().copyWith(
            sessionConfig: SessionConfiguration.defaultConfig().copyWith(
              sessionTimeout: initialTimeout,
            ),
          );

          await sessionManager.updateSecurityConfig(initialConfig);

          // Create session with initial configuration
          final sessionData = SessionData.create(
            sessionId: PropertyTest.randomString(minLength: 8, maxLength: 16),
            authMethod: AuthMethod.emailPassword,
          );

          final sessionCreated = await sessionManager.createSession(
            sessionData: sessionData,
            authMethod: AuthMethod.emailPassword,
          );

          if (!sessionCreated) return false;

          // Verify session is active
          final isActiveInitially = await sessionManager.isSessionValid();
          if (!isActiveInitially) return false;

          // Update configuration while session is active
          final newConfig = initialConfig.copyWith(
            sessionConfig: initialConfig.sessionConfig.copyWith(
              sessionTimeout: newTimeout,
            ),
          );

          final updateResult = await sessionManager.updateSecurityConfig(newConfig);
          if (!updateResult) return false;

          // Existing session should still be valid (migration handling)
          final isActiveAfterUpdate = await sessionManager.isSessionValid();
          if (!isActiveAfterUpdate) return false;

          // Record activity to trigger timer refresh with new configuration
          await sessionManager.recordActivity();

          // Session should still be valid after activity recording
          final isActiveAfterActivity = await sessionManager.isSessionValid();
          return isActiveAfterActivity;
        } catch (e) {
          return false;
        }
      },
      iterations: 25,
    );
  });
}
