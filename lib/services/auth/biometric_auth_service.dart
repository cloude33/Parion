import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart' as local_auth;

import '../../models/security/security_models.dart';
import '../../models/security/biometric_type.dart';
import 'interfaces/biometric_auth_interface.dart';
import 'secure_storage_service.dart';
import 'biometric_service.dart';

/// Enhanced biometric authentication service with security features
/// 
/// This service provides comprehensive biometric authentication with:
/// - Availability detection
/// - Secure state storage
/// - Fallback mechanisms
/// - Rate limiting and security controls
/// 
/// Implements Requirements 4.1, 4.2, 4.3, 4.4, 4.5
class BiometricAuthService implements IBiometricAuthService {
  final BiometricService _biometricService;
  final AuthSecureStorageService _secureStorage;
  final local_auth.LocalAuthentication _localAuth;
  
  // Rate limiting for security
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  // Cache for performance
  bool? _cachedAvailability;
  List<BiometricType>? _cachedTypes;
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // State management
  bool _isInitialized = false;
  int _failedAttempts = 0;
  DateTime? _lockoutTime;
  
  BiometricAuthService({
    BiometricService? biometricService,
    AuthSecureStorageService? secureStorage,
    local_auth.LocalAuthentication? localAuth,
  }) : _biometricService = biometricService ?? BiometricServiceSingleton.instance,
       _secureStorage = secureStorage ?? AuthSecureStorageService(),
       _localAuth = localAuth ?? local_auth.LocalAuthentication();

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _secureStorage.initialize();
      
      // Load failed attempts and lockout state
      _failedAttempts = await _secureStorage.getFailedAttempts();
      _lockoutTime = await _secureStorage.getLockoutTime();
      
      _isInitialized = true;
      debugPrint('BiometricAuthService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize BiometricAuthService: $e');
      throw Exception('BiometricAuthService initialization failed: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    await _ensureInitialized();
    
    try {
      // Check cache first for performance
      if (_cachedAvailability != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheExpiry) {
          return _cachedAvailability!;
        }
      }
      
      // Use the injected biometric service for consistency
      final isAvailable = await _biometricService.isBiometricAvailable();
      
      // Get available types for caching
      final availableTypes = await getAvailableTypes();
      
      _updateCache(isAvailable, availableTypes);
      return isAvailable;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      _updateCache(false, null);
      return false;
    }
  }

  @override
  Future<List<BiometricType>> getAvailableTypes() async {
    await _ensureInitialized();
    
    try {
      // Check cache first for performance
      if (_cachedTypes != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheExpiry) {
          return _cachedTypes!;
        }
      }
      
      // Get available biometric types from the underlying service
      final types = await _biometricService.getAvailableBiometrics();
      
      // Update cache
      _cachedTypes = types;
      _cacheTimestamp = DateTime.now();
      
      return types;
    } catch (e) {
      debugPrint('Error getting available biometric types: $e');
      return [];
    }
  }

  @override
  Future<AuthResult> authenticate({
    required String reason,
    String? localizedFallbackTitle,
    String? cancelButtonText,
  }) async {
    await _ensureInitialized();
    
    try {
      // Check if service is locked out due to failed attempts
      if (await _isLockedOut()) {
        final remainingTime = _getRemainingLockoutTime();
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Çok fazla başarısız deneme. ${remainingTime.inMinutes} dakika sonra tekrar deneyin.',
          lockoutDuration: remainingTime,
          remainingAttempts: 0,
        );
      }
      
      // Check if biometric authentication is available
      if (!await isAvailable()) {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Biyometrik kimlik doğrulama bu cihazda mevcut değil',
        );
      }
      
      // Check if biometric is enabled for the user
      if (!await isBiometricEnabled()) {
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: 'Biyometrik kimlik doğrulama etkinleştirilmemiş',
        );
      }
      
      // Perform biometric authentication
      final authResult = await _biometricService.authenticate(
        localizedFallbackTitle: localizedFallbackTitle,
        cancelButtonText: cancelButtonText,
      );
      
      if (authResult.isSuccess) {
        // Reset failed attempts on successful authentication
        await _resetFailedAttempts();
        
        return AuthResult.success(
          method: AuthMethod.biometric,
          metadata: {
            'timestamp': DateTime.now().toIso8601String(),
            'availableTypes': (await getAvailableTypes()).map((t) => t.toJson()).toList(),
            'reason': reason,
          },
        );
      } else {
        // Handle failed authentication
        await _handleFailedAttempt();
        
        final remainingAttempts = _maxFailedAttempts - _failedAttempts;
        return AuthResult.failure(
          method: AuthMethod.biometric,
          errorMessage: authResult.errorMessage ?? 'Biyometrik kimlik doğrulama başarısız',
          remainingAttempts: remainingAttempts > 0 ? remainingAttempts : 0,
          metadata: authResult.metadata,
        );
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      await _handleFailedAttempt();
      
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: 'Biyometrik kimlik doğrulama sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> enableBiometric() async {
    await _ensureInitialized();
    
    try {
      // Check if biometric authentication is available
      if (!await isAvailable()) {
        throw Exception('Biyometrik kimlik doğrulama bu cihazda mevcut değil');
      }
      
      // Get the available biometric types (only platform-supported ones)
      final availableTypes = await getAvailableTypes();
      if (availableTypes.isEmpty) {
        throw Exception('Kullanılabilir biyometrik tür bulunamadı');
      }
      
      // Filter out unsupported types (like voice) that may be in our enum but not supported by platform
      final supportedTypes = availableTypes.where((type) => 
        type == BiometricType.fingerprint || 
        type == BiometricType.face || 
        type == BiometricType.iris
      ).toList();
      
      if (supportedTypes.isEmpty) {
        throw Exception('Desteklenen biyometrik tür bulunamadı');
      }
      
      final primaryType = supportedTypes.first;
      
      // Store biometric configuration
      final success = await _secureStorage.storeBiometricConfig(
        true,
        primaryType.toJson(),
      );
      
      if (!success) {
        throw Exception('Biyometrik ayarlar kaydedilemedi');
      }
      
      debugPrint('Biometric authentication enabled for type: ${primaryType.displayName}');
    } catch (e) {
      debugPrint('Failed to enable biometric authentication: $e');
      rethrow;
    }
  }

  @override
  Future<void> disableBiometric() async {
    await _ensureInitialized();
    
    try {
      // Store disabled configuration
      final success = await _secureStorage.storeBiometricConfig(false, 'none');
      
      if (!success) {
        throw Exception('Biyometrik ayarlar güncellenemedi');
      }
      
      // Reset failed attempts when disabling
      await _resetFailedAttempts();
      
      debugPrint('Biometric authentication disabled');
    } catch (e) {
      debugPrint('Failed to disable biometric authentication: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isBiometricEnabled() async {
    await _ensureInitialized();
    
    try {
      final config = await _secureStorage.getBiometricConfig();
      return config?['enabled'] == true;
    } catch (e) {
      debugPrint('Error checking biometric enabled status: $e');
      return false;
    }
  }

  @override
  void dispose() {
    // Clear cache
    _cachedAvailability = null;
    _cachedTypes = null;
    _cacheTimestamp = null;
    
    debugPrint('BiometricAuthService disposed');
  }

  // Private helper methods

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  void _updateCache(bool availability, List<BiometricType>? types) {
    _cachedAvailability = availability;
    _cachedTypes = types;
    _cacheTimestamp = DateTime.now();
  }

  Future<bool> _isLockedOut() async {
    if (_lockoutTime == null) return false;
    
    final now = DateTime.now();
    if (now.isBefore(_lockoutTime!)) {
      return true;
    } else {
      // Lockout period has expired, clear it
      await _clearLockout();
      return false;
    }
  }

  Duration _getRemainingLockoutTime() {
    if (_lockoutTime == null) return Duration.zero;
    
    final now = DateTime.now();
    if (now.isBefore(_lockoutTime!)) {
      return _lockoutTime!.difference(now);
    }
    
    return Duration.zero;
  }

  Future<void> _handleFailedAttempt() async {
    _failedAttempts++;
    await _secureStorage.storeFailedAttempts(_failedAttempts);
    
    if (_failedAttempts >= _maxFailedAttempts) {
      // Lock out the service
      _lockoutTime = DateTime.now().add(_lockoutDuration);
      await _secureStorage.storeLockoutTime(_lockoutTime!);
      
      debugPrint('Biometric service locked out due to too many failed attempts');
    }
  }

  Future<void> _resetFailedAttempts() async {
    _failedAttempts = 0;
    await _secureStorage.storeFailedAttempts(0);
    await _clearLockout();
  }

  Future<void> _clearLockout() async {
    _lockoutTime = null;
    await _secureStorage.clearLockout();
  }
}

/// Singleton instance for BiometricAuthService
class BiometricAuthServiceSingleton {
  static BiometricAuthService? _instance;

  /// Get the singleton instance
  static BiometricAuthService get instance {
    _instance ??= BiometricAuthService();
    return _instance!;
  }

  /// Set a custom instance (for testing)
  static void setInstance(BiometricAuthService service) {
    _instance = service;
  }

  /// Reset the singleton (for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}