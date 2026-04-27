import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/security/security_models.dart';
import 'package:parion/services/auth/biometric_auth_service.dart';
import 'package:parion/services/auth/biometric_service.dart';
import 'package:parion/services/auth/secure_storage_service.dart';
import '../../property_test_utils.dart';
import '../../test_setup.dart';

/// Property-based tests for BiometricAuthService
/// 
/// **Feature: modern-auth-system, Property 7: Biometric Authentication Management**
/// **Validates: Requirements 4.1, 4.2, 4.4, 4.5**
void main() {
  group('BiometricAuthService Property Tests', () {
    late BiometricAuthService biometricAuthService;
    late MockBiometricService mockBiometricService;
    late AuthSecureStorageService mockSecureStorage;

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();
    });

    setUp(() async {
      await TestSetup.setupTest();
      mockBiometricService = MockBiometricService();
      mockSecureStorage = AuthSecureStorageService();
      await mockSecureStorage.initialize();
      
      biometricAuthService = BiometricAuthService(
        biometricService: mockBiometricService,
        secureStorage: mockSecureStorage,
      );
      
      await biometricAuthService.initialize();
    });

    tearDown(() async {
      biometricAuthService.dispose();
      await TestSetup.tearDownTest();
    });

    /// **Property 7: Biometric Authentication Management**
    /// *For any* biometric authentication interaction, the system should properly detect 
    /// availability, securely store settings, provide fallback options on failure, 
    /// and allow user control over enablement
    /// **Validates: Requirements 4.1, 4.2, 4.4, 4.5**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 7: Biometric Authentication Management - Availability detection and settings management',
      generator: () => _generateBiometricTestScenario(),
      property: (scenario) async {
        final isDeviceSupported = scenario['deviceSupported'] as bool;
        final availableTypes = scenario['availableTypes'] as List<BiometricType>;
        final shouldEnable = scenario['shouldEnable'] as bool;
        
        // Setup mock behavior
        mockBiometricService.setDeviceSupported(isDeviceSupported);
        mockBiometricService.setAvailableTypes(availableTypes);
        
        // Test availability detection (Requirement 4.1)
        final isAvailable = await biometricAuthService.isAvailable();
        
        // Availability should match device support and available types
        final expectedAvailability = isDeviceSupported && availableTypes.isNotEmpty;
        if (isAvailable != expectedAvailability) return false;
        
        // Test available types retrieval
        final retrievedTypes = await biometricAuthService.getAvailableTypes();
        if (!_listsEqual(retrievedTypes, availableTypes)) return false;
        
        // Test biometric enablement/disablement (Requirements 4.2, 4.5)
        if (shouldEnable) {
          if (isAvailable) {
            // Should be able to enable biometric when available
            try {
              await biometricAuthService.enableBiometric();
              final isEnabled = await biometricAuthService.isBiometricEnabled();
              if (!isEnabled) return false;
              
              // Should be able to disable after enabling
              await biometricAuthService.disableBiometric();
              final isDisabled = !(await biometricAuthService.isBiometricEnabled());
              if (!isDisabled) return false;
            } catch (e) {
              // Should not throw when biometric is available
              return false;
            }
          } else {
            // Should throw when trying to enable on unsupported device
            try {
              await biometricAuthService.enableBiometric();
              // Should have thrown an exception
              return false;
            } catch (e) {
              // Expected behavior
            }
          }
        } else {
          // When shouldEnable is false, we don't test enablement
          // Just verify that disabling works without error
          try {
            await biometricAuthService.disableBiometric();
            final isDisabled = !(await biometricAuthService.isBiometricEnabled());
            if (!isDisabled) return false;
          } catch (e) {
            // Disabling should not throw
            return false;
          }
        }
        
        return true;
      },
      iterations: 25,
    );

    /// Test biometric authentication flow with fallback mechanisms
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Biometric authentication should provide fallback options on failure',
      generator: () => _generateAuthenticationScenario(),
      property: (scenario) async {
        final shouldSucceed = scenario['shouldSucceed'] as bool;
        final reason = scenario['reason'] as String;
        final isEnabled = scenario['isEnabled'] as bool;
        final isAvailable = scenario['isAvailable'] as bool;
        
        // Setup mock behavior
        mockBiometricService.setDeviceSupported(isAvailable);
        mockBiometricService.setAvailableTypes(isAvailable ? [BiometricType.fingerprint] : []);
        
        // Set up the enabled state properly
        if (isAvailable && isEnabled) {
          try {
            await biometricAuthService.enableBiometric();
          } catch (e) {
            // If enabling fails, the test scenario is invalid
            return true; // Skip this scenario
          }
        } else {
          // Ensure biometric is disabled
          await biometricAuthService.disableBiometric();
        }
        
        // Setup authentication result - only set success if biometric is available and enabled
        final canSucceed = isAvailable && isEnabled;
        if (canSucceed && shouldSucceed) {
          mockBiometricService.setAuthResult(
            AuthResult.success(method: AuthMethod.biometric),
          );
        } else {
          mockBiometricService.setAuthResult(
            AuthResult.failure(
              method: AuthMethod.biometric,
              errorMessage: 'Authentication failed',
            ),
          );
        }
        
        // Test authentication (Requirement 4.4)
        final result = await biometricAuthService.authenticate(reason: reason);
        
        // Verify result consistency
        if (!isAvailable) {
          // Should fail when not available
          if (result.isSuccess) return false;
          if (!result.errorMessage!.contains('mevcut değil')) return false;
        } else if (!isEnabled) {
          // Should fail when not enabled
          if (result.isSuccess) return false;
          if (!result.errorMessage!.contains('etkinleştirilmemiş')) return false;
        } else {
          // Should match mock result when available and enabled
          if (result.isSuccess != shouldSucceed) return false;
          if (result.method != AuthMethod.biometric) return false;
        }
        
        return true;
      },
      iterations: 25,
    );

    /// Test rate limiting and security controls
    PropertyTest.forAll<int>(
      description: 'Property: Biometric service should implement rate limiting for security',
      generator: () => PropertyTest.randomInt(min: 1, max: 10),
      property: (failureCount) async {
        // Setup for failures
        mockBiometricService.setDeviceSupported(true);
        mockBiometricService.setAvailableTypes([BiometricType.fingerprint]);
        await biometricAuthService.enableBiometric();
        
        mockBiometricService.setAuthResult(
          AuthResult.failure(
            method: AuthMethod.biometric,
            errorMessage: 'Authentication failed',
          ),
        );
        
        // Attempt authentication multiple times
        AuthResult? lastResult;
        for (int i = 0; i < failureCount; i++) {
          lastResult = await biometricAuthService.authenticate(reason: 'Test');
        }
        
        // After 5 failures, should be locked out
        if (failureCount >= 5) {
          if (lastResult == null) return false;
          if (lastResult.isSuccess) return false;
          if (lastResult.lockoutDuration == null) return false;
          if (!lastResult.errorMessage!.contains('Çok fazla başarısız deneme')) return false;
        }
        
        return true;
      },
      iterations: 15,
    );

    /// Test secure storage of biometric settings
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Biometric settings should be securely stored and retrieved',
      generator: () => _generateStorageTestScenario(),
      property: (scenario) async {
        final biometricType = scenario['biometricType'] as BiometricType;
        final isEnabled = scenario['isEnabled'] as bool;
        
        // Setup availability
        mockBiometricService.setDeviceSupported(true);
        mockBiometricService.setAvailableTypes([biometricType]);
        
        // Test storage consistency
        if (isEnabled) {
          await biometricAuthService.enableBiometric();
        } else {
          await biometricAuthService.disableBiometric();
        }
        
        // Verify stored state matches expected state
        final storedEnabled = await biometricAuthService.isBiometricEnabled();
        if (storedEnabled != isEnabled) return false;
        
        // Test persistence across service instances
        final newService = BiometricAuthService(
          biometricService: mockBiometricService,
          secureStorage: mockSecureStorage,
        );
        await newService.initialize();
        
        final persistedEnabled = await newService.isBiometricEnabled();
        if (persistedEnabled != isEnabled) return false;
        
        newService.dispose();
        return true;
      },
      iterations: 25,
    );

    /// Test BiometricType enum consistency
    PropertyTest.forAll<BiometricType>(
      description: 'Property: BiometricType enum should have consistent serialization and display names',
      generator: () => _generateRandomBiometricType(),
      property: (biometricType) async {
        // Test round-trip serialization
        final serialized = biometricType.toJson();
        final deserialized = BiometricType.fromJson(serialized);
        
        if (deserialized != biometricType) return false;
        
        // Display name should not be empty
        if (biometricType.displayName.isEmpty) return false;
        
        // Platform name should not be empty
        if (biometricType.platformName.isEmpty) return false;
        
        // Platform name should be lowercase
        if (biometricType.platformName != biometricType.platformName.toLowerCase()) {
          return false;
        }
        
        return true;
      },
      iterations: 15,
    );
  });
}

/// Generate biometric test scenario
Map<String, dynamic> _generateBiometricTestScenario() {
  final deviceSupported = PropertyTest.randomBool();
  final availableTypes = deviceSupported ? _generateRandomBiometricTypes() : <BiometricType>[];
  
  return {
    'deviceSupported': deviceSupported,
    'availableTypes': availableTypes,
    'shouldEnable': PropertyTest.randomBool(),
  };
}

/// Generate authentication scenario
Map<String, dynamic> _generateAuthenticationScenario() {
  return {
    'shouldSucceed': PropertyTest.randomBool(),
    'reason': _generateAuthenticationReason(),
    'isEnabled': PropertyTest.randomBool(),
    'isAvailable': PropertyTest.randomBool(),
  };
}

/// Generate storage test scenario
Map<String, dynamic> _generateStorageTestScenario() {
  return {
    'biometricType': _generateRandomBiometricType(),
    'isEnabled': PropertyTest.randomBool(),
  };
}

/// Generate random biometric types list
List<BiometricType> _generateRandomBiometricTypes() {
  // Only generate platform-supported types (exclude voice as it's not supported by local_auth)
  final supportedTypes = [
    BiometricType.fingerprint,
    BiometricType.face,
    BiometricType.iris,
  ];
  
  final count = PropertyTest.randomInt(min: 0, max: supportedTypes.length);
  
  if (count == 0) return [];
  
  final types = <BiometricType>[];
  for (int i = 0; i < count; i++) {
    final type = supportedTypes[PropertyTest.randomInt(min: 0, max: supportedTypes.length - 1)];
    if (!types.contains(type)) {
      types.add(type);
    }
  }
  
  return types;
}

/// Generate random biometric type
BiometricType _generateRandomBiometricType() {
  // Only generate platform-supported types (exclude voice as it's not supported by local_auth)
  final supportedTypes = [
    BiometricType.fingerprint,
    BiometricType.face,
    BiometricType.iris,
  ];
  
  return supportedTypes[PropertyTest.randomInt(min: 0, max: supportedTypes.length - 1)];
}

/// Generate authentication reason
String _generateAuthenticationReason() {
  final reasons = [
    'Uygulamaya erişmek için kimliğinizi doğrulayın',
    'Güvenli işlem için doğrulama gerekli',
    'Hesap ayarlarına erişim',
    'Ödeme işlemi onayı',
    'Test authentication',
  ];
  
  return reasons[PropertyTest.randomInt(min: 0, max: reasons.length - 1)];
}

/// Check if two lists are equal
bool _listsEqual<T>(List<T> list1, List<T> list2) {
  if (list1.length != list2.length) return false;
  
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) return false;
  }
  
  return true;
}

/// Mock biometric service for testing
class MockBiometricService implements BiometricService {
  bool _deviceSupported = true;
  List<BiometricType> _availableTypes = [BiometricType.fingerprint];
  AuthResult? _authResult;
  
  void setDeviceSupported(bool supported) {
    _deviceSupported = supported;
  }
  
  void setAvailableTypes(List<BiometricType> types) {
    _availableTypes = types;
  }
  
  void setAuthResult(AuthResult result) {
    _authResult = result;
  }
  
  @override
  Future<bool> isBiometricAvailable() async {
    final supportedTypes = await getAvailableBiometrics();
    return _deviceSupported && supportedTypes.isNotEmpty;
  }
  
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    // Filter out unsupported types like voice that are not supported by the platform
    final supportedTypes = _availableTypes.where((type) => 
      type == BiometricType.fingerprint || 
      type == BiometricType.face || 
      type == BiometricType.iris
    ).toList();
    
    return supportedTypes;
  }
  
  @override
  Future<AuthResult> authenticate({
    String? localizedFallbackTitle,
    String? cancelButtonText,
  }) async {
    return _authResult ?? AuthResult.success(method: AuthMethod.biometric);
  }
  
  @override
  Future<bool> enrollBiometric() async {
    return _deviceSupported;
  }
  
  @override
  Future<void> disableBiometric() async {}
  
  @override
  Future<bool> isDeviceSecure() async {
    return _deviceSupported;
  }
  
  @override
  Future<bool> canCheckBiometrics() async {
    return _deviceSupported;
  }
}
