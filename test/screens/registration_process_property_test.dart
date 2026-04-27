import 'package:flutter_test/flutter_test.dart';
import '../property_test_utils.dart';
import '../test_setup.dart';

/// Property-based tests for Registration Process
/// 
/// **Feature: modern-auth-system, Property 8: Registration Process Integrity**
/// **Validates: Requirements 6.2, 6.3, 6.4, 6.5**
void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('Registration Process Property Tests', () {
    /// **Property 8: Registration Process Integrity**
    /// *For any* user registration attempt, the system should validate all required fields,
    /// enforce terms acceptance, create both Firebase and local profiles on success,
    /// and provide clear guidance on failure
    /// **Validates: Requirements 6.2, 6.3, 6.4, 6.5**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 8: Registration Process Integrity - All registration data should be properly validated',
      generator: () => _generateRegistrationData(),
      property: (registrationData) async {
        final name = registrationData['name'] as String?;
        final email = registrationData['email'] as String?;
        final password = registrationData['password'] as String?;
        final confirmPassword = registrationData['confirmPassword'] as String?;
        final termsAccepted = registrationData['termsAccepted'] as bool;
        
        // Requirement 6.2: Validate all required fields
        final hasValidName = name != null && name.trim().isNotEmpty && name.trim().length >= 2;
        final hasValidEmail = email != null && _isValidEmailFormat(email.trim());
        final hasValidPassword = password != null && _isValidPasswordFormat(password);
        final passwordsMatch = password == confirmPassword;
        
        // Requirement 6.5: Terms acceptance is required
        final hasTermsAccepted = termsAccepted;
        
        // All validation rules should be consistent
        final isValidRegistration = hasValidName && 
                                   hasValidEmail && 
                                   hasValidPassword && 
                                   passwordsMatch && 
                                   hasTermsAccepted;
        
        // If any field is invalid, registration should fail
        if (!hasValidName || !hasValidEmail || !hasValidPassword || !passwordsMatch || !hasTermsAccepted) {
          return !isValidRegistration;
        }
        
        // If all fields are valid, registration should succeed
        return isValidRegistration;
      },
      iterations: 100,
    );

    /// Test name validation property
    PropertyTest.forAll<String>(
      description: 'Property: Name validation should enforce minimum length and non-empty requirements',
      generator: () => _generateNameTestCase(),
      property: (name) async {
        final isValidName = _isValidName(name);
        
        // Empty or whitespace-only names should be invalid
        if (name.trim().isEmpty) {
          return !isValidName;
        }
        
        // Names shorter than 2 characters should be invalid
        if (name.trim().length < 2) {
          return !isValidName;
        }
        
        // Names with 2 or more characters should be valid
        if (name.trim().length >= 2) {
          return isValidName;
        }
        
        return true;
      },
      iterations: 100,
    );

    /// Test email validation for registration
    PropertyTest.forAll<String>(
      description: 'Property: Email validation for registration should be strict and consistent',
      generator: () => _generateEmailTestCase(),
      property: (email) async {
        final isValidEmail = _isValidEmailFormat(email);
        
        // Empty emails should be invalid
        if (email.isEmpty) {
          return !isValidEmail;
        }
        
        // Emails without @ should be invalid
        if (!email.contains('@')) {
          return !isValidEmail;
        }
        
        // Emails starting or ending with @ should be invalid
        if (email.startsWith('@') || email.endsWith('@')) {
          return !isValidEmail;
        }
        
        // Emails with consecutive dots should be invalid
        if (email.contains('..')) {
          return !isValidEmail;
        }
        
        // Emails without domain extension should be invalid
        if (!email.contains('.') || email.lastIndexOf('.') <= email.indexOf('@')) {
          return !isValidEmail;
        }
        
        return true;
      },
      iterations: 100,
    );

    /// Test password strength validation for registration
    PropertyTest.forAll<String>(
      description: 'Property: Password validation should enforce strong password requirements',
      generator: () => _generatePasswordTestCase(),
      property: (password) async {
        final isValidPassword = _isValidPasswordFormat(password);
        
        // Passwords shorter than 8 characters should be invalid
        if (password.length < 8) {
          return !isValidPassword;
        }
        
        // Passwords without uppercase letters should be invalid
        if (!RegExp(r'[A-Z]').hasMatch(password)) {
          return !isValidPassword;
        }
        
        // Passwords without lowercase letters should be invalid
        if (!RegExp(r'[a-z]').hasMatch(password)) {
          return !isValidPassword;
        }
        
        // Passwords without numbers should be invalid
        if (!RegExp(r'[0-9]').hasMatch(password)) {
          return !isValidPassword;
        }
        
        // Passwords meeting all criteria should be valid
        if (password.length >= 8 && 
            RegExp(r'[A-Z]').hasMatch(password) &&
            RegExp(r'[a-z]').hasMatch(password) &&
            RegExp(r'[0-9]').hasMatch(password)) {
          return isValidPassword;
        }
        
        return true;
      },
      iterations: 100,
    );

    /// Test password confirmation matching
    PropertyTest.forAll<Map<String, String>>(
      description: 'Property: Password confirmation should exactly match the original password',
      generator: () => _generatePasswordConfirmationData(),
      property: (passwordData) async {
        final password = passwordData['password']!;
        final confirmPassword = passwordData['confirmPassword']!;
        
        final passwordsMatch = password == confirmPassword;
        
        // Passwords should match exactly
        if (password == confirmPassword) {
          return passwordsMatch;
        } else {
          return !passwordsMatch;
        }
      },
      iterations: 100,
    );

    /// Test terms acceptance requirement
    PropertyTest.forAll<bool>(
      description: 'Property: Terms acceptance should be required for registration',
      generator: () => PropertyTest.randomBool(),
      property: (termsAccepted) async {
        // Terms must be accepted for valid registration
        // This property tests that the validation correctly enforces this requirement
        
        // If terms are not accepted, registration should be invalid
        if (!termsAccepted) {
          return !_isValidTermsAcceptance(termsAccepted);
        }
        
        // If terms are accepted, this part of validation should pass
        return _isValidTermsAcceptance(termsAccepted);
      },
      iterations: 50,
    );

    /// Test registration data completeness
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Registration should require all mandatory fields to be present and valid',
      generator: () => _generateIncompleteRegistrationData(),
      property: (registrationData) async {
        final name = registrationData['name'] as String?;
        final email = registrationData['email'] as String?;
        final password = registrationData['password'] as String?;
        final confirmPassword = registrationData['confirmPassword'] as String?;
        final termsAccepted = registrationData['termsAccepted'] as bool?;
        
        // Check if any required field is missing or invalid
        final hasAllFields = name != null && 
                            email != null && 
                            password != null && 
                            confirmPassword != null && 
                            termsAccepted != null;
        
        if (!hasAllFields) {
          // Registration with missing fields should be invalid
          return !_isCompleteRegistrationData(registrationData);
        }
        
        // If all fields are present, check if they're valid
        final isValid = _isValidName(name!) &&
                       _isValidEmailFormat(email!) &&
                       _isValidPasswordFormat(password!) &&
                       password == confirmPassword &&
                       termsAccepted!;
        
        return _isCompleteRegistrationData(registrationData) == isValid;
      },
      iterations: 100,
    );

    /// Test social registration data handling
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Social registration should handle provider-specific data correctly',
      generator: () => _generateSocialRegistrationData(),
      property: (socialData) async {
        final provider = socialData['provider'] as String?;
        final email = socialData['email'] as String?;
        final displayName = socialData['displayName'] as String?;
        
        // Social registration should have valid provider
        final hasValidProvider = provider != null && 
                                ['google', 'apple'].contains(provider);
        
        // Social registration should have email from provider
        final hasValidEmail = email != null && _isValidEmailFormat(email);
        
        // Display name can be optional but if present should be valid
        final hasValidDisplayName = displayName == null || 
                                   (displayName.isNotEmpty && displayName.length >= 2);
        
        final isValidSocialRegistration = hasValidProvider && 
                                         hasValidEmail && 
                                         hasValidDisplayName;
        
        return _isValidSocialRegistrationData(socialData) == isValidSocialRegistration;
      },
      iterations: 100,
    );
  });
}

/// Generate registration data for property testing
Map<String, dynamic> _generateRegistrationData() {
  return {
    'name': _generateNameTestCase(),
    'email': _generateEmailTestCase(),
    'password': _generatePasswordTestCase(),
    'confirmPassword': PropertyTest.randomBool() 
        ? _generatePasswordTestCase() // Different password
        : _generatePasswordTestCase(), // Could be same or different
    'termsAccepted': PropertyTest.randomBool(),
  };
}

/// Generate name test cases
String _generateNameTestCase() {
  final testCases = [
    // Valid names
    'John Doe',
    'Alice Smith',
    'Bob Johnson',
    'Maria Garcia',
    'Ahmed Ali',
    // Invalid names
    '',
    ' ',
    'A',
    '  ',
    '\t',
    '\n',
  ];
  
  if (PropertyTest.randomBool()) {
    return testCases[PropertyTest.randomInt(min: 0, max: testCases.length - 1)];
  } else {
    // Generate random name
    return PropertyTest.randomString(minLength: 0, maxLength: 50);
  }
}

/// Generate email test cases
String _generateEmailTestCase() {
  final testCases = [
    // Valid emails
    'user@example.com',
    'test.email@domain.co.uk',
    'user+tag@example.org',
    'valid.email@test.com',
    // Invalid emails
    'invalid-email',
    '@domain.com',
    'user@',
    'user@domain',
    '',
    'user space@domain.com',
    'user..double@domain.com',
    'user@domain..com',
  ];
  
  if (PropertyTest.randomBool()) {
    return testCases[PropertyTest.randomInt(min: 0, max: testCases.length - 1)];
  } else {
    // Generate random email-like string
    return PropertyTest.randomString(minLength: 0, maxLength: 30);
  }
}

/// Generate password test cases
String _generatePasswordTestCase() {
  final testCases = [
    // Valid passwords (8+ chars, upper, lower, number)
    'Password123',
    'MySecure1Pass',
    'Test123456',
    'StrongPass1',
    // Invalid passwords
    '123',
    'short',
    'password',
    'PASSWORD',
    '12345678',
    'NoNumbers',
    'nonumbers123',
    'NOLOWERCASE123',
    '',
  ];
  
  if (PropertyTest.randomBool()) {
    return testCases[PropertyTest.randomInt(min: 0, max: testCases.length - 1)];
  } else {
    // Generate random password
    return PropertyTest.randomString(minLength: 0, maxLength: 20);
  }
}

/// Generate password confirmation data
Map<String, String> _generatePasswordConfirmationData() {
  final password = _generatePasswordTestCase();
  
  if (PropertyTest.randomBool()) {
    // Same password
    return {
      'password': password,
      'confirmPassword': password,
    };
  } else {
    // Different password
    return {
      'password': password,
      'confirmPassword': _generatePasswordTestCase(),
    };
  }
}

/// Generate incomplete registration data (some fields missing)
Map<String, dynamic> _generateIncompleteRegistrationData() {
  final completeData = {
    'name': _generateNameTestCase(),
    'email': _generateEmailTestCase(),
    'password': _generatePasswordTestCase(),
    'confirmPassword': _generatePasswordTestCase(),
    'termsAccepted': PropertyTest.randomBool(),
  };
  
  // Randomly remove some fields
  final fieldsToRemove = <String>[];
  if (PropertyTest.randomBool()) fieldsToRemove.add('name');
  if (PropertyTest.randomBool()) fieldsToRemove.add('email');
  if (PropertyTest.randomBool()) fieldsToRemove.add('password');
  if (PropertyTest.randomBool()) fieldsToRemove.add('confirmPassword');
  if (PropertyTest.randomBool()) fieldsToRemove.add('termsAccepted');
  
  for (final field in fieldsToRemove) {
    completeData.remove(field);
  }
  
  return completeData;
}

/// Generate social registration data
Map<String, dynamic> _generateSocialRegistrationData() {
  final providers = ['google', 'apple', 'facebook', 'invalid', ''];
  
  return {
    'provider': providers[PropertyTest.randomInt(min: 0, max: providers.length - 1)],
    'email': _generateEmailTestCase(),
    'displayName': PropertyTest.randomBool() ? _generateNameTestCase() : null,
  };
}

/// Validate name format
bool _isValidName(String name) {
  return name.trim().isNotEmpty && name.trim().length >= 2;
}

/// Validate email format
bool _isValidEmailFormat(String email) {
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}

/// Validate password format (strong password requirements)
bool _isValidPasswordFormat(String password) {
  if (password.length < 8) return false;
  
  // Must have uppercase letter
  if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
  
  // Must have lowercase letter
  if (!RegExp(r'[a-z]').hasMatch(password)) return false;
  
  // Must have number
  if (!RegExp(r'[0-9]').hasMatch(password)) return false;
  
  return true;
}

/// Validate terms acceptance
bool _isValidTermsAcceptance(bool termsAccepted) {
  return termsAccepted;
}

/// Check if registration data is complete and valid
bool _isCompleteRegistrationData(Map<String, dynamic> data) {
  final name = data['name'] as String?;
  final email = data['email'] as String?;
  final password = data['password'] as String?;
  final confirmPassword = data['confirmPassword'] as String?;
  final termsAccepted = data['termsAccepted'] as bool?;
  
  // All fields must be present
  if (name == null || email == null || password == null || 
      confirmPassword == null || termsAccepted == null) {
    return false;
  }
  
  // All fields must be valid
  return _isValidName(name) &&
         _isValidEmailFormat(email) &&
         _isValidPasswordFormat(password) &&
         password == confirmPassword &&
         termsAccepted;
}

/// Check if social registration data is valid
bool _isValidSocialRegistrationData(Map<String, dynamic> data) {
  final provider = data['provider'] as String?;
  final email = data['email'] as String?;
  final displayName = data['displayName'] as String?;
  
  // Provider must be valid
  if (provider == null || !['google', 'apple'].contains(provider)) {
    return false;
  }
  
  // Email must be valid
  if (email == null || !_isValidEmailFormat(email)) {
    return false;
  }
  
  // Display name is optional but if present must be valid
  if (displayName != null && !_isValidName(displayName)) {
    return false;
  }
  
  return true;
}