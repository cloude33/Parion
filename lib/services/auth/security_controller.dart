import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/security/security_models.dart';
import 'interfaces/security_controller_interface.dart';

/// Comprehensive security controller implementation
/// 
/// Provides secure storage, encryption, rate limiting, and security event logging
/// for the authentication system.
class SecurityController implements ISecurityController {
  static const String _encryptionKeyName = 'auth_encryption_key';
  static const String _rateLimitPrefix = 'rate_limit_';
  static const String _securityConfigKey = 'security_config';
  
  final FlutterSecureStorage _secureStorage;
  final StreamController<SecurityEvent> _securityEventsController;
  final Map<String, List<DateTime>> _rateLimitTracker;
  
  SecurityConfig? _cachedConfig;
  List<int>? _encryptionKey;
  
  SecurityController({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(
         aOptions: AndroidOptions(
           // encryptedSharedPreferences: true, // Deprecated
         ),
         iOptions: IOSOptions(
           accessibility: KeychainAccessibility.first_unlock_this_device,
         ),
       ),
       _securityEventsController = StreamController<SecurityEvent>.broadcast(),
       _rateLimitTracker = {};

  @override
  Stream<SecurityEvent> get securityEventsStream => _securityEventsController.stream;

  @override
  Future<void> initialize() async {
    try {
      // Initialize encryption key
      await _getOrGenerateEncryptionKey();
      
      // Load security configuration
      await _loadSecurityConfig();
      
      // Log initialization event
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.securitySettingsChanged,
          description: 'Security controller initialized',
          severity: SecurityEventSeverity.info,
          source: 'SecurityController',
        ),
      );
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Failed to initialize security controller: $e',
          severity: SecurityEventSeverity.error,
          source: 'SecurityController',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> storeSecurely(
    String key, 
    String value, {
    bool encrypted = true,
  }) async {
    try {
      String finalValue = value;
      
      if (encrypted) {
        finalValue = await encryptForTransmission(value);
      }
      
      await _secureStorage.write(key: key, value: finalValue);
      
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.securitySettingsChanged,
          description: 'Data stored securely: $key (encrypted: $encrypted)',
          severity: SecurityEventSeverity.info,
          source: 'SecurityController',
          metadata: {
            'key': key,
            'encrypted': encrypted,
          },
        ),
      );
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Failed to store data securely: $key - $e',
          severity: SecurityEventSeverity.error,
          source: 'SecurityController',
          metadata: {
            'key': key,
            'error': e.toString(),
          },
        ),
      );
      rethrow;
    }
  }

  @override
  Future<String?> retrieveSecurely(
    String key, {
    bool encrypted = true,
  }) async {
    try {
      final storedValue = await _secureStorage.read(key: key);
      
      if (storedValue == null) {
        return null;
      }
      
      if (encrypted) {
        return await decryptReceived(storedValue);
      }
      
      return storedValue;
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Failed to retrieve data securely: $key - $e',
          severity: SecurityEventSeverity.warning,
          source: 'SecurityController',
          metadata: {
            'key': key,
            'error': e.toString(),
          },
        ),
      );
      return null;
    }
  }

  @override
  Future<void> deleteSecurely(String key) async {
    try {
      await _secureStorage.delete(key: key);
      
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.securitySettingsChanged,
          description: 'Data deleted securely: $key',
          severity: SecurityEventSeverity.info,
          source: 'SecurityController',
          metadata: {
            'key': key,
          },
        ),
      );
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Failed to delete data securely: $key - $e',
          severity: SecurityEventSeverity.warning,
          source: 'SecurityController',
          metadata: {
            'key': key,
            'error': e.toString(),
          },
        ),
      );
      rethrow;
    }
  }

  @override
  Future<String> encryptForTransmission(String data) async {
    try {
      final key = await _getOrGenerateEncryptionKey();
      final dataBytes = utf8.encode(data);
      
      // Generate random IV
      final random = Random.secure();
      final iv = List<int>.generate(16, (_) => random.nextInt(256));
      
      // Simple XOR encryption with key rotation
      final encrypted = <int>[];
      for (int i = 0; i < dataBytes.length; i++) {
        final keyByte = key[(i + iv[i % 16]) % key.length];
        encrypted.add(dataBytes[i] ^ keyByte);
      }
      
      // Combine IV and encrypted data
      final combined = [...iv, ...encrypted];
      
      // Encode as base64
      return base64.encode(combined);
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Encryption failed: $e',
          severity: SecurityEventSeverity.error,
          source: 'SecurityController',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<String> decryptReceived(String encryptedData) async {
    try {
      final key = await _getOrGenerateEncryptionKey();
      final combined = base64.decode(encryptedData);
      
      if (combined.length < 16) {
        throw Exception('Invalid encrypted data format');
      }
      
      // Extract IV and encrypted data
      final iv = combined.sublist(0, 16);
      final encrypted = combined.sublist(16);
      
      // Decrypt using XOR with key rotation
      final decrypted = <int>[];
      for (int i = 0; i < encrypted.length; i++) {
        final keyByte = key[(i + iv[i % 16]) % key.length];
        decrypted.add(encrypted[i] ^ keyByte);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Decryption failed: $e',
          severity: SecurityEventSeverity.error,
          source: 'SecurityController',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<bool> checkRateLimit(
    String operation,
    int maxAttempts,
    Duration timeWindow,
  ) async {
    try {
      final now = DateTime.now();
      final key = '$_rateLimitPrefix$operation';
      
      // Get or create attempt list for this operation
      final attempts = _rateLimitTracker[key] ?? <DateTime>[];
      
      // Remove old attempts outside the time window
      attempts.removeWhere((attempt) => 
        now.difference(attempt) > timeWindow);
      
      // Check if we're within the limit
      if (attempts.length >= maxAttempts) {
        await logSecurityEvent(
          SecurityEvent.rateLimitExceeded(
            operation: operation,
            timestamp: now,
            metadata: {
              'maxAttempts': maxAttempts,
              'timeWindow': timeWindow.inMilliseconds,
              'currentAttempts': attempts.length,
            },
          ),
        );
        return false;
      }
      
      // Add current attempt
      attempts.add(now);
      _rateLimitTracker[key] = attempts;
      
      return true;
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Rate limit check failed: $operation - $e',
          severity: SecurityEventSeverity.warning,
          source: 'SecurityController',
          metadata: {
            'operation': operation,
            'error': e.toString(),
          },
        ),
      );
      // Fail safe - deny access on error
      return false;
    }
  }

  @override
  Future<void> logSecurityEvent(SecurityEvent event) async {
    try {
      // Add to stream for real-time monitoring
      _securityEventsController.add(event);
      
      // Store event for audit trail (in production, this would go to a secure log)
      if (kDebugMode) {
        debugPrint('Security Event: ${event.toString()}');
      }
      
      // In production, you would send critical events to a security monitoring system
      if (event.severity == SecurityEventSeverity.critical) {
        await _sendToMonitoring(event);
      }
    } catch (e) {
      // Logging should never fail the main operation
      if (kDebugMode) {
        debugPrint('Failed to log security event: $e');
      }
    }
  }

  Future<void> _sendToMonitoring(SecurityEvent event) async {
    try {
      debugPrint('Monitoring: ${event.toString()}');
    } catch (_) {}
  }

  @override
  Future<SecurityConfig> getSecurityConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }
    
    return await _loadSecurityConfig();
  }

  @override
  Future<bool> updateSecurityConfig(SecurityConfig config) async {
    try {
      // Validate configuration
      final validationError = config.validate();
      if (validationError != null) {
        await logSecurityEvent(
          SecurityEvent(
            type: SecurityEventType.suspiciousActivity,
            description: 'Invalid security config update: $validationError',
            severity: SecurityEventSeverity.warning,
            source: 'SecurityController',
          ),
        );
        return false;
      }
      
      // Store configuration
      final configJson = json.encode(config.toJson());
      await storeSecurely(_securityConfigKey, configJson);
      
      // Update cache
      _cachedConfig = config;
      
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.securitySettingsChanged,
          description: 'Security configuration updated',
          severity: SecurityEventSeverity.info,
          source: 'SecurityController',
        ),
      );
      
      return true;
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Failed to update security config: $e',
          severity: SecurityEventSeverity.error,
          source: 'SecurityController',
        ),
      );
      return false;
    }
  }

  @override
  Future<SecurityValidationResult> validateSecurityRequirements(
    String operation,
    Map<String, dynamic> context,
  ) async {
    try {
      final config = await getSecurityConfig();
      
      // Check rate limiting
      final rateLimitPassed = await checkRateLimit(
        operation,
        5, // Default max attempts
        const Duration(minutes: 5), // Default time window
      );
      
      if (!rateLimitPassed) {
        return SecurityValidationResult.invalid(
          errorMessage: 'Rate limit exceeded for operation: $operation',
          requiredActions: ['Wait before retrying'],
          requiredLevel: SecurityLevel.high,
        );
      }
      
      // Check if operation requires additional authentication
      final sensitiveOperations = [
        'delete_account',
        'change_password',
        'export_data',
        'modify_security_settings',
      ];
      
      if (sensitiveOperations.contains(operation)) {
        final lastAuth = context['lastAuthTime'] as DateTime?;
        if (lastAuth == null || 
            DateTime.now().difference(lastAuth) > config.sessionConfig.sensitiveOperationTimeout) {
          return SecurityValidationResult.invalid(
            errorMessage: 'Additional authentication required for sensitive operation',
            requiredActions: ['Re-authenticate'],
            requiredLevel: SecurityLevel.high,
          );
        }
      }
      
      return SecurityValidationResult.valid();
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Security validation failed: $operation - $e',
          severity: SecurityEventSeverity.error,
          source: 'SecurityController',
        ),
      );
      
      return SecurityValidationResult.invalid(
        errorMessage: 'Security validation error',
        requiredActions: ['Contact support'],
        requiredLevel: SecurityLevel.critical,
      );
    }
  }

  @override
  void dispose() {
    _securityEventsController.close();
    _rateLimitTracker.clear();
    _cachedConfig = null;
    _encryptionKey = null;
  }

  /// Get or generate encryption key
  Future<List<int>> _getOrGenerateEncryptionKey() async {
    if (_encryptionKey != null) {
      return _encryptionKey!;
    }
    
    try {
      final keyString = await _secureStorage.read(key: _encryptionKeyName);
      
      if (keyString != null) {
        final keyList = json.decode(keyString) as List<dynamic>;
        _encryptionKey = keyList.cast<int>();
        return _encryptionKey!;
      }
      
      // Generate new key
      final random = Random.secure();
      _encryptionKey = List<int>.generate(32, (_) => random.nextInt(256));
      
      await _secureStorage.write(
        key: _encryptionKeyName, 
        value: json.encode(_encryptionKey),
      );
      
      return _encryptionKey!;
    } catch (e) {
      // Fallback to generated key
      final random = Random.secure();
      _encryptionKey = List<int>.generate(32, (_) => random.nextInt(256));
      return _encryptionKey!;
    }
  }

  /// Load security configuration
  Future<SecurityConfig> _loadSecurityConfig() async {
    try {
      final configJson = await retrieveSecurely(_securityConfigKey);
      
      if (configJson != null) {
        final configMap = json.decode(configJson) as Map<String, dynamic>;
        _cachedConfig = SecurityConfig.fromJson(configMap);
        return _cachedConfig!;
      }
      
      // Return default configuration
      _cachedConfig = SecurityConfig.defaultConfig();
      return _cachedConfig!;
    } catch (e) {
      await logSecurityEvent(
        SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          description: 'Failed to load security config, using defaults: $e',
          severity: SecurityEventSeverity.warning,
          source: 'SecurityController',
        ),
      );
      
      _cachedConfig = SecurityConfig.defaultConfig();
      return _cachedConfig!;
    }
  }
}
