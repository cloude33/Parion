import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parion/services/firebase_auth_service.dart';

void main() {
  group('FirebaseAuthService Tests', () {
    late FirebaseAuthService authService;

    setUp(() {
      authService = FirebaseAuthService();
    });

    group('Email Validation Tests', () {
      test('should return null for valid email', () {
        // Test valid email formats
        expect(authService.validateEmail('test@example.com'), isNull);
        expect(authService.validateEmail('user.name@domain.co.uk'), isNull);
        expect(authService.validateEmail('test123@test-domain.com'), isNull);
      });

      test('should return error for empty email', () {
        final result = authService.validateEmail('');
        expect(result, equals('E-posta adresi gereklidir'));
      });

      test('should return error for invalid email formats', () {
        expect(authService.validateEmail('invalid-email'), isNotNull);
        expect(authService.validateEmail('test@'), isNotNull);
        expect(authService.validateEmail('@domain.com'), isNotNull);
        expect(authService.validateEmail('test.domain.com'), isNotNull);
      });
    });

    group('Password Validation Tests', () {
      test('should return null for valid passwords', () {
        expect(authService.validatePassword('123456'), isNull);
        expect(authService.validatePassword('password123'), isNull);
        expect(authService.validatePassword('StrongPass1'), isNull);
      });

      test('should return error for empty password', () {
        final result = authService.validatePassword('');
        expect(result, equals('Şifre gereklidir'));
      });

      test('should return error for short passwords', () {
        final result = authService.validatePassword('12345');
        expect(result, equals('Şifre en az 6 karakter olmalıdır'));
      });

      test('should suggest stronger password for weak 8+ character passwords', () {
        final result = authService.validatePassword('password');
        expect(result, equals('Güçlü şifre için harf ve rakam kullanın'));
        
        final result2 = authService.validatePassword('12345678');
        expect(result2, equals('Güçlü şifre için harf ve rakam kullanın'));
      });
    });

    group('Display Name Validation Tests', () {
      test('should return null for valid display names', () {
        expect(authService.validateDisplayName('John Doe'), isNull);
        expect(authService.validateDisplayName('Ali Veli'), isNull);
        expect(authService.validateDisplayName('Test User 123'), isNull);
      });

      test('should return error for empty display name', () {
        final result = authService.validateDisplayName('');
        expect(result, equals('Ad soyad gereklidir'));
      });

      test('should return error for too short display name', () {
        final result = authService.validateDisplayName('A');
        expect(result, equals('Ad soyad en az 2 karakter olmalıdır'));
      });

      test('should return error for too long display name', () {
        final longName = 'A' * 51;
        final result = authService.validateDisplayName(longName);
        expect(result, equals('Ad soyad en fazla 50 karakter olabilir'));
      });
    });

    group('Error Handling Tests', () {
      test('should handle user-not-found error correctly', () {
        final exception = FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found',
        );
        
        final result = authService.handleAuthException(exception);
        expect(result, contains('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı'));
      });

      test('should handle wrong-password error correctly', () {
        final exception = FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password',
        );
        
        final result = authService.handleAuthException(exception);
        expect(result, contains('Hatalı şifre girdiniz'));
      });

      test('should handle email-already-in-use error correctly', () {
        final exception = FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already in use',
        );
        
        final result = authService.handleAuthException(exception);
        expect(result, contains('Bu e-posta adresi zaten kullanımda'));
      });

      test('should handle weak-password error correctly', () {
        final exception = FirebaseAuthException(
          code: 'weak-password',
          message: 'Weak password',
        );
        
        final result = authService.handleAuthException(exception);
        expect(result, contains('Şifre çok zayıf'));
      });

      test('should handle network-request-failed error correctly', () {
        final exception = FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Network error',
        );
        
        final result = authService.handleAuthException(exception);
        expect(result, contains('İnternet bağlantısı sorunu'));
      });

      test('should handle too-many-requests error correctly', () {
        final exception = FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Too many requests',
        );
        
        final result = authService.handleAuthException(exception);
        expect(result, contains('Çok fazla başarısız deneme'));
      });

      test('should handle expired-action-code error correctly', () {
        final exception = FirebaseAuthException(
          code: 'expired-action-code',
          message: 'Expired action code',
        );
        
        final result = authService.handleAuthException(exception);
        expect(result, contains('Şifre sıfırlama kodu süresi dolmuş'));
      });

      test('should handle invalid-action-code error correctly', () {
        final exception = FirebaseAuthException(
          code: 'invalid-action-code',
          message: 'Invalid action code',
        );
        
        final result = authService.handleAuthException(exception);
        expect(result, contains('Geçersiz şifre sıfırlama kodu'));
      });

      test('should handle unknown error codes with default message', () {
        final exception = FirebaseAuthException(
          code: 'unknown-error',
          message: 'Unknown error occurred',
        );
        
        final result = authService.handleAuthException(exception);
        expect(result, equals('Unknown error occurred'));
      });
    });

    group('Rate Limiting Tests', () {
      test('should not be rate limited initially', () {
        expect(authService.isRateLimited('test@example.com'), isFalse);
      });

      test('should be rate limited after max failed attempts', () {
        const email = 'test@example.com';
        
        // Record maximum failed attempts
        for (int i = 0; i < 5; i++) {
          authService.recordFailedAttempt(email);
        }
        
        expect(authService.isRateLimited(email), isTrue);
      });

      test('should clear failed attempts on successful authentication', () {
        const email = 'test@example.com';
        
        // Record some failed attempts
        authService.recordFailedAttempt(email);
        authService.recordFailedAttempt(email);
        
        // Clear failed attempts
        authService.clearFailedAttempts(email);
        
        expect(authService.isRateLimited(email), isFalse);
      });
    });

    group('Retry Logic Tests', () {
      test('should not retry for non-retryable errors', () {
        expect(authService.shouldNotRetry('user-not-found'), isTrue);
        expect(authService.shouldNotRetry('wrong-password'), isTrue);
        expect(authService.shouldNotRetry('email-already-in-use'), isTrue);
        expect(authService.shouldNotRetry('weak-password'), isTrue);
        expect(authService.shouldNotRetry('invalid-email'), isTrue);
        expect(authService.shouldNotRetry('user-disabled'), isTrue);
        expect(authService.shouldNotRetry('invalid-credential'), isTrue);
        expect(authService.shouldNotRetry('operation-not-allowed'), isTrue);
      });

      test('should retry for retryable errors', () {
        expect(authService.shouldNotRetry('network-request-failed'), isFalse);
        expect(authService.shouldNotRetry('internal-error'), isFalse);
        expect(authService.shouldNotRetry('service-unavailable'), isFalse);
        expect(authService.shouldNotRetry('timeout'), isFalse);
      });
    });

    group('Input Validation Integration Tests', () {
      test('should validate all inputs for sign up', () async {
        // Test with invalid email
        try {
          await authService.signUpWithEmailAndPassword(
            email: 'invalid-email',
            password: 'password123',
            displayName: 'Test User',
          );
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('Geçerli bir e-posta adresi girin'));
        }

        // Test with weak password
        try {
          await authService.signUpWithEmailAndPassword(
            email: 'test@example.com',
            password: '123',
            displayName: 'Test User',
          );
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('Şifre en az 6 karakter olmalıdır'));
        }

        // Test with invalid display name
        try {
          await authService.signUpWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
            displayName: '',
          );
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('Ad soyad gereklidir'));
        }
      });

      test('should validate inputs for sign in', () async {
        // Test with invalid email
        try {
          await authService.signInWithEmailAndPassword(
            email: 'invalid-email',
            password: 'password123',
          );
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('Geçerli bir e-posta adresi girin'));
        }

        // Test with empty password
        try {
          await authService.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: '',
          );
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('Şifre gereklidir'));
        }
      });

      test('should validate email for password reset', () async {
        // Test with invalid email
        try {
          await authService.sendPasswordResetEmail('invalid-email');
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('Geçerli bir e-posta adresi girin'));
        }

        // Test with empty email
        try {
          await authService.sendPasswordResetEmail('');
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('E-posta adresi gereklidir'));
        }
      });
    });

    group('Password Reset Flow Tests', () {
      test('should validate password reset code', () async {
        // Test with empty code
        try {
          await authService.verifyPasswordResetCode('');
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('Doğrulama kodu gereklidir'));
        }
      });

      test('should validate new password in confirm reset', () async {
        // Test with weak password
        try {
          await authService.confirmPasswordReset(
            code: 'valid-code',
            newPassword: '123',
          );
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('Şifre en az 6 karakter olmalıdır'));
        }

        // Test with empty code
        try {
          await authService.confirmPasswordReset(
            code: '',
            newPassword: 'password123',
          );
          fail('Should have thrown validation error');
        } catch (e) {
          expect(e.toString(), contains('Doğrulama kodu gereklidir'));
        }
      });

      test('should return false for invalid password reset code', () async {
        // This test would need proper mocking of Firebase Auth
        // For now, we test the method exists and handles errors gracefully
        final isValid = await authService.isPasswordResetCodeValid('invalid-code');
        expect(isValid, isFalse);
      });
    });
  });
}