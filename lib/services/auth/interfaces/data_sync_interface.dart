import 'dart:async';
import '../../../models/user.dart';

/// Interface for data synchronization service
abstract class DataSyncInterface {
  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream;

  /// Whether the device is currently online
  bool get isOnline;

  /// Whether sync is currently in progress
  bool get isSyncing;

  /// Last successful sync time
  DateTime? get lastSyncTime;

  /// Initialize the sync service
  Future<void> initialize();

  /// Sync user profile data between Firebase and local storage
  Future<SyncResult> syncUserProfile(User user);

  /// Sync all user data
  Future<SyncResult> syncAllUserData(String userId);

  /// Sync pending operations when coming back online
  Future<SyncResult> syncPendingOperations();

  /// Resolve sync conflicts between local and remote sources
  Future<SyncResult> resolveConflicts();

  /// Handle errors that occur during sync (e.g., network failures)
  Future<void> handleSyncError(Object error);

  /// Verify local vs remote data consistency
  Future<bool> verifyDataConsistency();

  /// Handle partial sync scenarios (some operations succeed, others fail)
  Future<SyncResult> handlePartialSync();

  /// Invalidate cached sync data
  Future<void> invalidateCache();

  /// Refresh cache after network becomes available
  Future<void> refreshCache();

  /// Dispose resources
  void dispose();
}

/// Represents the current sync status
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingOperationsCount;

  const SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    this.lastSyncTime,
    required this.pendingOperationsCount,
  });

  @override
  String toString() {
    return 'SyncStatus(isOnline: $isOnline, isSyncing: $isSyncing, '
           'lastSyncTime: $lastSyncTime, pendingOperationsCount: $pendingOperationsCount)';
  }
}

/// Result of a sync operation
class SyncResult {
  final bool isSuccess;
  final String? errorMessage;
  final int conflictsResolved;
  final bool wasQueued;

  const SyncResult._({
    required this.isSuccess,
    this.errorMessage,
    required this.conflictsResolved,
    required this.wasQueued,
  });

  factory SyncResult.success({int conflictsResolved = 0}) {
    return SyncResult._(
      isSuccess: true,
      conflictsResolved: conflictsResolved,
      wasQueued: false,
    );
  }

  factory SyncResult.error(String errorMessage) {
    return SyncResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      conflictsResolved: 0,
      wasQueued: false,
    );
  }

  factory SyncResult.queued() {
    return const SyncResult._(
      isSuccess: true,
      conflictsResolved: 0,
      wasQueued: true,
    );
  }

  @override
  String toString() {
    return 'SyncResult(isSuccess: $isSuccess, errorMessage: $errorMessage, '
           'conflictsResolved: $conflictsResolved, wasQueued: $wasQueued)';
  }
}

/// Represents a pending sync operation for offline scenarios
class PendingSyncOperation {
  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  const PendingSyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  PendingSyncOperation copyWith({
    String? id,
    SyncOperationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return PendingSyncOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SyncOperationType.userProfile,
      ),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'PendingSyncOperation(id: $id, type: $type, timestamp: $timestamp, retryCount: $retryCount)';
  }
}

/// Types of sync operations
enum SyncOperationType {
  userProfile,
  userData,
  preferences,
}
