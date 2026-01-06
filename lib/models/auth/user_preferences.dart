/// User authentication preferences model
/// 
/// This model stores user preferences for authentication methods,
/// including remember me settings and preferred authentication methods.
class UserPreferences {
  /// Remember me setting for authentication
  final bool rememberMe;
  
  /// Preferred authentication method
  final String? preferredAuthMethod;
  
  /// Biometric authentication enabled
  final bool biometricEnabled;
  
  /// Auto-lock timeout in minutes
  final int autoLockTimeoutMinutes;
  
  /// Show biometric prompt on app start
  final bool showBiometricPrompt;
  
  /// Last authentication method used
  final String? lastAuthMethod;
  
  /// Authentication preferences metadata
  final Map<String, dynamic> metadata;
  
  /// Created timestamp
  final DateTime createdAt;
  
  /// Last updated timestamp
  final DateTime updatedAt;

  UserPreferences({
    this.rememberMe = false,
    this.preferredAuthMethod,
    this.biometricEnabled = false,
    this.autoLockTimeoutMinutes = 5,
    this.showBiometricPrompt = true,
    this.lastAuthMethod,
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Create default preferences
  factory UserPreferences.defaultPreferences() {
    final now = DateTime.now();
    return UserPreferences(
      rememberMe: false,
      biometricEnabled: false,
      autoLockTimeoutMinutes: 5,
      showBiometricPrompt: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create preferences with remember me enabled
  factory UserPreferences.withRememberMe({
    String? preferredAuthMethod,
    bool biometricEnabled = false,
  }) {
    final now = DateTime.now();
    return UserPreferences(
      rememberMe: true,
      preferredAuthMethod: preferredAuthMethod,
      biometricEnabled: biometricEnabled,
      showBiometricPrompt: biometricEnabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'rememberMe': rememberMe,
      'preferredAuthMethod': preferredAuthMethod,
      'biometricEnabled': biometricEnabled,
      'autoLockTimeoutMinutes': autoLockTimeoutMinutes,
      'showBiometricPrompt': showBiometricPrompt,
      'lastAuthMethod': lastAuthMethod,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// JSON deserialization
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      rememberMe: json['rememberMe'] as bool? ?? false,
      preferredAuthMethod: json['preferredAuthMethod'] as String?,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      autoLockTimeoutMinutes: json['autoLockTimeoutMinutes'] as int? ?? 5,
      showBiometricPrompt: json['showBiometricPrompt'] as bool? ?? true,
      lastAuthMethod: json['lastAuthMethod'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Create a copy with updated values
  UserPreferences copyWith({
    bool? rememberMe,
    String? preferredAuthMethod,
    bool? biometricEnabled,
    int? autoLockTimeoutMinutes,
    bool? showBiometricPrompt,
    String? lastAuthMethod,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      rememberMe: rememberMe ?? this.rememberMe,
      preferredAuthMethod: preferredAuthMethod ?? this.preferredAuthMethod,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeoutMinutes: autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      showBiometricPrompt: showBiometricPrompt ?? this.showBiometricPrompt,
      lastAuthMethod: lastAuthMethod ?? this.lastAuthMethod,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Update preferred authentication method
  UserPreferences updatePreferredAuthMethod(String method) {
    return copyWith(
      preferredAuthMethod: method,
      lastAuthMethod: method,
      updatedAt: DateTime.now(),
    );
  }

  /// Enable/disable remember me
  UserPreferences setRememberMe(bool enabled) {
    return copyWith(
      rememberMe: enabled,
      updatedAt: DateTime.now(),
    );
  }

  /// Enable/disable biometric authentication
  UserPreferences setBiometricEnabled(bool enabled) {
    return copyWith(
      biometricEnabled: enabled,
      showBiometricPrompt: enabled,
      preferredAuthMethod: enabled ? 'biometric' : preferredAuthMethod,
      updatedAt: DateTime.now(),
    );
  }

  /// Update auto-lock timeout
  UserPreferences setAutoLockTimeout(int minutes) {
    return copyWith(
      autoLockTimeoutMinutes: minutes.clamp(1, 60), // 1-60 minutes
      updatedAt: DateTime.now(),
    );
  }

  /// Record authentication method usage
  UserPreferences recordAuthMethodUsage(String method) {
    return copyWith(
      lastAuthMethod: method,
      updatedAt: DateTime.now(),
    );
  }

  /// Validate preferences
  String? validate() {
    if (autoLockTimeoutMinutes < 1 || autoLockTimeoutMinutes > 60) {
      return 'Auto-lock timeout must be between 1 and 60 minutes';
    }
    
    if (preferredAuthMethod != null && 
        !['biometric', 'pin', 'password', 'google', 'apple'].contains(preferredAuthMethod)) {
      return 'Invalid preferred authentication method';
    }
    
    return null;
  }

  /// Check if preferences are valid
  bool get isValid => validate() == null;

  /// Get auto-lock timeout as Duration
  Duration get autoLockTimeout => Duration(minutes: autoLockTimeoutMinutes);

  /// Check if user prefers biometric authentication
  bool get prefersBiometric => preferredAuthMethod == 'biometric' && biometricEnabled;

  /// Check if user has any authentication preferences set
  bool get hasPreferences => 
      preferredAuthMethod != null || 
      biometricEnabled || 
      rememberMe || 
      autoLockTimeoutMinutes != 5;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences &&
        other.rememberMe == rememberMe &&
        other.preferredAuthMethod == preferredAuthMethod &&
        other.biometricEnabled == biometricEnabled &&
        other.autoLockTimeoutMinutes == autoLockTimeoutMinutes &&
        other.showBiometricPrompt == showBiometricPrompt &&
        other.lastAuthMethod == lastAuthMethod;
  }

  @override
  int get hashCode {
    return Object.hash(
      rememberMe,
      preferredAuthMethod,
      biometricEnabled,
      autoLockTimeoutMinutes,
      showBiometricPrompt,
      lastAuthMethod,
    );
  }

  @override
  String toString() {
    return 'UserPreferences('
           'rememberMe: $rememberMe, '
           'preferredAuthMethod: $preferredAuthMethod, '
           'biometricEnabled: $biometricEnabled, '
           'autoLockTimeout: ${autoLockTimeoutMinutes}min)';
  }
}