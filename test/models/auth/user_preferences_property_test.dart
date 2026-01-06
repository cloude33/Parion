import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/auth/user_preferences.dart';
import '../../property_test_utils.dart';

/// Property-based tests for UserPreferences model
/// 
/// **Feature: modern-auth-system, Property 9: Authentication Preference Persistence**
/// **Validates: Requirements 1.5, 2.5**
/// 
/// This test ensures that user authentication preferences are properly
/// persisted and retrieved across app sessions, maintaining consistency
/// and user experience.
void main() {
  group('UserPreferences Property Tests', () {
    
    // **Property 9: Authentication Preference Persistence**
    // For any user preferences, serializing then deserializing should preserve all data
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 9: Authentication Preference Persistence - Serialization round trip should preserve all preference data',
      generator: () => _generateRandomUserPreferences(),
      property: (preferencesData) {
        // Create UserPreferences from generated data
        final originalPreferences = UserPreferences(
          rememberMe: preferencesData['rememberMe'] as bool,
          preferredAuthMethod: preferencesData['preferredAuthMethod'] as String?,
          biometricEnabled: preferencesData['biometricEnabled'] as bool,
          autoLockTimeoutMinutes: preferencesData['autoLockTimeoutMinutes'] as int,
          showBiometricPrompt: preferencesData['showBiometricPrompt'] as bool,
          lastAuthMethod: preferencesData['lastAuthMethod'] as String?,
          metadata: preferencesData['metadata'] as Map<String, dynamic>,
          createdAt: preferencesData['createdAt'] as DateTime,
          updatedAt: preferencesData['updatedAt'] as DateTime,
        );

        // Serialize to JSON
        final json = originalPreferences.toJson();
        
        // Deserialize from JSON
        final deserializedPreferences = UserPreferences.fromJson(json);

        // Verify all fields are preserved
        return originalPreferences.rememberMe == deserializedPreferences.rememberMe &&
               originalPreferences.preferredAuthMethod == deserializedPreferences.preferredAuthMethod &&
               originalPreferences.biometricEnabled == deserializedPreferences.biometricEnabled &&
               originalPreferences.autoLockTimeoutMinutes == deserializedPreferences.autoLockTimeoutMinutes &&
               originalPreferences.showBiometricPrompt == deserializedPreferences.showBiometricPrompt &&
               originalPreferences.lastAuthMethod == deserializedPreferences.lastAuthMethod &&
               _mapsEqual(originalPreferences.metadata, deserializedPreferences.metadata) &&
               originalPreferences.createdAt.isAtSameMomentAs(deserializedPreferences.createdAt) &&
               originalPreferences.updatedAt.isAtSameMomentAs(deserializedPreferences.updatedAt);
      },
      iterations: 100,
    );

    // Property: Remember Me setting persistence
    PropertyTest.forAll<bool>(
      description: 'Property: Remember Me setting should persist correctly across serialization',
      generator: () => PropertyTest.randomBool(),
      property: (rememberMe) {
        final preferences = UserPreferences.defaultPreferences().setRememberMe(rememberMe);
        final json = preferences.toJson();
        final deserialized = UserPreferences.fromJson(json);
        
        return deserialized.rememberMe == rememberMe;
      },
      iterations: 50,
    );

    // Property: Biometric preferences persistence
    PropertyTest.forAll<bool>(
      description: 'Property: Biometric preferences should persist correctly',
      generator: () => PropertyTest.randomBool(),
      property: (biometricEnabled) {
        final preferences = UserPreferences.defaultPreferences().setBiometricEnabled(biometricEnabled);
        final json = preferences.toJson();
        final deserialized = UserPreferences.fromJson(json);
        
        return deserialized.biometricEnabled == biometricEnabled &&
               deserialized.showBiometricPrompt == biometricEnabled &&
               (biometricEnabled ? deserialized.preferredAuthMethod == 'biometric' : true);
      },
      iterations: 50,
    );

    // Property: Auto-lock timeout validation and persistence
    PropertyTest.forAll<int>(
      description: 'Property: Auto-lock timeout should be validated and persist within valid range',
      generator: () => PropertyTest.randomInt(min: -10, max: 100), // Include invalid values
      property: (timeout) {
        final preferences = UserPreferences.defaultPreferences().setAutoLockTimeout(timeout);
        final json = preferences.toJson();
        final deserialized = UserPreferences.fromJson(json);
        
        // Should clamp to valid range (1-60 minutes)
        final expectedTimeout = timeout.clamp(1, 60);
        return deserialized.autoLockTimeoutMinutes == expectedTimeout;
      },
      iterations: 50,
    );

    // Property: Authentication method usage tracking
    PropertyTest.forAll<String>(
      description: 'Property: Authentication method usage should be tracked and persist',
      generator: () => _generateRandomAuthMethod(),
      property: (authMethod) {
        final preferences = UserPreferences.defaultPreferences().recordAuthMethodUsage(authMethod);
        final json = preferences.toJson();
        final deserialized = UserPreferences.fromJson(json);
        
        return deserialized.lastAuthMethod == authMethod;
      },
      iterations: 50,
    );

    // Property: Preference validation consistency
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Preference validation should be consistent across serialization',
      generator: () => _generateRandomUserPreferences(),
      property: (preferencesData) {
        final originalPreferences = UserPreferences(
          rememberMe: preferencesData['rememberMe'] as bool,
          preferredAuthMethod: preferencesData['preferredAuthMethod'] as String?,
          biometricEnabled: preferencesData['biometricEnabled'] as bool,
          autoLockTimeoutMinutes: preferencesData['autoLockTimeoutMinutes'] as int,
          showBiometricPrompt: preferencesData['showBiometricPrompt'] as bool,
          lastAuthMethod: preferencesData['lastAuthMethod'] as String?,
          metadata: preferencesData['metadata'] as Map<String, dynamic>,
          createdAt: preferencesData['createdAt'] as DateTime,
          updatedAt: preferencesData['updatedAt'] as DateTime,
        );

        final json = originalPreferences.toJson();
        final deserializedPreferences = UserPreferences.fromJson(json);

        // Validation should be consistent
        final originalValid = originalPreferences.isValid;
        final deserializedValid = deserializedPreferences.isValid;
        
        return originalValid == deserializedValid;
      },
      iterations: 100,
    );

    // Property: Metadata preservation
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Metadata should be preserved exactly across serialization',
      generator: () => _generateRandomMetadata(),
      property: (metadata) {
        final preferences = UserPreferences.defaultPreferences().copyWith(metadata: metadata);
        final json = preferences.toJson();
        final deserialized = UserPreferences.fromJson(json);
        
        return _mapsEqual(metadata, deserialized.metadata);
      },
      iterations: 50,
    );
  });
}

/// Generate random user preferences data for testing
Map<String, dynamic> _generateRandomUserPreferences() {
  return {
    'rememberMe': PropertyTest.randomBool(),
    'preferredAuthMethod': PropertyTest.randomBool() ? _generateRandomAuthMethod() : null,
    'biometricEnabled': PropertyTest.randomBool(),
    'autoLockTimeoutMinutes': PropertyTest.randomInt(min: 1, max: 60),
    'showBiometricPrompt': PropertyTest.randomBool(),
    'lastAuthMethod': PropertyTest.randomBool() ? _generateRandomAuthMethod() : null,
    'metadata': _generateRandomMetadata(),
    'createdAt': PropertyTest.randomDateTime(
      start: DateTime(2020, 1, 1),
      end: DateTime.now(),
    ),
    'updatedAt': PropertyTest.randomDateTime(
      start: DateTime(2020, 1, 1),
      end: DateTime.now(),
    ),
  };
}

/// Generate random authentication method
String _generateRandomAuthMethod() {
  final methods = ['biometric', 'pin', 'password', 'google', 'apple'];
  return methods[PropertyTest.randomInt(min: 0, max: methods.length - 1)];
}

/// Generate random metadata
Map<String, dynamic> _generateRandomMetadata() {
  final metadata = <String, dynamic>{};
  final keyCount = PropertyTest.randomInt(min: 0, max: 5);
  
  for (int i = 0; i < keyCount; i++) {
    final key = PropertyTest.randomString(minLength: 3, maxLength: 10);
    final valueType = PropertyTest.randomInt(min: 0, max: 3);
    
    switch (valueType) {
      case 0:
        metadata[key] = PropertyTest.randomString(minLength: 1, maxLength: 20);
        break;
      case 1:
        metadata[key] = PropertyTest.randomInt(min: -1000, max: 1000);
        break;
      case 2:
        metadata[key] = PropertyTest.randomBool();
        break;
      case 3:
        metadata[key] = PropertyTest.randomDouble(min: -100.0, max: 100.0);
        break;
    }
  }
  
  return metadata;
}

/// Helper function to compare maps for equality
bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
  if (map1.length != map2.length) return false;
  
  for (final key in map1.keys) {
    if (!map2.containsKey(key)) return false;
    if (map1[key] != map2[key]) return false;
  }
  
  return true;
}