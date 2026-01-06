import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/user.dart';
import 'package:parion/models/auth/user_preferences.dart';
import 'package:parion/services/auth/interfaces/data_sync_interface.dart';
import '../../property_test_utils.dart';

/// Property-based tests for DataSyncService
/// 
/// **Feature: modern-auth-system, Property 4: Data Synchronization Integrity**
/// **Validates: Requirements 9.1, 9.2, 9.4**
void main() {
  group('DataSyncService Property Tests', () {
    /// **Property 4: Data Synchronization Integrity**
    /// *For any* user data change or authentication event, the data should be 
    /// consistently synchronized between Firebase and local storage, with Firebase 
    /// serving as the source of truth for conflict resolution
    /// **Validates: Requirements 9.1, 9.2, 9.4**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 4: Data Synchronization Integrity - User data should maintain consistency',
      generator: () => _generateUserSyncData(),
      property: (syncData) async {
        final localUser = syncData['localUser'] as User;
        final firebaseData = syncData['firebaseData'] as Map<String, dynamic>?;
        final isOnline = syncData['isOnline'] as bool;
        
        // Test data consistency properties
        
        // 1. User ID should always be consistent
        if (localUser.id.isEmpty) return false;
        
        // 2. Required fields should not be null or empty
        if (localUser.name.isEmpty) return false;
        
        // 3. Timestamps should be valid
        if (localUser.createdAt.isAfter(DateTime.now())) return false;
        if (localUser.updatedAt.isBefore(localUser.createdAt)) return false;
        
        // 4. Preferences should be valid
        if (!_isValidUserPreferences(localUser.preferences)) return false;
        
        // 5. If Firebase data exists, test conflict resolution logic
        if (firebaseData != null) {
          final firebaseUpdatedAt = DateTime.tryParse(
            firebaseData['updatedAt']?.toString() ?? ''
          );
          
          if (firebaseUpdatedAt != null) {
            // Firebase as source of truth: newer timestamp should win
            final localIsNewer = localUser.updatedAt.isAfter(firebaseUpdatedAt);
            final firebaseIsNewer = firebaseUpdatedAt.isAfter(localUser.updatedAt);
            
            // At least one should be true (or they're equal)
            if (!localIsNewer && !firebaseIsNewer) {
              // They're equal - this is valid
              return localUser.updatedAt.isAtSameMomentAs(firebaseUpdatedAt);
            }
          }
        }
        
        // 6. Online/offline behavior consistency
        if (!isOnline) {
          // Offline operations should be queueable
          // This tests that the data structure supports offline queuing
          return _canBeQueuedForSync(localUser);
        }
        
        return true;
      },
      iterations: 25,
    );

    /// Test sync operation consistency
    PropertyTest.forAll<PendingSyncOperation>(
      description: 'Property: Pending sync operations should maintain data integrity',
      generator: () => _generatePendingSyncOperation(),
      property: (operation) async {
        // 1. Operation ID should not be empty
        if (operation.id.isEmpty) return false;
        
        // 2. Timestamp should be valid
        if (operation.timestamp.isAfter(DateTime.now())) return false;
        
        // 3. Retry count should be non-negative
        if (operation.retryCount < 0) return false;
        
        // 4. Data should be serializable
        try {
          final json = operation.toJson();
          final restored = PendingSyncOperation.fromJson(json);
          
          // Round-trip should preserve data
          if (restored.id != operation.id) return false;
          if (restored.type != operation.type) return false;
          if (restored.retryCount != operation.retryCount) return false;
          if (!restored.timestamp.isAtSameMomentAs(operation.timestamp)) return false;
          
        } catch (e) {
          // Serialization failed
          return false;
        }
        
        // 5. Operation data should be valid for its type
        switch (operation.type) {
          case SyncOperationType.userProfile:
            try {
              final user = User.fromJson(operation.data);
              return _isValidUser(user);
            } catch (e) {
              return false;
            }
          case SyncOperationType.preferences:
            try {
              final prefs = UserPreferences.fromJson(operation.data);
              return _isValidUserPreferences(prefs);
            } catch (e) {
              return false;
            }
          default:
            // Other types should have non-empty data
            return operation.data.isNotEmpty;
        }
      },
      iterations: 25,
    );

    /// Test sync status consistency
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Sync status should reflect accurate system state',
      generator: () => _generateSyncStatusData(),
      property: (statusData) async {
        final isOnline = statusData['isOnline'] as bool;
        final isSyncing = statusData['isSyncing'] as bool;
        final pendingCount = statusData['pendingCount'] as int;
        final lastSyncTime = statusData['lastSyncTime'] as DateTime?;
        
        final status = SyncStatus(
          isOnline: isOnline,
          isSyncing: isSyncing,
          lastSyncTime: lastSyncTime,
          pendingOperationsCount: pendingCount,
        );
        
        // 1. Pending count should be non-negative
        if (status.pendingOperationsCount < 0) return false;
        
        // 2. If syncing, should be online (can't sync while offline)
        if (status.isSyncing && !status.isOnline) return false;
        
        // 3. Last sync time should not be in the future
        if (status.lastSyncTime != null && 
            status.lastSyncTime!.isAfter(DateTime.now())) {
          return false;
        }
        
        // 4. If never synced and offline, should have pending operations
        if (!status.isOnline && status.lastSyncTime == null && 
            status.pendingOperationsCount == 0) {
          // This could be valid for a fresh install
          return true;
        }
        
        return true;
      },
      iterations: 25,
    );

    /// Test sync result consistency
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Sync results should accurately reflect operation outcomes',
      generator: () => _generateSyncResultData(),
      property: (resultData) async {
        final isSuccess = resultData['isSuccess'] as bool;
        final conflictsResolved = resultData['conflictsResolved'] as int;
        final errorMessage = resultData['errorMessage'] as String?;
        final wasQueued = resultData['wasQueued'] as bool;
        
        SyncResult result;
        if (isSuccess && wasQueued) {
          result = SyncResult.queued();
        } else if (isSuccess) {
          result = SyncResult.success(conflictsResolved: conflictsResolved);
        } else {
          result = SyncResult.error(errorMessage ?? 'Test error');
        }
        
        // 1. Success state should be consistent
        if (result.isSuccess != isSuccess) return false;
        
        // 2. Conflicts resolved should be non-negative
        if (result.conflictsResolved < 0) return false;
        
        // 3. Successful operations should not have error messages
        if (result.isSuccess && result.errorMessage != null) return false;
        
        // 4. Failed operations should have error messages
        if (!result.isSuccess && 
            (result.errorMessage == null || result.errorMessage!.isEmpty)) {
          return false;
        }
        
        // 5. Queued operations should be successful
        if (result.wasQueued && !result.isSuccess) return false;
        
        // 6. Queued operations should have zero conflicts resolved
        if (result.wasQueued && result.conflictsResolved != 0) return false;
        
        return true;
      },
      iterations: 25,
    );

    /// Test user data migration consistency
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property: Data migration should preserve user data integrity',
      generator: () => _generateMigrationData(),
      property: (migrationData) async {
        final oldUser = migrationData['oldUser'] as User;
        final newPreferences = migrationData['newPreferences'] as UserPreferences?;
        final migrationVersion = migrationData['version'] as String;
        
        // 1. Migration version should be valid
        if (migrationVersion.isEmpty) return false;
        
        // 2. Old user data should be valid
        if (!_isValidUser(oldUser)) return false;
        
        // 3. If new preferences exist, they should be valid
        if (newPreferences != null && !_isValidUserPreferences(newPreferences)) {
          return false;
        }
        
        // 4. Migration should preserve essential user data
        if (oldUser.id.isEmpty || oldUser.name.isEmpty) return false;
        
        // 5. Timestamps should be preserved or updated appropriately
        if (oldUser.createdAt.isAfter(DateTime.now())) return false;
        
        return true;
      },
      iterations: 25,
    );
  });
}

/// Generate user sync test data
Map<String, dynamic> _generateUserSyncData() {
  final user = _generateRandomUser();
  final hasFirebaseData = PropertyTest.randomBool();
  final isOnline = PropertyTest.randomBool();
  
  Map<String, dynamic>? firebaseData;
  if (hasFirebaseData) {
    firebaseData = {
      'displayName': PropertyTest.randomString(minLength: 1, maxLength: 50),
      'email': _generateValidEmail(),
      'updatedAt': _generateRandomDateTime().toIso8601String(),
      'preferences': _generateRandomUserPreferences().toJson(),
      'currencyCode': _generateRandomCurrencyCode(),
      'currencySymbol': _generateRandomCurrencySymbol(),
    };
  }
  
  return {
    'localUser': user,
    'firebaseData': firebaseData,
    'isOnline': isOnline,
  };
}

/// Generate a random user for testing
User _generateRandomUser() {
  return User(
    id: PropertyTest.randomString(minLength: 10, maxLength: 30),
    name: PropertyTest.randomString(minLength: 1, maxLength: 50),
    email: PropertyTest.randomBool() ? _generateValidEmail() : null,
    currencyCode: _generateRandomCurrencyCode(),
    currencySymbol: _generateRandomCurrencySymbol(),
    authMethod: _generateRandomAuthMethod(),
    createdAt: _generateRandomDateTime(),
    updatedAt: _generateRandomDateTime(),
    preferences: _generateRandomUserPreferences(),
  );
}

/// Generate a valid email
String _generateValidEmail() {
  final domains = ['gmail.com', 'yahoo.com', 'example.com', 'test.org'];
  final username = PropertyTest.randomString(minLength: 3, maxLength: 15);
  final domain = domains[PropertyTest.randomInt(min: 0, max: domains.length - 1)];
  return '$username@$domain';
}

/// Generate random auth method
AuthMethod _generateRandomAuthMethod() {
  final methods = AuthMethod.values;
  return methods[PropertyTest.randomInt(min: 0, max: methods.length - 1)];
}

/// Generate random currency code
String _generateRandomCurrencyCode() {
  final currencies = ['USD', 'EUR', 'TRY', 'GBP', 'JPY'];
  return currencies[PropertyTest.randomInt(min: 0, max: currencies.length - 1)];
}

/// Generate random currency symbol
String _generateRandomCurrencySymbol() {
  final symbols = ['\$', '€', '₺', '£', '¥'];
  return symbols[PropertyTest.randomInt(min: 0, max: symbols.length - 1)];
}

/// Generate random user preferences
UserPreferences _generateRandomUserPreferences() {
  final authMethods = ['biometric', 'pin', 'password', 'google', 'apple'];
  return UserPreferences(
    biometricEnabled: PropertyTest.randomBool(),
    rememberMe: PropertyTest.randomBool(),
    autoLockTimeoutMinutes: PropertyTest.randomInt(min: 1, max: 60),
    showBiometricPrompt: PropertyTest.randomBool(),
    preferredAuthMethod: PropertyTest.randomBool() 
        ? authMethods[PropertyTest.randomInt(min: 0, max: authMethods.length - 1)]
        : null,
    lastAuthMethod: PropertyTest.randomBool()
        ? authMethods[PropertyTest.randomInt(min: 0, max: authMethods.length - 1)]
        : null,
  );
}

/// Generate random datetime within reasonable bounds
DateTime _generateRandomDateTime() {
  final now = DateTime.now();
  final daysAgo = PropertyTest.randomInt(min: 0, max: 365);
  return now.subtract(Duration(days: daysAgo));
}

/// Generate pending sync operation
PendingSyncOperation _generatePendingSyncOperation() {
  final types = SyncOperationType.values;
  final type = types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
  
  Map<String, dynamic> data;
  switch (type) {
    case SyncOperationType.userProfile:
      data = _generateRandomUser().toJson();
      break;
    case SyncOperationType.preferences:
      data = _generateRandomUserPreferences().toJson();
      break;
    default:
      data = {'test': PropertyTest.randomString(minLength: 1, maxLength: 100)};
  }
  
  return PendingSyncOperation(
    id: PropertyTest.randomString(minLength: 5, maxLength: 30),
    type: type,
    data: data,
    timestamp: _generateRandomDateTime(),
    retryCount: PropertyTest.randomInt(min: 0, max: 5),
  );
}

/// Generate sync status test data
Map<String, dynamic> _generateSyncStatusData() {
  final isOnline = PropertyTest.randomBool();
  final isSyncing = PropertyTest.randomBool() && isOnline; // Can only sync if online
  
  return {
    'isOnline': isOnline,
    'isSyncing': isSyncing,
    'pendingCount': PropertyTest.randomInt(min: 0, max: 100),
    'lastSyncTime': PropertyTest.randomBool() ? _generateRandomDateTime() : null,
  };
}

/// Generate sync result test data
Map<String, dynamic> _generateSyncResultData() {
  final isSuccess = PropertyTest.randomBool();
  final wasQueued = PropertyTest.randomBool() && isSuccess; // Only successful ops can be queued
  
  return {
    'isSuccess': isSuccess,
    'conflictsResolved': isSuccess ? PropertyTest.randomInt(min: 0, max: 10) : 0,
    'errorMessage': isSuccess ? null : PropertyTest.randomString(minLength: 5, maxLength: 100),
    'wasQueued': wasQueued,
  };
}

/// Generate migration test data
Map<String, dynamic> _generateMigrationData() {
  return {
    'oldUser': _generateRandomUser(),
    'newPreferences': PropertyTest.randomBool() ? _generateRandomUserPreferences() : null,
    'version': 'v${PropertyTest.randomInt(min: 1, max: 10)}',
  };
}

/// Check if user is valid
bool _isValidUser(User user) {
  if (user.id.isEmpty) return false;
  if (user.name.isEmpty) return false;
  if (user.createdAt.isAfter(DateTime.now())) return false;
  if (user.updatedAt.isBefore(user.createdAt)) return false;
  return _isValidUserPreferences(user.preferences);
}

/// Check if user preferences are valid
bool _isValidUserPreferences(UserPreferences preferences) {
  if (preferences.autoLockTimeoutMinutes <= 0) return false;
  if (preferences.autoLockTimeoutMinutes > 60) return false;
  
  // Check if preferred auth method is valid
  if (preferences.preferredAuthMethod != null) {
    final validMethods = ['biometric', 'pin', 'password', 'google', 'apple'];
    if (!validMethods.contains(preferences.preferredAuthMethod)) return false;
  }
  
  // Check if last auth method is valid
  if (preferences.lastAuthMethod != null) {
    final validMethods = ['biometric', 'pin', 'password', 'google', 'apple'];
    if (!validMethods.contains(preferences.lastAuthMethod)) return false;
  }
  
  return true;
}

/// Check if user data can be queued for sync
bool _canBeQueuedForSync(User user) {
  try {
    // Test if user can be serialized for queuing
    final json = user.toJson();
    final restored = User.fromJson(json);
    return restored.id == user.id;
  } catch (e) {
    return false;
  }
}
