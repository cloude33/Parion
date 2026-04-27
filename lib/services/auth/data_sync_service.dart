import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';
import '../../models/auth/user_preferences.dart';
import '../firestore_service.dart';
import '../data_service.dart';
import 'interfaces/data_sync_interface.dart';

class DataSyncService implements DataSyncInterface {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final DataService _dataService = DataService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final List<PendingSyncOperation> _pendingOperations = [];

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  @override
  bool get isOnline => _isOnline;

  @override
  bool get isSyncing => _isSyncing;

  @override
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize the sync service
  @override
  Future<void> initialize() async {
    try {
      debugPrint('🔄 DataSyncService: Initializing...');

      // Check initial connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _isOnline = !connectivityResult.contains(ConnectivityResult.none);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint('❌ DataSyncService: Connectivity error: $error');
        },
      );

      // Load pending operations from storage
      await _loadPendingOperations();

      // Perform initial sync if online
      if (_isOnline) {
        unawaited(_performInitialSync());
      }

      debugPrint('✅ DataSyncService: Initialized successfully');
      _emitSyncStatus();
    } catch (e) {
      debugPrint('❌ DataSyncService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    debugPrint('🌐 DataSyncService: Connectivity changed - Online: $_isOnline');

    if (!wasOnline && _isOnline) {
      // Came back online - sync pending operations
      unawaited(syncPendingOperations());
    }

    _emitSyncStatus();
  }

  /// Sync user profile data between Firebase and local storage
  @override
  Future<SyncResult> syncUserProfile(User user) async {
    try {
      debugPrint('👤 DataSyncService: Syncing user profile for ${user.id}');

      if (!_isOnline) {
        // Queue for later sync
        await _queueOperation(
          PendingSyncOperation(
            id: 'user_profile_${user.id}',
            type: SyncOperationType.userProfile,
            data: user.toJson(),
            timestamp: DateTime.now(),
          ),
        );
        return SyncResult.queued();
      }

      _isSyncing = true;
      _emitSyncStatus();

      // Get Firebase user profile
      final firebaseDoc = await _firestoreService.getUserProfile(user.id);

      if (firebaseDoc == null || !firebaseDoc.exists) {
        // Create new profile in Firebase
        await _firestoreService.createUserProfile(
          uid: user.id,
          email: user.email ?? '',
          displayName: user.name,
          additionalData: {
            'preferences': user.preferences.toJson(),
            'authMethod': user.authMethod.toString(),
            'currencyCode': user.currencyCode,
            'currencySymbol': user.currencySymbol,
            'lastActive': user.lastActive?.toIso8601String(),
          },
        );

        // Update local storage with server timestamp
        await _dataService.updateUser(user.copyWith(updatedAt: DateTime.now()));

        debugPrint('✅ DataSyncService: Created new user profile in Firebase');
        return SyncResult.success(conflictsResolved: 0);
      }

      // Handle conflict resolution
      final firebaseData = firebaseDoc.data() as Map<String, dynamic>;
      final conflictResult = await _resolveUserProfileConflict(
        user,
        firebaseData,
      );

      _lastSyncTime = DateTime.now();
      await _saveLastSyncTime();

      debugPrint('✅ DataSyncService: User profile sync completed');
      return conflictResult;
    } catch (e) {
      debugPrint('❌ DataSyncService: User profile sync failed: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
      _emitSyncStatus();
    }
  }

  /// Resolve conflicts between local and Firebase user data
  Future<SyncResult> _resolveUserProfileConflict(
    User localUser,
    Map<String, dynamic> firebaseData,
  ) async {
    try {
      // Firebase is source of truth for conflict resolution (Requirement 9.4)
      final firebaseUpdatedAt =
          DateTime.tryParse(firebaseData['updatedAt']?.toString() ?? '') ??
          DateTime.now();
      final localUpdatedAt = localUser.updatedAt;

      int conflictsResolved = 0;

      if (firebaseUpdatedAt.isAfter(localUpdatedAt)) {
        // Firebase data is newer - update local
        debugPrint(
          '🔄 DataSyncService: Firebase data is newer, updating local',
        );

        final updatedUser = localUser.copyWith(
          name: firebaseData['displayName']?.toString() ?? localUser.name,
          email: firebaseData['email']?.toString() ?? localUser.email,
          currencyCode:
              firebaseData['currencyCode']?.toString() ??
              localUser.currencyCode,
          currencySymbol:
              firebaseData['currencySymbol']?.toString() ??
              localUser.currencySymbol,
          lastActive: firebaseData['lastActive'] != null
              ? DateTime.tryParse(firebaseData['lastActive'].toString())
              : localUser.lastActive,
          preferences: firebaseData['preferences'] != null
              ? UserPreferences.fromJson(
                  firebaseData['preferences'] as Map<String, dynamic>,
                )
              : localUser.preferences,
          updatedAt: firebaseUpdatedAt,
        );

        await _dataService.updateUser(updatedUser);
        conflictsResolved++;
      } else if (localUpdatedAt.isAfter(firebaseUpdatedAt)) {
        // Local data is newer - update Firebase
        debugPrint(
          '🔄 DataSyncService: Local data is newer, updating Firebase',
        );

        await _firestoreService.createUserProfile(
          uid: localUser.id,
          email: localUser.email ?? '',
          displayName: localUser.name,
          additionalData: {
            'preferences': localUser.preferences.toJson(),
            'authMethod': localUser.authMethod.toString(),
            'currencyCode': localUser.currencyCode,
            'currencySymbol': localUser.currencySymbol,
            'lastActive': localUser.lastActive?.toIso8601String(),
            'updatedAt': localUser.updatedAt.toIso8601String(),
          },
        );
        conflictsResolved++;
      }

      return SyncResult.success(conflictsResolved: conflictsResolved);
    } catch (e) {
      debugPrint('❌ DataSyncService: Conflict resolution failed: $e');
      return SyncResult.error('Conflict resolution failed: $e');
    }
  }

  /// Sync all user data
  @override
  Future<SyncResult> syncAllUserData(String userId) async {
    try {
      debugPrint('🔄 DataSyncService: Starting full sync for user $userId');

      if (!_isOnline) {
        return SyncResult.error('No internet connection');
      }

      _isSyncing = true;
      _emitSyncStatus();

      int totalConflicts = 0;

      // Sync user profile
      final user = await _dataService.getCurrentUser();
      if (user != null) {
        final profileResult = await syncUserProfile(user);
        if (profileResult.isSuccess) {
          totalConflicts += profileResult.conflictsResolved;
        }
      }

      // Handle data migration for existing users (Requirement 9.5)
      await _handleDataMigration(userId);

      _lastSyncTime = DateTime.now();
      await _saveLastSyncTime();

      debugPrint(
        '✅ DataSyncService: Full sync completed with $totalConflicts conflicts resolved',
      );
      return SyncResult.success(conflictsResolved: totalConflicts);
    } catch (e) {
      debugPrint('❌ DataSyncService: Full sync failed: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
      _emitSyncStatus();
    }
  }

  /// Handle data migration for existing users
  Future<void> _handleDataMigration(String userId) async {
    try {
      debugPrint(
        '🔄 DataSyncService: Checking data migration for user $userId',
      );

      final prefs = await SharedPreferences.getInstance();
      final migrationKey = 'data_migration_v1_$userId';
      final isMigrated = prefs.getBool(migrationKey) ?? false;

      if (!isMigrated) {
        debugPrint(
          '🔄 DataSyncService: Performing data migration for user $userId',
        );

        // Migrate user preferences if they don't exist
        final user = await _dataService.getCurrentUser();
        if (user != null &&
            user.preferences == UserPreferences.defaultPreferences()) {
          // Check if there are any stored preferences in old format
          final oldPrefsJson = prefs.getString('user_preferences_$userId');
          if (oldPrefsJson != null) {
            try {
              final oldPrefs =
                  json.decode(oldPrefsJson) as Map<String, dynamic>;
              final migratedPreferences = UserPreferences.fromJson(oldPrefs);

              final updatedUser = user.copyWith(
                preferences: migratedPreferences,
                updatedAt: DateTime.now(),
              );

              await _dataService.updateUser(updatedUser);
              debugPrint('✅ DataSyncService: Migrated user preferences');
            } catch (e) {
              debugPrint(
                '⚠️ DataSyncService: Failed to migrate preferences: $e',
              );
            }
          }
        }

        // Mark migration as completed
        await prefs.setBool(migrationKey, true);
        debugPrint(
          '✅ DataSyncService: Data migration completed for user $userId',
        );
      }
    } catch (e) {
      debugPrint('❌ DataSyncService: Data migration failed: $e');
    }
  }

  /// Queue operation for offline sync
  Future<void> _queueOperation(PendingSyncOperation operation) async {
    _pendingOperations.add(operation);
    await _savePendingOperations();
    debugPrint('📝 DataSyncService: Queued operation ${operation.id}');
    _emitSyncStatus();
  }

  /// Sync pending operations when coming back online
  @override
  Future<SyncResult> syncPendingOperations() async {
    if (!_isOnline || _pendingOperations.isEmpty) {
      return SyncResult.success(conflictsResolved: 0);
    }

    try {
      debugPrint(
        '🔄 DataSyncService: Syncing ${_pendingOperations.length} pending operations',
      );

      _isSyncing = true;
      _emitSyncStatus();

      int successCount = 0;
      int conflictsResolved = 0;
      final failedOperations = <PendingSyncOperation>[];

      for (final operation in List.from(_pendingOperations)) {
        try {
          final result = await _executePendingOperation(operation);
          if (result.isSuccess) {
            successCount++;
            conflictsResolved += result.conflictsResolved;
            _pendingOperations.remove(operation);
          } else {
            failedOperations.add(operation);
          }
        } catch (e) {
          debugPrint(
            '❌ DataSyncService: Failed to execute operation ${operation.id}: $e',
          );
          failedOperations.add(operation);
        }
      }

      await _savePendingOperations();

      debugPrint(
        '✅ DataSyncService: Synced $successCount operations, ${failedOperations.length} failed',
      );
      return SyncResult.success(conflictsResolved: conflictsResolved);
    } catch (e) {
      debugPrint('❌ DataSyncService: Pending operations sync failed: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
      _emitSyncStatus();
    }
  }

  /// Resolve sync conflicts between local and remote sources
  @override
  Future<SyncResult> resolveConflicts() async {
    try {
      final user = await _dataService.getCurrentUser();
      if (user == null) {
        return SyncResult.error('No current user');
      }
      if (!_isOnline) {
        return SyncResult.error('No internet connection');
      }

      final firebaseDoc = await _firestoreService.getUserProfile(user.id);
      if (firebaseDoc == null || !firebaseDoc.exists) {
        return SyncResult.success(conflictsResolved: 0);
      }
      final firebaseData = firebaseDoc.data() as Map<String, dynamic>;
      return await _resolveUserProfileConflict(user, firebaseData);
    } catch (e) {
      debugPrint('❌ DataSyncService: resolveConflicts failed: $e');
      return SyncResult.error(e.toString());
    }
  }

  /// Handle errors that occur during sync (e.g., network failures)
  @override
  Future<void> handleSyncError(Object error) async {
    try {
      debugPrint('⚠️ DataSyncService: Handling sync error: $error');
      _isSyncing = false;
      _emitSyncStatus();
      // Basic backoff: persist pending operations for retry
      await _savePendingOperations();
    } catch (e) {
      debugPrint('❌ DataSyncService: handleSyncError failed: $e');
    }
  }

  /// Verify local vs remote data consistency
  @override
  Future<bool> verifyDataConsistency() async {
    try {
      final user = await _dataService.getCurrentUser();
      if (user == null) return true;
      if (!_isOnline) {
        // Cannot verify without network; assume consistent
        return true;
      }
      final firebaseDoc = await _firestoreService.getUserProfile(user.id);
      if (firebaseDoc == null || !firebaseDoc.exists) return true;
      final data = firebaseDoc.data() as Map<String, dynamic>;

      final nameMatch = (data['displayName']?.toString() ?? '') == user.name;
      final emailMatch = (data['email']?.toString() ?? '') == (user.email ?? '');
      final currencyMatch = (data['currencyCode']?.toString() ?? '') == user.currencyCode;

      return nameMatch && emailMatch && currencyMatch;
    } catch (e) {
      debugPrint('❌ DataSyncService: verifyDataConsistency failed: $e');
      return false;
    }
  }

  /// Handle partial sync scenarios (some operations succeed, others fail)
  @override
  Future<SyncResult> handlePartialSync() async {
    try {
      // Attempt to sync pending operations and report conflicts
      final result = await syncPendingOperations();
      return result;
    } catch (e) {
      debugPrint('❌ DataSyncService: handlePartialSync failed: $e');
      return SyncResult.error(e.toString());
    }
  }

  /// Invalidate cached sync data
  @override
  Future<void> invalidateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_sync_operations');
      await prefs.remove('last_sync_time');
      _pendingOperations.clear();
      _lastSyncTime = null;
      _emitSyncStatus();
      debugPrint('🧹 DataSyncService: Cache invalidated');
    } catch (e) {
      debugPrint('❌ DataSyncService: invalidateCache failed: $e');
    }
  }

  /// Refresh cache after network becomes available
  @override
  Future<void> refreshCache() async {
    try {
      await _loadPendingOperations();
      if (_isOnline) {
        final user = await _dataService.getCurrentUser();
        if (user != null) {
          await syncAllUserData(user.id);
        }
      }
      debugPrint('🔄 DataSyncService: Cache refreshed');
    } catch (e) {
      debugPrint('❌ DataSyncService: refreshCache failed: $e');
    }
  }

  /// Execute a pending sync operation
  Future<SyncResult> _executePendingOperation(
    PendingSyncOperation operation,
  ) async {
    switch (operation.type) {
      case SyncOperationType.userProfile:
        final user = User.fromJson(operation.data);
        return await syncUserProfile(user);
      default:
        return SyncResult.error('Unknown operation type: ${operation.type}');
    }
  }

  /// Perform initial sync when service starts
  Future<void> _performInitialSync() async {
    try {
      final user = await _dataService.getCurrentUser();
      if (user != null) {
        await syncAllUserData(user.id);
      }
    } catch (e) {
      debugPrint('❌ DataSyncService: Initial sync failed: $e');
    }
  }

  /// Load pending operations from storage
  Future<void> _loadPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = prefs.getString('pending_sync_operations') ?? '[]';
      final operationsList = json.decode(operationsJson) as List;

      _pendingOperations.clear();
      _pendingOperations.addAll(
        operationsList.map(
          (op) => PendingSyncOperation.fromJson(op as Map<String, dynamic>),
        ),
      );

      debugPrint(
        '📝 DataSyncService: Loaded ${_pendingOperations.length} pending operations',
      );
    } catch (e) {
      debugPrint('❌ DataSyncService: Failed to load pending operations: $e');
    }
  }

  /// Save pending operations to storage
  Future<void> _savePendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = json.encode(
        _pendingOperations.map((op) => op.toJson()).toList(),
      );
      await prefs.setString('pending_sync_operations', operationsJson);
    } catch (e) {
      debugPrint('❌ DataSyncService: Failed to save pending operations: $e');
    }
  }

  /// Save last sync time
  Future<void> _saveLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_sync_time',
        _lastSyncTime?.toIso8601String() ?? '',
      );
    } catch (e) {
      debugPrint('❌ DataSyncService: Failed to save last sync time: $e');
    }
  }

  /// Emit current sync status
  void _emitSyncStatus() {
    _syncStatusController.add(
      SyncStatus(
        isOnline: _isOnline,
        isSyncing: _isSyncing,
        lastSyncTime: _lastSyncTime,
        pendingOperationsCount: _pendingOperations.length,
      ),
    );
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}
