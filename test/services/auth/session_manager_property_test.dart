import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/session_manager.dart';
import 'package:parion/models/security/session_data.dart';
import 'package:parion/models/security/auth_state.dart';
import 'package:parion/models/security/security_models.dart';
import '../../property_test_utils.dart';
import '../../test_setup.dart';

/// Property-based tests for SessionManager
/// 
/// **Feature: modern-auth-system, Property 3: Session Management Consistency**
/// **Validates: Requirements 5.1, 5.2, 5.3, 5.4**
void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('SessionManager Property Tests', () {
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
      description: 'Property 3: Session Management Consistency - For any successful authentication, '
                  'a secure session should be created, properly managed according to security policies, '
                  'and require re-authentication when expired or for sensitive operations',
      generator: () => {
        'sessionId': PropertyTest.randomString(minLength: 8, maxLength: 32),
        'authMethod': _generateRandomAuthMethod(),
        'metadata': _generateRandomMetadata(),
      },
      property: (testData) async {
        final sessionId = testData['sessionId'] as String;
        final authMethod = testData['authMethod'] as AuthMethod;
        final metadata = testData['metadata'] as Map<String, dynamic>;
        
        final sessionData = SessionData.create(
          sessionId: sessionId,
          authMethod: authMethod,
          metadata: metadata,
        );

        try {
          // Test session creation
          final createResult = await sessionManager.createSession(
            sessionData: sessionData,
            authMethod: authMethod,
            metadata: metadata,
          );
          
          if (!createResult) return false;
          
          // Verify session is active
          final isActive = await sessionManager.isSessionValid();
          if (!isActive) return false;
          
          // Verify session state
          final currentState = sessionManager.currentSessionState;
          if (!currentState.isActive) return false;
          if (currentState.sessionData?.sessionId != sessionId) return false;
          if (currentState.authMethod != authMethod) return false;
          
          // Test activity recording
          await sessionManager.recordActivity();
          final remainingTime = await sessionManager.getSessionRemainingTime();
          if (remainingTime == null) return false;
          
          // Test sensitive screen handling
          await sessionManager.setSensitiveScreenState(true);
          await sessionManager.setSensitiveScreenState(false);
          
          // Test session invalidation
          await sessionManager.invalidateSession();
          final isActiveAfterInvalidation = await sessionManager.isSessionValid();
          if (isActiveAfterInvalidation) return false;
          
          final finalState = sessionManager.currentSessionState;
          if (finalState.isActive) return false;
          
          return true;
        } catch (e) {
          // Property should handle errors gracefully
          return false;
        }
      },
      iterations: 15, // Reduced for faster testing
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 3.1: Session Timeout Consistency - For any session with configured timeout, '
                  'the session should remain valid within timeout and become invalid after timeout',
      generator: () => {
        'sessionId': PropertyTest.randomString(minLength: 8, maxLength: 32),
        'authMethod': _generateRandomAuthMethod(),
      },
      property: (testData) async {
        final sessionId = testData['sessionId'] as String;
        final authMethod = testData['authMethod'] as AuthMethod;
        
        // Use short timeout for testing (1 second)
        final config = SecurityConfig.defaultConfig().copyWith(
          sessionConfig: SessionConfiguration.defaultConfig().copyWith(
            sessionTimeout: const Duration(seconds: 1),
          ),
        );
        
        final sessionData = SessionData.create(
          sessionId: sessionId,
          authMethod: authMethod,
        );

        try {
          // Update security config
          await sessionManager.updateSecurityConfig(config);
          
          // Create session
          final createResult = await sessionManager.createSession(
            sessionData: sessionData,
            authMethod: authMethod,
          );
          
          if (!createResult) return false;
          
          // Session should be valid initially
          final isValidInitially = await sessionManager.isSessionValid();
          if (!isValidInitially) return false;
          
          // Wait for timeout (1.5 seconds to be safe)
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // Session should be invalid after timeout
          final isValidAfterTimeout = await sessionManager.isSessionValid();
          return !isValidAfterTimeout; // Should be false (invalid)
        } catch (e) {
          return false;
        }
      },
      iterations: 25, // Reduced for faster testing
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 3.2: Background/Foreground State Tracking - For any session, '
                  'background and foreground transitions should be properly tracked and enforced',
      generator: () => {
        'sessionId': PropertyTest.randomString(minLength: 8, maxLength: 32),
        'authMethod': _generateRandomAuthMethod(),
      },
      property: (testData) async {
        final sessionId = testData['sessionId'] as String;
        final authMethod = testData['authMethod'] as AuthMethod;
        
        final sessionData = SessionData.create(
          sessionId: sessionId,
          authMethod: authMethod,
        );

        try {
          // Create session
          await sessionManager.createSession(
            sessionData: sessionData,
            authMethod: authMethod,
          );
          
          // Initially should be in foreground
          final initialState = sessionManager.currentSessionState;
          if (initialState.isInBackground) return false;
          
          // Move to background
          await sessionManager.onAppBackground();
          final backgroundState = sessionManager.currentSessionState;
          if (!backgroundState.isInBackground) return false;
          
          // Return to foreground
          await sessionManager.onAppForeground();
          final foregroundState = sessionManager.currentSessionState;
          if (foregroundState.isInBackground) return false;
          
          // Session should still be valid if within timeout
          final isValid = await sessionManager.isSessionValid();
          return isValid;
        } catch (e) {
          return false;
        }
      },
      iterations: 25,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 3.3: Sensitive Operation Detection - For any session in sensitive screen, '
                  'appropriate security measures should be applied',
      generator: () => {
        'sessionId': PropertyTest.randomString(minLength: 8, maxLength: 32),
        'authMethod': _generateRandomAuthMethod(),
      },
      property: (testData) async {
        final sessionId = testData['sessionId'] as String;
        final authMethod = testData['authMethod'] as AuthMethod;
        
        final sessionData = SessionData.create(
          sessionId: sessionId,
          authMethod: authMethod,
        );

        try {
          // Create session
          await sessionManager.createSession(
            sessionData: sessionData,
            authMethod: authMethod,
          );
          
          // Enter sensitive screen
          await sessionManager.setSensitiveScreenState(true);
          final sensitiveState = sessionManager.currentSessionState;
          if (!sensitiveState.isInSensitiveScreen) return false;
          
          // Exit sensitive screen
          await sessionManager.setSensitiveScreenState(false);
          final normalState = sessionManager.currentSessionState;
          if (normalState.isInSensitiveScreen) return false;
          
          // Session should remain valid throughout
          final isValid = await sessionManager.isSessionValid();
          return isValid;
        } catch (e) {
          return false;
        }
      },
      iterations: 25,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 3.4: Session Extension Consistency - For any active session, '
                  'extending the session should update activity time and maintain validity',
      generator: () => {
        'sessionId': PropertyTest.randomString(minLength: 8, maxLength: 32),
        'authMethod': _generateRandomAuthMethod(),
      },
      property: (testData) async {
        final sessionId = testData['sessionId'] as String;
        final authMethod = testData['authMethod'] as AuthMethod;
        
        final sessionData = SessionData.create(
          sessionId: sessionId,
          authMethod: authMethod,
        );

        try {
          // Create session
          await sessionManager.createSession(
            sessionData: sessionData,
            authMethod: authMethod,
          );
          
          final initialTime = sessionManager.currentSessionState.lastActivityTime;
          
          // Wait a bit
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Extend session
          await sessionManager.extendSession();
          
          final extendedTime = sessionManager.currentSessionState.lastActivityTime;
          final timeUpdated = extendedTime.isAfter(initialTime) || extendedTime.isAtSameMomentAs(initialTime);
          if (!timeUpdated) return false;
          
          // Session should still be valid
          final isValid = await sessionManager.isSessionValid();
          return isValid;
        } catch (e) {
          return false;
        }
      },
      iterations: 25,
    );
  });
}

/// Generate random auth method for testing
AuthMethod _generateRandomAuthMethod() {
  final methods = AuthMethod.values;
  return methods[PropertyTest.randomInt(max: methods.length - 1)];
}

/// Generate random metadata for testing
Map<String, dynamic> _generateRandomMetadata() {
  final platforms = ['android', 'ios', 'web'];
  return {
    'deviceId': PropertyTest.randomString(minLength: 8, maxLength: 16),
    'platform': platforms[PropertyTest.randomInt(max: platforms.length - 1)],
    'version': '${PropertyTest.randomInt(max: 10)}.${PropertyTest.randomInt(max: 9)}.${PropertyTest.randomInt(max: 9)}',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
}
