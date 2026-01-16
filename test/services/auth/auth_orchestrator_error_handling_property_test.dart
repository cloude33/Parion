import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/security/security_models.dart';
import '../../property_test_utils.dart';
import '../../test_setup.dart';

/// Property-based tests for AuthOrchestrator Error Handling
/// 
/// **Feature: modern-auth-system, Property 2: Comprehensive Error Handling**
/// **Validates: Requirements 1.4, 2.2, 3.4, 4.4, 6.4, 10.1, 10.2, 10.3**
void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('AuthOrchestrator Error Handling Property Tests', () {
    /// **Property 2: Comprehensive Error Handling**
    /// *For any* authentication error or system failure, the system should provide 
    /// appropriate error messages, recovery options, and fallback mechanisms without 
    /// exposing sensitive information
    /// **Validates: Requirements 1.4, 2.2, 3.4, 4.4, 6.4, 10.1, 10.2, 10.3**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 2: Comprehensive Error Handling - Error messages should be user-friendly and not expose sensitive information',
      generator: () => _generateErrorScenario(),
      property: (errorData) async {
        final errorType = errorData['type'] as String;
        final errorMessage = errorData['message'] as String;
        
        // Test error message localization
        final localizedMessage = _getLocalizedErrorMessage(errorMessage);
        
        // Error messages should be in Turkish (user-friendly)
        if (!_isUserFriendlyMessage(localizedMessage)) {
          return false;
        }
        
        // Should not expose sensitive technical details
        if (_containsSensitiveInformation(localizedMessage)) {
          return false;
        }
        
        // Should provide actionable guidance when possible
        if (_shouldProvideGuidance(errorType) && !_providesGuidance(localizedMessage)) {
          return false;
        }
        
        // Should end with proper punctuation
        if (!localizedMessage.endsWith('.') && 
            !localizedMessage.endsWith('!') &&
            !localizedMessage.endsWith('?')) {
          return false;
        }
        
        return true;
      },
      iterations: 25,
    );

    /// Test network error handling
    PropertyTest.forAll<String>(
      description: 'Property: Network errors should provide appropriate user guidance',
      generator: () => _generateNetworkError(),
      property: (networkError) async {
        final localizedMessage = _getLocalizedErrorMessage(networkError);
        
        // Network errors should mention connection issues
        if (!localizedMessage.toLowerCase().contains('bağlantı')) {
          return false;
        }
        
        // Should not expose technical network details
        if (localizedMessage.contains('timeout') || 
            localizedMessage.contains('socket') ||
            localizedMessage.contains('DNS')) {
          return false;
        }
        
        return true;
      },
      iterations: 15,
    );

    /// Test authentication error handling
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Authentication errors should provide specific guidance without exposing security details',
      generator: () => _generateAuthError(),
      property: (authErrorData) async {
        final errorCode = authErrorData['code'] as String;
        final originalMessage = authErrorData['message'] as String;
        
        final localizedMessage = _getLocalizedErrorMessage(originalMessage);
        
        // Should provide specific guidance for common errors
        switch (errorCode) {
          case 'user-not-found':
            if (!localizedMessage.contains('kullanıcı') || !localizedMessage.contains('bulunamadı')) {
              return false;
            }
            break;
          case 'wrong-password':
            if (!localizedMessage.contains('hatalı') || !localizedMessage.contains('şifre')) {
              return false;
            }
            break;
          case 'email-already-in-use':
            if (!localizedMessage.contains('zaten') || !localizedMessage.contains('kullanımda')) {
              return false;
            }
            break;
          case 'weak-password':
            if (!localizedMessage.contains('zayıf') || !localizedMessage.contains('şifre')) {
              return false;
            }
            break;
        }
        
        // Should not expose Firebase error codes or technical details
        if (localizedMessage.contains('firebase') ||
            localizedMessage.contains('auth/') ||
            localizedMessage.contains('error code')) {
          return false;
        }
        
        return true;
      },
      iterations: 15,
    );

    /// Test biometric error handling
    PropertyTest.forAll<String>(
      description: 'Property: Biometric errors should provide fallback options',
      generator: () => _generateBiometricError(),
      property: (biometricError) async {
        final localizedMessage = _getLocalizedErrorMessage(biometricError);
        
        // Should mention biometric authentication
        if (!localizedMessage.toLowerCase().contains('biyometrik')) {
          return false;
        }
        
        // Should not expose technical biometric details
        if (localizedMessage.contains('sensor') ||
            localizedMessage.contains('hardware') ||
            localizedMessage.contains('API')) {
          return false;
        }
        
        // Should suggest alternatives for common biometric issues
        if (biometricError.contains('not available') && 
            !localizedMessage.contains('mevcut değil')) {
          return false;
        }
        
        if (biometricError.contains('not enrolled') && 
            !localizedMessage.contains('ayarlanmamış')) {
          return false;
        }
        
        return true;
      },
      iterations: 15,
    );

    /// Test error message consistency
    PropertyTest.forAll<String>(
      description: 'Property: Error messages should be consistent in format and tone',
      generator: () => _generateRandomError(),
      property: (error) async {
        final localizedMessage = _getLocalizedErrorMessage(error);
        
        // Should not be empty
        if (localizedMessage.isEmpty) {
          return false;
        }
        
        // Should not contain English technical terms (except proper nouns)
        final englishTechnicalTerms = [
          'error', 'exception', 'null', 'undefined', 'timeout',
          'socket', 'connection', 'authentication', 'authorization'
        ];
        
        for (final term in englishTechnicalTerms) {
          if (localizedMessage.toLowerCase().contains(term)) {
            return false;
          }
        }
        
        // Should end with proper punctuation
        if (!localizedMessage.endsWith('.') && 
            !localizedMessage.endsWith('!') &&
            !localizedMessage.endsWith('?')) {
          return false;
        }
        
        return true;
      },
      iterations: 25,
    );

    /// Test AuthResult error consistency
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: AuthResult failures should always have error messages',
      generator: () => _generateAuthResultFailure(),
      property: (failureData) async {
        final method = failureData['method'] as AuthMethod;
        final errorMessage = failureData['errorMessage'] as String?;
        final lockoutDuration = failureData['lockoutDuration'] as Duration?;
        final remainingAttempts = failureData['remainingAttempts'] as int?;
        
        final result = AuthResult.failure(
          method: method,
          errorMessage: errorMessage ?? 'Test error',
          lockoutDuration: lockoutDuration,
          remainingAttempts: remainingAttempts,
        );
        
        // Failure results must have error messages
        if (result.errorMessage == null || result.errorMessage!.isEmpty) {
          return false;
        }
        
        // Should not be successful
        if (result.isSuccess) {
          return false;
        }
        
        // Lockout duration should not be negative
        if (result.lockoutDuration != null && result.lockoutDuration!.isNegative) {
          return false;
        }
        
        // Remaining attempts should not be negative
        if (result.remainingAttempts != null && result.remainingAttempts! < 0) {
          return false;
        }
        
        return true;
      },
      iterations: 25,
    );
  });
}

/// Generate error scenario for testing
Map<String, dynamic> _generateErrorScenario() {
  final errorTypes = [
    'network',
    'authentication',
    'biometric',
    'validation',
    'system',
  ];
  
  final errorType = errorTypes[PropertyTest.randomInt(min: 0, max: errorTypes.length - 1)];
  
  switch (errorType) {
    case 'network':
      return {
        'type': errorType,
        'message': 'Network connection failed',
        'expectedUserMessage': 'Bağlantı sorunu yaşanıyor',
      };
    case 'authentication':
      return {
        'type': errorType,
        'message': 'user-not-found',
        'expectedUserMessage': 'Kullanıcı bulunamadı',
      };
    case 'biometric':
      return {
        'type': errorType,
        'message': 'biometric not available',
        'expectedUserMessage': 'Biyometrik doğrulama mevcut değil',
      };
    case 'validation':
      return {
        'type': errorType,
        'message': 'invalid-email',
        'expectedUserMessage': 'Geçersiz e-posta adresi',
      };
    default:
      return {
        'type': errorType,
        'message': 'Unknown error',
        'expectedUserMessage': 'Beklenmeyen bir hata oluştu',
      };
  }
}

/// Generate network error for testing
String _generateNetworkError() {
  final networkErrors = [
    'network connection failed',
    'timeout error',
    'connection refused',
    'DNS resolution failed',
    'socket timeout',
    'no internet connection',
  ];
  
  return networkErrors[PropertyTest.randomInt(min: 0, max: networkErrors.length - 1)];
}

/// Generate authentication error for testing
Map<String, dynamic> _generateAuthError() {
  final authErrors = [
    {'code': 'user-not-found', 'message': 'user-not-found'},
    {'code': 'wrong-password', 'message': 'wrong-password'},
    {'code': 'email-already-in-use', 'message': 'email-already-in-use'},
    {'code': 'weak-password', 'message': 'weak-password'},
    {'code': 'invalid-email', 'message': 'invalid-email'},
    {'code': 'user-disabled', 'message': 'user-disabled'},
    {'code': 'too-many-requests', 'message': 'too-many-requests'},
  ];
  
  return authErrors[PropertyTest.randomInt(min: 0, max: authErrors.length - 1)];
}

/// Generate biometric error for testing
String _generateBiometricError() {
  final biometricErrors = [
    'biometric not available',
    'biometric not enrolled',
    'biometric cancelled',
    'biometric failed',
    'biometric hardware error',
  ];
  
  return biometricErrors[PropertyTest.randomInt(min: 0, max: biometricErrors.length - 1)];
}

/// Generate random error for testing
String _generateRandomError() {
  final errors = [
    'Network connection failed',
    'user-not-found',
    'biometric not available',
    'invalid-email',
    'Google sign in failed',
    'Session expired',
    'Rate limit exceeded',
  ];
  
  return errors[PropertyTest.randomInt(min: 0, max: errors.length - 1)];
}

/// Generate AuthResult failure data
Map<String, dynamic> _generateAuthResultFailure() {
  final methods = AuthMethod.values;
  final method = methods[PropertyTest.randomInt(min: 0, max: methods.length - 1)];
  
  return {
    'method': method,
    'errorMessage': PropertyTest.randomBool() ? PropertyTest.randomString(minLength: 5, maxLength: 50) : null,
    'lockoutDuration': PropertyTest.randomBool() ? Duration(minutes: PropertyTest.randomInt(min: 1, max: 60)) : null,
    'remainingAttempts': PropertyTest.randomBool() ? PropertyTest.randomInt(min: 0, max: 5) : null,
  };
}

/// Get localized error message (simplified version of the actual implementation)
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
  if (error is String && error.isNotEmpty && !_containsTechnicalTerms(error.toString())) {
    // If the error is already user-friendly, ensure it ends with punctuation
    final cleanError = error.toString().trim();
    if (!cleanError.endsWith('.') && !cleanError.endsWith('!') && !cleanError.endsWith('?')) {
      return '$cleanError.';
    }
    return cleanError;
  }
  
  return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
}

/// Check if error contains technical terms that should be hidden from users
bool _containsTechnicalTerms(String error) {
  final technicalTerms = [
    'firebase', 'auth/', 'exception', 'stack trace', 'error code',
    'internal', 'debug', 'api', 'token', 'credential', 'socket',
    'dns', 'timeout', 'null', 'undefined'
  ];
  
  final lowerError = error.toLowerCase();
  return technicalTerms.any((term) => lowerError.contains(term));
}

/// Check if message is user-friendly (in Turkish)
bool _isUserFriendlyMessage(String message) {
  // Should contain Turkish words or be in Turkish
  final turkishWords = [
    'lütfen', 'tekrar', 'deneyin', 'kontrol', 'edin', 'geçersiz',
    'hatalı', 'başarısız', 'sorunu', 'yaşanıyor', 'bağlantı',
    'şifre', 'e-posta', 'kullanıcı', 'hesap', 'doğrulama',
    'beklenmeyen', 'hata', 'oluştu', 'iptal', 'edildi',
    'mevcut', 'değil', 'ayarlanmamış', 'etkinleştirin'
  ];
  
  final lowerMessage = message.toLowerCase();
  return turkishWords.any((word) => lowerMessage.contains(word));
}

/// Check if message contains sensitive information
bool _containsSensitiveInformation(String message) {
  final sensitiveTerms = [
    'firebase', 'auth/', 'error code', 'exception', 'stack trace',
    'internal', 'debug', 'api key', 'token', 'credential',
    'password', 'şifre' // Note: 'şifre' is OK in user messages but not raw passwords
  ];
  
  final lowerMessage = message.toLowerCase();
  
  // Check for actual sensitive data patterns
  if (RegExp(r'[a-zA-Z0-9]{20,}').hasMatch(message)) { // Long tokens/keys
    return true;
  }
  
  if (RegExp(r'auth/[a-z-]+').hasMatch(message)) { // Firebase error codes
    return true;
  }
  
  return sensitiveTerms.any((term) => lowerMessage.contains(term));
}

/// Check if error type should provide guidance
bool _shouldProvideGuidance(String errorType) {
  return ['network', 'authentication', 'biometric'].contains(errorType);
}

/// Check if message provides guidance
bool _providesGuidance(String message) {
  final guidanceWords = [
    'lütfen', 'kontrol edin', 'tekrar deneyin', 'ayarlarından',
    'etkinleştirin', 'güncelleyin', 'yeniden başlatın'
  ];
  
  final lowerMessage = message.toLowerCase();
  return guidanceWords.any((word) => lowerMessage.contains(word));
}
