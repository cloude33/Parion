import 'dart:async';
import '../../../models/security/security_models.dart';

/// Interface for session management
/// 
/// This interface defines the contract for managing user sessions,
/// including creation, validation, and lifecycle management.
abstract class ISessionManager {
  /// Session state stream
  Stream<SessionState> get sessionStateStream;
  
  /// Current session state
  SessionState get currentSessionState;
  
  /// Create a new session
  /// 
  /// [sessionData] - Session data to create
  /// [authMethod] - Authentication method used
  /// [metadata] - Additional metadata
  /// 
  /// Returns true if session was created successfully
  Future<bool> createSession({
    required SessionData sessionData,
    required AuthMethod authMethod,
    Map<String, dynamic>? metadata,
  });
  
  /// Extend the current session
  Future<void> extendSession();
  
  /// Invalidate the current session
  Future<void> invalidateSession();
  
  /// Check if session is valid
  Future<bool> isSessionValid();
  
  /// Check if re-authentication is required
  Future<bool> requiresReauth();
  
  /// Record user activity
  Future<void> recordActivity();
  
  /// Handle app background
  Future<void> onAppBackground();
  
  /// Handle app foreground
  Future<void> onAppForeground();
  
  /// Set sensitive screen state
  Future<void> setSensitiveScreenState(bool isSensitive);
  
  /// Get session remaining time
  Future<Duration?> getSessionRemainingTime();
  
  /// Update security configuration
  Future<bool> updateSecurityConfig(SecurityConfig config);
  
  /// Initialize the session manager
  Future<void> initialize();
  
  /// Dispose resources
  void dispose();
}

/// Session state model for the interface
class SessionState {
  final bool isActive;
  final SessionData? sessionData;
  final AuthMethod? authMethod;
  final DateTime lastActivityTime;
  final bool isInBackground;
  final bool isInSensitiveScreen;
  final Map<String, dynamic>? metadata;

  const SessionState({
    this.isActive = false,
    this.sessionData,
    this.authMethod,
    required this.lastActivityTime,
    this.isInBackground = false,
    this.isInSensitiveScreen = false,
    this.metadata,
  });

  factory SessionState.inactive() {
    return SessionState(
      isActive: false,
      lastActivityTime: DateTime.now(),
    );
  }

  factory SessionState.active({
    required SessionData sessionData,
    required AuthMethod authMethod,
    Map<String, dynamic>? metadata,
  }) {
    return SessionState(
      isActive: true,
      sessionData: sessionData,
      authMethod: authMethod,
      lastActivityTime: DateTime.now(),
      metadata: metadata,
    );
  }

  SessionState copyWith({
    bool? isActive,
    SessionData? sessionData,
    AuthMethod? authMethod,
    DateTime? lastActivityTime,
    bool? isInBackground,
    bool? isInSensitiveScreen,
    Map<String, dynamic>? metadata,
  }) {
    return SessionState(
      isActive: isActive ?? this.isActive,
      sessionData: sessionData ?? this.sessionData,
      authMethod: authMethod ?? this.authMethod,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      isInBackground: isInBackground ?? this.isInBackground,
      isInSensitiveScreen: isInSensitiveScreen ?? this.isInSensitiveScreen,
      metadata: metadata ?? this.metadata,
    );
  }

  SessionState updateActivity() {
    return copyWith(lastActivityTime: DateTime.now());
  }

  SessionState terminate() {
    return SessionState(
      isActive: false,
      sessionData: null,
      authMethod: null,
      lastActivityTime: lastActivityTime,
      isInBackground: false,
      isInSensitiveScreen: false,
      metadata: null,
    );
  }

  SessionState enterBackground() {
    return copyWith(isInBackground: true);
  }

  SessionState enterForeground() {
    return copyWith(isInBackground: false);
  }

  SessionState setSensitiveScreen(bool isSensitive) {
    return copyWith(isInSensitiveScreen: isSensitive);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'sessionData': sessionData?.toJson(),
      'authMethod': authMethod?.toJson(),
      'lastActivityTime': lastActivityTime.toIso8601String(),
      'isInBackground': isInBackground,
      'isInSensitiveScreen': isInSensitiveScreen,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory SessionState.fromJson(Map<String, dynamic> json) {
    return SessionState(
      isActive: json['isActive'] as bool? ?? false,
      sessionData: json['sessionData'] != null
          ? SessionData.fromJson(json['sessionData'] as Map<String, dynamic>)
          : null,
      authMethod: json['authMethod'] != null
          ? AuthMethod.fromJson(json['authMethod'] as String)
          : null,
      lastActivityTime: DateTime.parse(json['lastActivityTime'] as String),
      isInBackground: json['isInBackground'] as bool? ?? false,
      isInSensitiveScreen: json['isInSensitiveScreen'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionState &&
        other.isActive == isActive &&
        other.sessionData == sessionData &&
        other.authMethod == authMethod &&
        other.lastActivityTime == lastActivityTime &&
        other.isInBackground == isInBackground &&
        other.isInSensitiveScreen == isInSensitiveScreen;
  }

  @override
  int get hashCode {
    return Object.hash(
      isActive,
      sessionData,
      authMethod,
      lastActivityTime,
      isInBackground,
      isInSensitiveScreen,
    );
  }

  @override
  String toString() {
    return 'SessionState(isActive: $isActive, '
           'authMethod: $authMethod, '
           'lastActivityTime: $lastActivityTime, '
           'isInBackground: $isInBackground, '
           'isInSensitiveScreen: $isInSensitiveScreen)';
  }
}