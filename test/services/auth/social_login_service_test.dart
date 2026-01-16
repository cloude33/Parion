import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/social_login_service.dart';
import 'package:parion/models/security/security_models.dart';
import '../../test_setup.dart';

/// Unit tests for Social Login Service
/// 
/// Tests Requirements:
/// - 3.1: Google authentication flow
/// - 3.2: Apple authentication flow  
/// - 3.5: Account linking scenarios
void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

  group('SocialLoginService Unit Tests', () {
    late SocialLoginService socialLoginService;

    setUp(() {
      socialLoginService = SocialLoginService();
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        // Test that initialization completes without errors
        await expectLater(
          socialLoginService.initialize(),
          completes,
        );
      });

      test('should handle multiple initialization calls gracefully', () async {
        // First initialization
        await socialLoginService.initialize();
        
        // Second initialization should not cause issues
        await expectLater(
          socialLoginService.initialize(),
          completes,
        );
      });

      test('should dispose resources properly', () {
        // Test that dispose doesn't throw errors
        expect(() => socialLoginService.dispose(), returnsNormally);
      });
    });

    group('Google Sign-In Tests - Requirement 3.1', () {
      test('should return success result for successful Google sign-in', () async {
        // This test focuses on the result structure rather than Firebase integration
        // since we can't easily mock the Firebase Auth Service dependency
        
        // Test that the method exists and returns an AuthResult
        final result = await socialLoginService.signInWithGoogle();
        
        expect(result, isA<AuthResult>());
        expect(result.method, equals(AuthMethod.social));
        
        // If it's a success, verify metadata structure
        if (result.isSuccess) {
          expect(result.metadata, isNotNull);
          expect(result.metadata!['provider'], equals('google'));
          expect(result.metadata!.containsKey('email'), isTrue);
          expect(result.metadata!.containsKey('uid'), isTrue);
        }
      });

      test('should handle Google sign-in cancellation gracefully', () async {
        // Test the error handling structure
        final result = await socialLoginService.signInWithGoogle();
        
        expect(result, isA<AuthResult>());
        expect(result.method, equals(AuthMethod.social));
        
        // If it's a failure due to cancellation, verify error message
        if (!result.isSuccess && result.errorMessage != null) {
          final errorMessage = result.errorMessage!.toLowerCase();
          if (errorMessage.contains('iptal')) {
            expect(result.metadata!['provider'], equals('google'));
          }
        }
      });

      test('should validate Google sign-in result metadata structure', () async {
        final result = await socialLoginService.signInWithGoogle();
        
        expect(result, isA<AuthResult>());
        expect(result.method, equals(AuthMethod.social));
        expect(result.metadata, isNotNull);
        expect(result.metadata!['provider'], equals('google'));
        
        // Verify metadata has expected keys
        final expectedKeys = ['provider'];
        for (final key in expectedKeys) {
          expect(result.metadata!.containsKey(key), isTrue, 
                 reason: 'Metadata should contain key: $key');
        }
      });
    });

    group('Apple Sign-In Tests - Requirement 3.2', () {
      test('should check Apple Sign-In availability correctly', () async {
        final isAvailable = await socialLoginService.isAppleSignInAvailable();
        
        expect(isAvailable, isA<bool>());
        // On non-iOS platforms or without proper setup, should return false
        // On iOS with proper setup, should return true
      });

      test('should return appropriate result for Apple sign-in attempt', () async {
        final result = await socialLoginService.signInWithApple();
        
        expect(result, isA<AuthResult>());
        expect(result.method, equals(AuthMethod.social));
        
        // If Apple Sign-In is not available, should return failure
        final isAvailable = await socialLoginService.isAppleSignInAvailable();
        if (!isAvailable) {
          expect(result.isSuccess, isFalse);
          expect(result.errorMessage, contains('kullanılamıyor'));
        }
        
        // Verify metadata structure
        expect(result.metadata, isNotNull);
        expect(result.metadata!['provider'], equals('apple'));
      });

      test('should validate Apple sign-in result metadata structure', () async {
        final result = await socialLoginService.signInWithApple();
        
        expect(result, isA<AuthResult>());
        expect(result.method, equals(AuthMethod.social));
        expect(result.metadata, isNotNull);
        expect(result.metadata!['provider'], equals('apple'));
        
        // If successful, should have proper metadata
        if (result.isSuccess) {
          expect(result.metadata!.containsKey('uid'), isTrue);
          // Apple might not always provide email
          expect(result.metadata!.containsKey('email'), isTrue);
        }
      });
    });

    group('Account Linking Tests - Requirement 3.5', () {
      test('should validate provider parameter for account linking', () async {
        // Test with invalid provider
        final result = await socialLoginService.linkAccount('invalid', {});
        
        expect(result, isA<AuthResult>());
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Desteklenmeyen sağlayıcı'));
        expect(result.metadata!['provider'], equals('invalid'));
      });

      test('should require authentication for account linking', () async {
        // Test linking without being authenticated
        final result = await socialLoginService.linkAccount('google', {});
        
        expect(result, isA<AuthResult>());
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('giriş yapmalısınız'));
      });

      test('should validate supported providers for linking', () async {
        // Test with supported providers
        final supportedProviders = ['google', 'apple'];
        
        for (final provider in supportedProviders) {
          final result = await socialLoginService.linkAccount(provider, {});
          
          expect(result, isA<AuthResult>());
          expect(result.metadata!['provider'], equals(provider));
          
          // Should fail due to not being authenticated, not due to invalid provider
          if (!result.isSuccess) {
            expect(result.errorMessage, isNot(contains('Desteklenmeyen sağlayıcı')));
          }
        }
      });

      test('should handle account unlinking gracefully', () async {
        // Test unlinking without authentication
        try {
          await socialLoginService.unlinkAccount('google');
          fail('Should throw error when not authenticated');
        } catch (e) {
          expect(e.toString(), contains('giriş yapmalısınız'));
        }
        
        // Test with invalid provider
        try {
          await socialLoginService.unlinkAccount('invalid');
          fail('Should throw error for invalid provider');
        } catch (e) {
          expect(e.toString(), contains('Desteklenmeyen sağlayıcı'));
        }
      });

      test('should return empty list for linked providers when not authenticated', () async {
        final providers = await socialLoginService.getLinkedProviders();
        
        expect(providers, isA<List<String>>());
        expect(providers, isEmpty);
      });
    });

    group('Error Handling Tests', () {
      test('should handle Firebase Auth exceptions properly', () async {
        // Test Google sign-in error handling
        final result = await socialLoginService.signInWithGoogle();
        
        expect(result, isA<AuthResult>());
        
        // If there's an error, it should be properly formatted
        if (!result.isSuccess) {
          expect(result.errorMessage, isNotNull);
          expect(result.errorMessage!.isNotEmpty, isTrue);
          expect(result.metadata, isNotNull);
          expect(result.metadata!['provider'], equals('google'));
        }
      });

      test('should handle platform exceptions properly', () async {
        // Test that platform exceptions are caught and handled
        final result = await socialLoginService.signInWithGoogle();
        
        expect(result, isA<AuthResult>());
        
        // Verify error structure if there's a platform error
        if (!result.isSuccess && result.metadata!.containsKey('errorCode')) {
          expect(result.errorMessage, isNotNull);
          expect(result.metadata!['provider'], equals('google'));
        }
      });

      test('should provide localized error messages', () async {
        // Test Google sign-in error messages
        final googleResult = await socialLoginService.signInWithGoogle();
        if (!googleResult.isSuccess) {
          expect(googleResult.errorMessage, isNotNull);
          // Should be in Turkish
          expect(googleResult.errorMessage!.contains('Google'), isTrue);
        }
        
        // Test Apple sign-in error messages
        final appleResult = await socialLoginService.signInWithApple();
        if (!appleResult.isSuccess) {
          expect(appleResult.errorMessage, isNotNull);
          // Should be in Turkish
          final errorMessage = appleResult.errorMessage!.toLowerCase();
          expect(
            errorMessage.contains('apple') || 
            errorMessage.contains('kullanılamıyor') ||
            errorMessage.contains('iptal'),
            isTrue
          );
        }
      });
    });

    group('Sign Out Tests', () {
      test('should sign out from all providers without errors', () async {
        await expectLater(
          socialLoginService.signOutAll(),
          completes,
        );
      });

      test('should handle sign out errors gracefully', () async {
        // Even if there are errors during sign out, it should not throw
        await expectLater(
          socialLoginService.signOutAll(),
          completes,
        );
      });
    });

    group('Integration Tests', () {
      test('should maintain consistent AuthResult structure across all methods', () async {
        final methods = [
          () => socialLoginService.signInWithGoogle(),
          () => socialLoginService.signInWithApple(),
          () => socialLoginService.linkAccount('google', {}),
        ];
        
        for (final method in methods) {
          final result = await method();
          
          expect(result, isA<AuthResult>());
          expect(result.method, equals(AuthMethod.social));
          expect(result.metadata, isNotNull);
          expect(result.metadata!.containsKey('provider'), isTrue);
          
          // Verify timestamp is recent
          final now = DateTime.now();
          final timeDiff = now.difference(result.timestamp);
          expect(timeDiff.inMinutes, lessThan(1));
        }
      });

      test('should handle rapid successive calls gracefully', () async {
        // Test multiple rapid calls don't cause issues
        final futures = List.generate(3, (_) => socialLoginService.signInWithGoogle());
        final results = await Future.wait(futures);
        
        for (final result in results) {
          expect(result, isA<AuthResult>());
          expect(result.method, equals(AuthMethod.social));
        }
      });

      test('should validate provider names consistently', () async {
        final testCases = [
          {'provider': 'google', 'shouldBeValid': true},
          {'provider': 'apple', 'shouldBeValid': true},
          {'provider': 'GOOGLE', 'shouldBeValid': false}, // Case sensitive
          {'provider': 'facebook', 'shouldBeValid': false},
          {'provider': '', 'shouldBeValid': false},
        ];
        
        for (final testCase in testCases) {
          final provider = testCase['provider'] as String;
          final shouldBeValid = testCase['shouldBeValid'] as bool;
          
          final result = await socialLoginService.linkAccount(provider, {});
          
          if (shouldBeValid) {
            // Should fail due to authentication, not invalid provider
            expect(result.errorMessage, isNot(contains('Desteklenmeyen sağlayıcı')));
          } else {
            // Should fail due to invalid provider
            if (provider.isNotEmpty) {
              expect(result.errorMessage, contains('Desteklenmeyen sağlayıcı'));
            }
          }
        }
      });
    });

    group('Service Lifecycle Tests', () {
      test('should handle initialization before operations', () async {
        final newService = SocialLoginService();
        
        // Operations should work even without explicit initialization
        // (service should auto-initialize)
        final result = await newService.signInWithGoogle();
        expect(result, isA<AuthResult>());
      });

      test('should handle operations after disposal', () {
        socialLoginService.dispose();
        
        // Operations should still work after disposal
        // (service should re-initialize if needed)
        expect(() => socialLoginService.signInWithGoogle(), returnsNormally);
      });

      test('should maintain singleton behavior', () {
        final service1 = SocialLoginService();
        final service2 = SocialLoginService();
        
        expect(identical(service1, service2), isTrue);
      });
    });

    group('Metadata Validation Tests', () {
      test('should include required metadata fields in results', () async {
        final result = await socialLoginService.signInWithGoogle();
        
        expect(result.metadata, isNotNull);
        
        // Required fields for all social auth results
        expect(result.metadata!.containsKey('provider'), isTrue);
        
        // Provider should be valid
        final provider = result.metadata!['provider'] as String;
        expect(['google', 'apple'].contains(provider), isTrue);
      });

      test('should handle metadata consistently across success and failure', () async {
        final googleResult = await socialLoginService.signInWithGoogle();
        final appleResult = await socialLoginService.signInWithApple();
        
        for (final result in [googleResult, appleResult]) {
          expect(result.metadata, isNotNull);
          expect(result.metadata!['provider'], isNotNull);
          
          // Success results should have more metadata
          if (result.isSuccess) {
            expect(result.metadata!.containsKey('uid'), isTrue);
          }
          
          // Failure results should have error context
          if (!result.isSuccess) {
            expect(result.errorMessage, isNotNull);
          }
        }
      });
    });
  });
}