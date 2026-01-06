import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../models/security/security_models.dart';
import '../../models/security/session_data.dart';
import '../../models/security/auth_state.dart';
import 'secure_storage_service.dart';
import 'interfaces/session_manager_interface.dart';

class SessionManager implements ISessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final AuthSecureStorageService _storage = AuthSecureStorageService();
  
  // Oturum durumu stream controller
  final StreamController<SessionState> _sessionStateController = StreamController<SessionState>.broadcast();
  
  // Mevcut oturum durumu
  SessionState _currentSessionState = SessionState.inactive();
  
  // Timer'lar
  Timer? _sessionTimeoutTimer;
  Timer? _backgroundLockTimer;
  Timer? _sensitiveOperationTimer;
  Timer? _activityCheckTimer;
  
  // Uygulama yaşam döngüsü durumu
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Son aktivite zamanı
  DateTime _lastActivityTime = DateTime.now();
  
  // Hassas ekran durumu
  bool _isInSensitiveScreen = false;
  
  // Arka plan geçiş zamanı
  DateTime? _backgroundTime;
  
  bool _isInitialized = false;

  /// Session state stream
  @override
  Stream<SessionState> get sessionStateStream => _sessionStateController.stream;
  
  /// Current session state
  @override
  SessionState get currentSessionState => _currentSessionState;
  
  /// Son aktivite zamanı
  DateTime get lastActivityTime => _lastActivityTime;
  
  /// Hassas ekran durumu
  bool get isInSensitiveScreen => _isInSensitiveScreen;
  
  /// Uygulama yaşam döngüsü durumu
  AppLifecycleState get appLifecycleState => _appLifecycleState;

  /// Initialize the session manager
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Storage servisini başlat
      await _storage.initialize();
      
      // Mevcut oturum durumunu yükle
      await _loadStoredSessionState();
      
      // Aktivite kontrol timer'ını başlat
      _startActivityCheckTimer();
      
      _isInitialized = true;
      debugPrint('Session Manager initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize Session Manager: ${e.toString()}');
    }
  }

  /// Start a new session with comprehensive security policies
  /// 
  /// [sessionData] - Session data to create
  /// [authMethod] - Authentication method used
  /// [metadata] - Additional metadata
  /// 
  /// Returns true if session was created successfully
  /// 
  /// Implements Requirements 5.1, 5.2: Secure session creation and timeout settings
  Future<bool> startSession({
    required SessionData sessionData,
    required AuthMethod authMethod,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _ensureInitialized();
      
      // Validate security configuration
      final config = await _getSecurityConfig();
      final validation = config.validate();
      if (validation != null) {
        debugPrint('Security config validation failed: $validation');
        return false;
      }
      
      // Stop any existing session
      await stopSession();
      
      // Create new session state
      _currentSessionState = SessionState.active(
        sessionData: sessionData,
        authMethod: authMethod,
        metadata: metadata,
      );
      
      // Update activity time
      _lastActivityTime = DateTime.now();
      _backgroundTime = null;
      
      // Start session timer with configured timeout
      await _startSessionTimer();
      
      // Save session state
      await _saveSessionState();
      
      // Notify listeners
      _sessionStateController.add(_currentSessionState);
      
      debugPrint('Session started successfully: ${sessionData.sessionId}');
      debugPrint('Session timeout: ${config.sessionTimeout}');
      debugPrint('Sensitive operation timeout: ${config.sessionConfig.sensitiveOperationTimeout}');
      
      return true;
    } catch (e) {
      debugPrint('Failed to start session: $e');
      return false;
    }
  }

  /// Stop the current session and clean up resources
  /// 
  /// Cancels all timers and clears session data
  /// 
  /// Implements Requirements 5.2, 5.3: Session termination and cleanup
  Future<void> stopSession() async {
    try {
      await _ensureInitialized();
      
      // Cancel all timers
      _sessionTimeoutTimer?.cancel();
      _backgroundLockTimer?.cancel();
      _sensitiveOperationTimer?.cancel();
      
      // Clear background tracking
      _backgroundTime = null;
      _isInSensitiveScreen = false;
      
      // Update session state if it was active
      if (_currentSessionState.isActive) {
        _currentSessionState = _currentSessionState.terminate();
        
        // Clear stored session data
        await _clearStoredSessionState();
        await _storage.clearBackgroundTimestamp();
        
        // Notify listeners
        _sessionStateController.add(_currentSessionState);
        
        debugPrint('Session terminated and cleaned up');
      }
      
    } catch (e) {
      debugPrint('Failed to stop session: $e');
    }
  }

  /// Create a new session
  @override
  Future<bool> createSession({
    required SessionData sessionData,
    required AuthMethod authMethod,
    Map<String, dynamic>? metadata,
  }) async {
    return await startSession(
      sessionData: sessionData,
      authMethod: authMethod,
      metadata: metadata,
    );
  }

  /// Extend the current session
  @override
  Future<void> extendSession() async {
    await recordActivity();
  }

  /// Invalidate the current session
  @override
  Future<void> invalidateSession() async {
    await stopSession();
  }

  /// Check if session is valid
  @override
  Future<bool> isSessionValid() async {
    return await isSessionActive();
  }

  /// Check if re-authentication is required
  @override
  Future<bool> requiresReauth() async {
    try {
      await _ensureInitialized();
      
      if (!_currentSessionState.isActive) return true;
      
      final config = await _getSecurityConfig();
      
      // Check if sensitive operation timeout has passed
      if (_isInSensitiveScreen && _currentSessionState.sessionData != null) {
        final sessionData = _currentSessionState.sessionData!;
        if (sessionData.requiresSensitiveAuth(config.sessionConfig.sensitiveOperationTimeout)) {
          return true;
        }
      }
      
      // Check regular session timeout
      final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
      return timeSinceLastActivity > config.sessionTimeout;
    } catch (e) {
      debugPrint('Reauth check error: $e');
      return true;
    }
  }

  /// Record user activity
  @override
  Future<void> recordActivity() async {
    try {
      await _ensureInitialized();
      
      if (!_currentSessionState.isActive) return;
      
      // Update activity time
      _lastActivityTime = DateTime.now();
      
      // Update session state
      _currentSessionState = _currentSessionState.updateActivity();
      
      // Update session data activity time
      if (_currentSessionState.sessionData != null) {
        final updatedSessionData = _currentSessionState.sessionData!.updateActivity();
        _currentSessionState = _currentSessionState.copyWith(sessionData: updatedSessionData);
      }
      
      // Refresh session timer
      await _refreshSessionTimer();
      
      // Save state (throttled to avoid excessive I/O)
      await _saveSessionStateThrottled();
      
      debugPrint('User activity recorded at $_lastActivityTime');
    } catch (e) {
      debugPrint('Failed to record activity: $e');
    }
  }

  /// Handle app background
  @override
  Future<void> onAppBackground() async {
    try {
      await _ensureInitialized();
      
      _appLifecycleState = AppLifecycleState.paused;
      _backgroundTime = DateTime.now();
      
      if (!_currentSessionState.isActive) return;
      
      // Store background timestamp for security tracking
      await _storage.storeBackgroundTimestamp(_backgroundTime!);
      
      // Start background lock timer based on security configuration
      final config = await _getSecurityConfig();
      if (config.sessionConfig.enableBackgroundLock) {
        _backgroundLockTimer?.cancel();
        _backgroundLockTimer = Timer(config.sessionConfig.backgroundLockDelay, () {
          _onBackgroundLockTimeout();
        });
        
        debugPrint('Background lock timer started: ${config.sessionConfig.backgroundLockDelay}');
      }
      
      // Update session state to reflect background mode
      _currentSessionState = _currentSessionState.enterBackground();
      _sessionStateController.add(_currentSessionState);
      
      debugPrint('App entered background, security timers activated');
      
    } catch (e) {
      debugPrint('App background handling error: $e');
    }
  }

  /// Handle app foreground
  @override
  Future<void> onAppForeground() async {
    try {
      await _ensureInitialized();
      
      _appLifecycleState = AppLifecycleState.resumed;
      
      // Calculate time spent in background
      if (_backgroundTime != null) {
        final timeInBackground = DateTime.now().difference(_backgroundTime!);
        final config = await _getSecurityConfig();
        
        // Check if background time exceeded security threshold
        if (config.sessionConfig.enableBackgroundLock && 
            timeInBackground > config.sessionConfig.backgroundLockDelay) {
          debugPrint('Background time exceeded threshold, invalidating session');
          await stopSession();
          return;
        }
        
        _backgroundTime = null;
        await _storage.clearBackgroundTimestamp();
      }
      
      // Cancel background timer
      _backgroundLockTimer?.cancel();
      _backgroundLockTimer = null;
      
      if (!_currentSessionState.isActive) return;
      
      // Update session state to reflect foreground mode
      _currentSessionState = _currentSessionState.enterForeground();
      _sessionStateController.add(_currentSessionState);
      
      // Refresh session timer
      await _refreshSessionTimer();
      
      debugPrint('App returned to foreground, session validated');
      
    } catch (e) {
      debugPrint('App foreground handling error: $e');
    }
  }

  /// Set sensitive screen state
  @override
  Future<void> setSensitiveScreenState(bool isSensitive) async {
    try {
      await _ensureInitialized();
      
      _isInSensitiveScreen = isSensitive;
      
      if (!_currentSessionState.isActive) return;
      
      if (isSensitive) {
        // Start sensitive operation timer
        await _startSensitiveOperationTimer();
        
        // Update session data to mark sensitive auth time
        if (_currentSessionState.sessionData != null) {
          final updatedSessionData = _currentSessionState.sessionData!.updateSensitiveAuth();
          _currentSessionState = _currentSessionState.copyWith(sessionData: updatedSessionData);
        }
        
        debugPrint('Sensitive screen mode activated');
      } else {
        // Cancel sensitive operation timer
        _sensitiveOperationTimer?.cancel();
        debugPrint('Sensitive screen mode deactivated');
      }
      
      // Update session state
      _currentSessionState = _currentSessionState.setSensitiveScreen(isSensitive);
      _sessionStateController.add(_currentSessionState);
      
      // Save updated state
      await _saveSessionState();
      
    } catch (e) {
      debugPrint('Failed to set sensitive screen state: $e');
    }
  }

  /// Check if session is active with comprehensive validation
  /// 
  /// Returns true if session is active and valid
  /// 
  /// Implements Requirements 5.1, 5.2, 5.3: Session creation, timeout tracking, and expiration
  Future<bool> isSessionActive() async {
    try {
      await _ensureInitialized();
      
      if (!_currentSessionState.isActive) return false;
      
      final config = await _getSecurityConfig();
      final now = DateTime.now();
      
      // Check regular session timeout
      final timeSinceLastActivity = now.difference(_lastActivityTime);
      if (timeSinceLastActivity > config.sessionTimeout) {
        debugPrint('Session expired due to inactivity: $timeSinceLastActivity');
        await stopSession();
        return false;
      }
      
      // Check background timeout if applicable
      if (_currentSessionState.isInBackground && _backgroundTime != null) {
        final timeInBackground = now.difference(_backgroundTime!);
        if (config.sessionConfig.enableBackgroundLock && 
            timeInBackground > config.sessionConfig.backgroundLockDelay) {
          debugPrint('Session expired due to background timeout: $timeInBackground');
          await stopSession();
          return false;
        }
      }
      
      // Check sensitive operation timeout if in sensitive screen
      if (_isInSensitiveScreen && _currentSessionState.sessionData != null) {
        final sessionData = _currentSessionState.sessionData!;
        if (sessionData.requiresSensitiveAuth(config.sessionConfig.sensitiveOperationTimeout)) {
          debugPrint('Session requires re-authentication for sensitive operation');
          // Don't stop session, but indicate re-auth needed
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Session active check error: $e');
      return false;
    }
  }

  /// Get session remaining time
  @override
  Future<Duration?> getSessionRemainingTime() async {
    try {
      await _ensureInitialized();
      
      if (!_currentSessionState.isActive) return null;
      
      final config = await _getSecurityConfig();
      final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
      final remainingTime = config.sessionTimeout - timeSinceLastActivity;
      
      return remainingTime.isNegative ? Duration.zero : remainingTime;
    } catch (e) {
      debugPrint('Get session remaining time error: $e');
      return null;
    }
  }

  /// Update security configuration
  @override
  Future<bool> updateSecurityConfig(SecurityConfig config) async {
    try {
      await _ensureInitialized();
      
      // Konfigürasyonu validate et
      final validation = config.validate();
      if (validation != null) {
        debugPrint('Security config validation failed: $validation');
        return false;
      }
      
      // Konfigürasyonu kaydet
      await _storage.storeSecurityConfig(config);
      
      // Aktif oturum varsa timer'ları güncelle
      if (_currentSessionState.isActive) {
        await _refreshSessionTimer();
        
        if (_isInSensitiveScreen) {
          await _startSensitiveOperationTimer();
        }
      }
      
      debugPrint('Security config updated, timers refreshed');
      return true;
    } catch (e) {
      debugPrint('Security config update error: $e');
      return false;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _sessionTimeoutTimer?.cancel();
    _backgroundLockTimer?.cancel();
    _sensitiveOperationTimer?.cancel();
    _activityCheckTimer?.cancel();
    _sessionStateController.close();
  }

  /// Reset service for testing purposes
  /// 
  /// This method is intended for testing only and should not be used in production
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _currentSessionState = SessionState.inactive();
    _lastActivityTime = DateTime.now();
    _isInSensitiveScreen = false;
    _backgroundTime = null;
    _appLifecycleState = AppLifecycleState.resumed;
    _sessionTimeoutTimer?.cancel();
    _backgroundLockTimer?.cancel();
    _sensitiveOperationTimer?.cancel();
    _activityCheckTimer?.cancel();
    // ignore: invalid_use_of_visible_for_testing_member
    _storage.resetForTesting();
  }

  // Private helper methods

  /// Servisin başlatıldığından emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Oturum timer'ını başlatır
  Future<void> _startSessionTimer() async {
    final config = await _getSecurityConfig();
    
    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = Timer(config.sessionTimeout, () {
      _onSessionTimeout();
    });
    
    debugPrint('Session timer started: ${config.sessionTimeout}');
  }

  /// Oturum timer'ını yeniler
  Future<void> _refreshSessionTimer() async {
    if (_currentSessionState.isActive) {
      await _startSessionTimer();
    }
  }

  /// Hassas işlem timer'ını başlatır
  Future<void> _startSensitiveOperationTimer() async {
    final config = await _getSecurityConfig();
    
    _sensitiveOperationTimer?.cancel();
    _sensitiveOperationTimer = Timer(config.sessionConfig.sensitiveOperationTimeout, () {
      _onSensitiveOperationTimeout();
    });
    
    debugPrint('Sensitive operation timer started: ${config.sessionConfig.sensitiveOperationTimeout}');
  }

  /// Aktivite kontrol timer'ını başlatır
  void _startActivityCheckTimer() {
    _activityCheckTimer?.cancel();
    _activityCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkSessionActivity();
    });
  }

  /// Oturum zaman aşımı callback'i
  void _onSessionTimeout() {
    debugPrint('Session timeout occurred');
    stopSession();
  }

  /// Arka plan kilitleme zaman aşımı callback'i
  void _onBackgroundLockTimeout() {
    debugPrint('Background lock timeout occurred');
    stopSession();
  }

  /// Hassas işlem zaman aşımı callback'i
  void _onSensitiveOperationTimeout() {
    debugPrint('Sensitive operation timeout occurred');
    stopSession();
  }

  /// Oturum aktivitesini kontrol eder
  Future<void> _checkSessionActivity() async {
    try {
      if (!_currentSessionState.isActive) return;
      
      final config = await _getSecurityConfig();
      final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
      
      if (timeSinceLastActivity > config.sessionTimeout) {
        debugPrint('Session inactive for too long, terminating');
        await stopSession();
      }
    } catch (e) {
      debugPrint('Session activity check error: $e');
    }
  }

  /// Güvenlik konfigürasyonunu alır
  Future<SecurityConfig> _getSecurityConfig() async {
    try {
      final config = await _storage.getSecurityConfig();
      return config ?? SecurityConfig.defaultConfig();
    } catch (e) {
      debugPrint('Failed to get security config: $e');
      return SecurityConfig.defaultConfig();
    }
  }

  /// Oturum durumunu kaydeder
  Future<void> _saveSessionState() async {
    try {
      await _storage.storeSessionState(_currentSessionState);
    } catch (e) {
      debugPrint('Failed to save session state: $e');
    }
  }

  /// Oturum durumunu throttle edilmiş şekilde kaydeder
  Timer? _saveThrottleTimer;
  Future<void> _saveSessionStateThrottled() async {
    _saveThrottleTimer?.cancel();
    _saveThrottleTimer = Timer(const Duration(seconds: 5), () {
      _saveSessionState();
    });
  }

  /// Depolanan oturum durumunu yükler
  Future<void> _loadStoredSessionState() async {
    try {
      final storedStateMap = await _storage.getSessionState();
      
      if (storedStateMap != null) {
        final storedSessionState = SessionState.fromJson(storedStateMap as Map<String, dynamic>);
        
        if (storedSessionState.isActive) {
          final config = await _getSecurityConfig();
          
          // Oturum süresi kontrolü
          final timeSinceLastActivity = DateTime.now().difference(storedSessionState.lastActivityTime);
          
          if (timeSinceLastActivity <= config.sessionTimeout) {
            
            // Check background lock logic on restoration
            bool shouldLock = false;
            
            // If background lock is enabled, check if enough time passed to lock
            if (config.sessionConfig.enableBackgroundLock) {
               // If app was killed/restarted, we treat 'timeSinceLastActivity' as time spent 'away'
               if (timeSinceLastActivity > config.sessionConfig.backgroundLockDelay) {
                 shouldLock = true;
               }
            }

            if (shouldLock) {
               // Clear session if lock condition met on startup
               await _clearStoredSessionState();
               debugPrint('Stored session valid but background lock timeout exceeded, cleared');
               _currentSessionState = SessionState.inactive();
            } else {
               _currentSessionState = storedSessionState;
               _lastActivityTime = storedSessionState.lastActivityTime;
               
               // Restart timers
               await _startSessionTimer();
               
               debugPrint('Stored session state loaded successfully');
            }
          } else {
            // Expired session
            await _clearStoredSessionState();
            debugPrint('Stored session expired, cleared');
            _currentSessionState = SessionState.inactive();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load stored session state: $e');
    }
  }

  /// Depolanan oturum durumunu temizler
  Future<void> _clearStoredSessionState() async {
    try {
      await _storage.clearSessionState();
    } catch (e) {
      debugPrint('Failed to clear stored session state: $e');
    }
  }
}

/// Session manager için singleton instance
class SessionManagerSingleton {
  static SessionManager? _instance;
  
  /// Singleton instance'ı döndürür
  static SessionManager get instance {
    _instance ??= SessionManager();
    return _instance!;
  }
  
  /// Test için instance'ı set eder
  static void setInstance(SessionManager manager) {
    _instance = manager;
  }
  
  /// Instance'ı temizler
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}