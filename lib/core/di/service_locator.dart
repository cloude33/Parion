import 'package:get_it/get_it.dart';
import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../../services/data_service.dart';
import '../../services/statistics_service.dart';
import '../../services/auth/auth_orchestrator.dart';
import '../../services/auth/interfaces/auth_orchestrator_interface.dart';
import '../../services/auth/interfaces/session_manager_interface.dart';
import '../../services/auth/interfaces/biometric_auth_interface.dart';
import '../../services/auth/interfaces/social_login_interface.dart';
import '../../services/auth/interfaces/security_controller_interface.dart';
import '../../services/auth/interfaces/data_sync_interface.dart';
import '../../services/auth/session_manager.dart';
import '../../services/auth/biometric_auth_service.dart';
import '../../services/auth/social_login_service.dart';
import '../../services/auth/security_controller.dart';
import '../../services/auth/data_sync_service.dart';
import '../utils/app_logger.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Setup dependency injection
Future<void> setupDependencyInjection() async {
  // Core services
  if (!getIt.isRegistered<AppLogger>()) {
    getIt.registerLazySingleton<AppLogger>(() => AppLogger());
  }

  // Legacy auth services (keep for backward compatibility)
  if (!getIt.isRegistered<AuthService>()) {
    getIt.registerLazySingleton<AuthService>(() => AuthService());
  }

  // Modern auth services - register implementations
  if (!getIt.isRegistered<ISessionManager>()) {
    getIt.registerLazySingleton<ISessionManager>(() => SessionManager());
  }
  if (!getIt.isRegistered<IBiometricAuthService>()) {
    getIt.registerLazySingleton<IBiometricAuthService>(
      () => BiometricAuthService(),
    );
  }
  if (!getIt.isRegistered<ISocialLoginService>()) {
    getIt.registerLazySingleton<ISocialLoginService>(
      () => SocialLoginService(),
    );
  }
  if (!getIt.isRegistered<ISecurityController>()) {
    getIt.registerLazySingleton<ISecurityController>(
      () => SecurityController(),
    );
  }
  if (!getIt.isRegistered<DataSyncInterface>()) {
    getIt.registerLazySingleton<DataSyncInterface>(() => DataSyncService());
  }

  // Register auth orchestrator with dependencies
  if (!getIt.isRegistered<IAuthOrchestrator>()) {
    getIt.registerLazySingleton<IAuthOrchestrator>(
      () => AuthOrchestrator(
        sessionManager: getIt<ISessionManager>(),
        biometricService: getIt<IBiometricAuthService>(),
        socialLoginService: getIt<ISocialLoginService>(),
        securityController: getIt<ISecurityController>(),
        dataSyncService: getIt<DataSyncInterface>(),
      ),
    );
  }

  // Backup services
  if (!getIt.isRegistered<BackupService>()) {
    getIt.registerLazySingleton<BackupService>(() => BackupService());
  }

  // Data services
  if (!getIt.isRegistered<DataService>()) {
    getIt.registerLazySingleton<DataService>(() => DataService());
  }

  // Statistics services
  if (!getIt.isRegistered<StatisticsService>()) {
    getIt.registerLazySingleton<StatisticsService>(() => StatisticsService());
  }

  // Initialize services that need async initialization
  try {
    getIt<AppLogger>().init();
  } catch (e) {
    // Logger might already be initialized
  }

  try {
    await getIt<DataService>().init();
  } catch (e) {
    // Service might already be initialized
  }

  try {
    await getIt<AuthService>().init();
  } catch (e) {
    // Service might already be initialized
  }

  // Initialize modern auth services
  try {
    await getIt<ISessionManager>().initialize();
    await getIt<IBiometricAuthService>().initialize();
    await getIt<ISocialLoginService>().initialize();
    await getIt<ISecurityController>().initialize();
    await getIt<DataSyncInterface>().initialize();
    await getIt<IAuthOrchestrator>().initialize();
  } catch (e) {
    // Services might already be initialized or have platform dependencies
    print('Warning: Some auth services failed to initialize: $e');
  }

  getIt<AppLogger>().info('Dependency injection setup completed');
}

/// Reset all dependencies (for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}

/// Extension methods for easy access
extension GetItExtensions on GetIt {
  /// Get AuthService instance
  AuthService get authService => get<AuthService>();

  /// Get modern AuthOrchestrator instance
  IAuthOrchestrator get authOrchestrator => get<IAuthOrchestrator>();

  /// Get BackupService instance
  BackupService get backupService => get<BackupService>();

  /// Get DataService instance
  DataService get dataService => get<DataService>();

  /// Get StatisticsService instance
  StatisticsService get statisticsService => get<StatisticsService>();

  /// Get AppLogger instance
  AppLogger get logger => get<AppLogger>();

  /// Get DataSyncService instance
  DataSyncInterface get dataSyncService => get<DataSyncInterface>();
}
