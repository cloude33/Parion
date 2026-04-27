import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart'
    show SharePlus, ShareResultStatus, ShareParams, XFile;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/backup_metadata.dart';
import 'data_service.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../repositories/kmh_repository.dart';
import 'bill_template_service.dart';
import 'bill_payment_service.dart';
import 'credit_card_service.dart';
import 'google_drive_service.dart';

enum CloudBackupStatus { idle, uploading, downloading, syncing, error }

class BackupService {
  final DataService _dataService = DataService();
  final BillTemplateService _billTemplateService = BillTemplateService();
  final BillPaymentService _billPaymentService = BillPaymentService();
  final GoogleDriveService _driveService = GoogleDriveService();

  ValueNotifier<CloudBackupStatus> cloudBackupStatus = ValueNotifier(
    CloudBackupStatus.idle,
  );
  ValueNotifier<String?> lastCloudBackupDate = ValueNotifier(null);
  ValueNotifier<bool> autoCloudBackupEnabled = ValueNotifier(false);
  ValueNotifier<String?> lastError = ValueNotifier(null);

  Future<String> _getPlatformInfo() async {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  Future<String> _getDeviceModel() async {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    return 'unknown';
  }

  Future<Map<String, dynamic>> _gatherBackupData() async {
    final transactions = await _dataService.getTransactions();
    final wallets = await _dataService.getWallets();
    final recurringRepo = RecurringTransactionRepository();
    await recurringRepo.init();
    final recurringTransactions = recurringRepo.getAll();

    final categories = await _dataService.getCategories();
    final kmhRepo = KmhRepository();
    final kmhTransactions = await kmhRepo.findAll();

    // Bill templates and payments
    final billTemplates = await _billTemplateService.getTemplates();
    final billPayments = await _billPaymentService.getPayments();

    // Credit card data
    final creditCardService = CreditCardService();
    final creditCards = await creditCardService.getAllCards();
    final creditCardTransactions = <Map<String, dynamic>>[];
    final creditCardPayments = <Map<String, dynamic>>[];

    for (var card in creditCards) {
      final transactions = await creditCardService.getCardTransactions(card.id);
      creditCardTransactions.addAll(
        transactions.map((t) => t.toJson()).toList(),
      );

      final payments = await creditCardService.getCardPayments(card.id);
      creditCardPayments.addAll(payments.map((p) => p.toJson()).toList());
    }

    final goals = await _dataService.getGoals();

    final loans = await _dataService.getLoans();

    // Kullanıcı verileri
    final users = await _dataService.getAllUsers();
    final currentUser = await _dataService.getCurrentUser();

    final userImages = <String, String>{};
    if (!kIsWeb) {
      for (var user in users) {
        if (user.avatar != null &&
            user.avatar!.isNotEmpty &&
            !user.avatar!.startsWith('http') &&
            !user.avatar!.startsWith('assets')) {
          try {
            final file = File(user.avatar!);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final base64Img = base64Encode(bytes);
              userImages[user.id] = base64Img;
            }
          } catch (e) {
            debugPrint('Avatar yedekleme hatası (${user.id}): $e');
          }
        }
      }
    }

    final platform = await _getPlatformInfo();
    final deviceModel = await _getDeviceModel();

    final metadata = BackupMetadata(
      version: '2.0',
      createdAt: DateTime.now(),
      transactionCount: transactions.length,
      walletCount: wallets.length,
      platform: platform,
      deviceModel: deviceModel,
    );

    return {
      'metadata': metadata.toJson(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'wallets': wallets.map((w) => w.toJson()).toList(),
      'recurringTransactions': recurringTransactions
          .map((rt) => rt.toJson())
          .toList(),
      'categories': categories,
      'kmhTransactions': kmhTransactions.map((kt) => kt.toJson()).toList(),
      'billTemplates': billTemplates.map((bt) => bt.toJson()).toList(),
      'billPayments': billPayments.map((bp) => bp.toJson()).toList(),
      'creditCards': creditCards.map((cc) => cc.toJson()).toList(),
      'creditCardTransactions': creditCardTransactions,
      'creditCardPayments': creditCardPayments,
      'goals': goals.map((g) => g.toJson()).toList(),
      'loans': loans.map((l) => l.toJson()).toList(),
      'users': users.map((u) => u.toJson()).toList(),
      'currentUser': currentUser?.toJson(),
      'userImages': userImages,
    };
  }

  Future<List<int>> createBackupRaw() async {
    final backupData = await _gatherBackupData();
    final jsonString = jsonEncode(backupData);
    final jsonBytes = utf8.encode(jsonString);
    final compressed = GZipEncoder().encode(jsonBytes);
    return compressed!;
  }

  Future<File> createBackup() async {
    if (kIsWeb) {
      throw UnsupportedError('createBackup (File) is not supported on Web');
    }

    final compressed = await createBackupRaw();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'money_backup_$timestamp.mbk';

    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(directory.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final filePath = path.join(backupDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(compressed);

    return file;
  }

  Future<void> restoreFromBackup(File backupFile) async {
    try {
      final compressed = await backupFile.readAsBytes();
      final decompressed = GZipDecoder().decodeBytes(compressed);
      final jsonString = utf8.decode(decompressed);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!backupData.containsKey('metadata') ||
          !backupData.containsKey('transactions')) {
        throw Exception('Invalid backup file format');
      }

      // Platform kontrolü ve uyarı
      final metadata = BackupMetadata.fromJson(backupData['metadata']);
      final currentPlatform = await _getPlatformInfo();

      print('Restoring backup from ${metadata.platform} to $currentPlatform');
      print('Device: ${metadata.deviceModel}');
      print('Backup created: ${metadata.createdAt}');
      print('Cross-platform compatible: ${metadata.isCrossPlatformCompatible}');

      if (!metadata.isCrossPlatformCompatible) {
        throw Exception('Backup version ${metadata.version} is not compatible');
      }

      await _dataService.restoreFromBackup(backupData);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> shareBackup() async {
    if (kIsWeb) {
      debugPrint(
        'Share is not fully supported on Web via SharePlus for MBK files',
      );
      return false;
    }
    try {
      final backupFile = await createBackup();
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          subject: 'Parion Backup',
          text:
              'Backup created on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
        ),
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      return false;
    }
  }

  Future<List<File>> getBackupFiles() async {
    if (kIsWeb) return [];

    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(directory.path, 'backups'));

    if (!await backupDir.exists()) {
      return [];
    }

    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mbk'))
        .toList();
    files.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();
      return bStat.modified.compareTo(aStat.modified);
    });

    return files;
  }

  Future<void> cleanupOldBackups() async {
    final backups = await getBackupFiles();
    if (backups.length > 7) {
      final toDelete = backups.sublist(7);
      for (final file in toDelete) {
        await file.delete();
      }
    }
  }

  Future<BackupMetadata?> getBackupMetadata(File backupFile) async {
    if (kIsWeb) return null;
    try {
      final compressed = await backupFile.readAsBytes();
      return await getBackupMetadataFromBytes(compressed);
    } catch (e) {
      return null;
    }
  }

  Future<BackupMetadata?> getBackupMetadataFromBytes(List<int> bytes) async {
    try {
      final decompressed = GZipDecoder().decodeBytes(bytes);
      final jsonString = utf8.decode(decompressed);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (backupData.containsKey('metadata')) {
        return BackupMetadata.fromJson(backupData['metadata']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> scheduleAutomaticBackup(TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store the scheduled time
      await prefs.setInt('auto_backup_hour', time.hour);
      await prefs.setInt('auto_backup_minute', time.minute);

      // Enable automatic backup
      await prefs.setBool('auto_backup_enabled', true);

      debugPrint(
        'Automatic backup scheduled for ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );

      // Initialize background backup service if needed
      _startBackgroundBackupService();
    } catch (e) {
      debugPrint('Error scheduling automatic backup: $e');
      rethrow;
    }
  }

  /// Starts the background backup service to check for scheduled backups
  void _startBackgroundBackupService() {
    // Cancel any existing periodic timer
    _stopBackgroundBackupService();

    // Start a new timer that checks every minute if backup should run
    _backgroundBackupTimer = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) {
      _checkAndRunScheduledBackup();
    });
  }

  /// Stops the background backup service
  void _stopBackgroundBackupService() {
    if (_backgroundBackupTimer != null && _backgroundBackupTimer!.isActive) {
      _backgroundBackupTimer!.cancel();
    }
  }

  /// Checks if it's time to run the scheduled backup and runs it if needed
  Future<void> _checkAndRunScheduledBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if auto backup is enabled
      final isEnabled = prefs.getBool('auto_backup_enabled') ?? false;
      if (!isEnabled) {
        return;
      }

      // Get scheduled time
      final scheduledHour = prefs.getInt('auto_backup_hour');
      final scheduledMinute = prefs.getInt('auto_backup_minute');

      if (scheduledHour == null || scheduledMinute == null) {
        return;
      }

      // Get current time
      final now = DateTime.now();

      // Check if it's time to backup (same hour and minute)
      if (now.hour == scheduledHour && now.minute == scheduledMinute) {
        // Prevent multiple backups in the same minute
        final lastRunDate = prefs.getString('last_scheduled_backup_date');
        final today = DateFormat('yyyy-MM-dd').format(now);

        if (lastRunDate != today) {
          debugPrint('Running scheduled backup...');
          await _runScheduledBackup();
          await prefs.setString('last_scheduled_backup_date', today);
        }
      }
    } catch (e) {
      debugPrint('Error checking scheduled backup: $e');
    }
  }

  /// Runs the actual backup process
  Future<void> _runScheduledBackup() async {
    try {
      await createBackup();
      debugPrint('Scheduled backup completed successfully');

      // Optionally sync with cloud if auto cloud backup is enabled
      if (autoCloudBackupEnabled.value) {
        await uploadToCloud();
      }
    } catch (e) {
      debugPrint('Error running scheduled backup: $e');
    }
  }

  Timer? _backgroundBackupTimer;

  /// Cancels the automatic backup schedule
  Future<void> cancelAutomaticBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', false);
    _stopBackgroundBackupService();
    debugPrint('Automatic backup scheduling cancelled');
  }

  /// Checks if automatic backup is currently scheduled
  Future<bool> isAutomaticBackupScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_backup_enabled') ?? false;
  }

  /// Gets the scheduled backup time
  Future<TimeOfDay?> getScheduledBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('auto_backup_hour');
    final minute = prefs.getInt('auto_backup_minute');

    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour, minute: minute);
    }

    return null;
  }

  // Bulut yedekleme fonksiyonları - DRIVE Implementation
  Future<bool> uploadToCloud() async {
    lastError.value = null;
    debugPrint('CLOUD_BACKUP: 🔄 Starting Google Drive backup process...');
    try {
      debugPrint('CLOUD_BACKUP: 🔄 Google Drive yedekleme başlatılıyor...');

      // Check connectivity first
      debugPrint('CLOUD_BACKUP: 🔍 Checking connectivity before backup...');
      final hasConnectivity = await _driveService.isOnline();
      debugPrint(
        'CLOUD_BACKUP: 🔍 Connectivity check result: $hasConnectivity',
      );
      if (!hasConnectivity) {
        final errorMsg =
            _driveService.lastConnectionError ??
            'İnternet bağlantınızı kontrol edin';
        lastError.value = 'network_error: $errorMsg';
        debugPrint('❌ Connectivity check failed before backup: $errorMsg');
        throw Exception('network_error: $errorMsg');
      }
      debugPrint(
        'CLOUD_BACKUP: ✅ Connectivity verified, proceeding with backup',
      );

      // Auth Check
      debugPrint('CLOUD_BACKUP: 🔍 Checking authentication status...');
      if (!await _driveService.isAuthenticated()) {
        debugPrint(
          'CLOUD_BACKUP: 🔍 User not authenticated, starting sign-in process...',
        );
        await _driveService.signIn();
        debugPrint('CLOUD_BACKUP: ✅ Sign-in completed successfully');
      } else {
        debugPrint('CLOUD_BACKUP: ✅ User already authenticated');
      }

      cloudBackupStatus.value = CloudBackupStatus.uploading;
      debugPrint('CLOUD_BACKUP: 📤 Setting backup status to uploading');

      // 1. Dosyayı Oluştur (Create Local File)
      debugPrint('CLOUD_BACKUP: 📦 Preparing backup data and file...');
      File? backupFile;
      if (kIsWeb) {
        throw UnsupportedError(
          'Web upload not fully implemented for direct file IO in this method yet.',
        );
      } else {
        debugPrint('CLOUD_BACKUP: 💾 Creating local backup file...');
        backupFile = await createBackup();
        debugPrint(
          'CLOUD_BACKUP: ✅ Local backup file created: ${backupFile.path}',
        );
      }

      // 2. Drive'a Yükle
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'money_backup_$timestamp.mbk';

      debugPrint('CLOUD_BACKUP: ☁️ Uploading to Google Drive: $fileName');
      debugPrint(
        'CLOUD_BACKUP: 📁 File size: ${await backupFile!.length()} bytes',
      );

      final result = await _driveService.uploadBackup(
        backupFile,
        fileName,
        description: 'Parion Backup Version 2.0 via Google Drive',
        properties: {
          'platform': await _getPlatformInfo(),
          'deviceModel': await _getDeviceModel(),
          'version': '2.0',
        },
      );

      if (result == null) {
        debugPrint('CLOUD_BACKUP: ❌ Google Drive upload returned null result');
        throw Exception('Google Drive upload failed');
      }

      debugPrint(
        'CLOUD_BACKUP: ✅ Google Drive upload successful: ${result.id}',
      );
      debugPrint(
        'CLOUD_BACKUP: ✅ File uploaded: ${result.name} (${result.size} bytes)',
      );

      final now = DateTime.now();
      lastCloudBackupDate.value = DateFormat('dd/MM/yyyy HH:mm').format(now);
      cloudBackupStatus.value = CloudBackupStatus.idle;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_cloud_backup_date',
        lastCloudBackupDate.value!,
      );

      debugPrint('CLOUD_BACKUP: ✅ Backup process completed successfully');
      return true;
    } catch (e, stackTrace) {
      lastError.value = 'Hata: ${e.toString()}';
      debugPrint('CLOUD_BACKUP: ❌ Bulut yedekleme hatası: $e');
      debugPrint('CLOUD_BACKUP: 📍 Stack trace: $stackTrace');
      cloudBackupStatus.value = CloudBackupStatus.error;
      debugPrint('CLOUD_BACKUP: ❌ Setting backup status to error');
      return false;
    }
  }

  Future<bool> downloadFromCloud([String? backupId]) async {
    lastError.value = null;
    try {
      debugPrint('CLOUD_BACKUP: 🔄 Google Drive geri yükleme başlatılıyor...');

      // Check connectivity first
      final hasConnectivity = await _driveService.isOnline();
      if (!hasConnectivity) {
        final errorMsg =
            _driveService.lastConnectionError ??
            'İnternet bağlantınızı kontrol edin';
        lastError.value = 'network_error: $errorMsg';
        throw Exception('network_error: $errorMsg');
      }

      cloudBackupStatus.value = CloudBackupStatus.downloading;

      // Auth Check
      if (!await _driveService.isAuthenticated()) {
        await _driveService.signIn();
      }

      String? fileId = backupId;
      String? fileName;

      // Eğer ID verilmediyse en son yedeği bul
      if (fileId == null) {
        final backups = await _driveService.listBackups();
        if (backups.isEmpty) {
          debugPrint('CLOUD_BACKUP: ❌ Hiç yedek bulunamadı.');
          cloudBackupStatus.value = CloudBackupStatus.error;
          return false;
        }
        fileId = backups.first.id;
        fileName = backups.first.name;
      }

      if (fileId == null) return false;

      debugPrint('CLOUD_BACKUP: 📥 İndiriliyor: $fileId');

      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(
        tempDir.path,
        fileName ?? 'restored_backup.mbk',
      );

      final downloadedFile = await _driveService.downloadBackup(
        fileId,
        tempPath,
      );

      if (downloadedFile == null) {
        throw Exception('Dosya indirilemedi');
      }

      await restoreFromBackup(downloadedFile);

      await downloadedFile.delete(); // Cleanup

      cloudBackupStatus.value = CloudBackupStatus.idle;
      debugPrint('CLOUD_BACKUP: ✅ Geri yükleme başarılı');
      return true;
    } catch (e) {
      debugPrint('CLOUD_BACKUP: ❌ Bulut geri yükleme hatası: $e');
      // Store error for UI
      if (e.toString().contains('network') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        lastError.value = 'network_error: İnternet bağlantınızı kontrol edin';
      } else {
        lastError.value = e.toString();
      }
      cloudBackupStatus.value = CloudBackupStatus.error;
      return false;
    }
  }

  // Listeleme (Firestore yerine Drive'dan)
  Future<List<Map<String, dynamic>>> getCloudBackups() async {
    lastError.value = null;
    try {
      if (!await _driveService.isAuthenticated()) {
        return [];
      }

      // Check connectivity before listing
      final hasConnectivity = await _driveService.isOnline();
      if (!hasConnectivity) {
        final errorMsg =
            _driveService.lastConnectionError ??
            'İnternet bağlantınızı kontrol edin';
        lastError.value = 'network_error: $errorMsg';
        throw Exception('network_error: $errorMsg');
      }

      final files = await _driveService.listBackups();

      return files
          .map(
            (f) => {
              'id': f.id,
              'uploadedAt':
                  f.createdTime?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
              'size': int.tryParse(f.size ?? '0') ?? 0,
              'metadata': {
                'deviceModel':
                    f.properties?['deviceModel'] ??
                    (f.description?.contains('Android') ?? false
                        ? 'Android Device'
                        : 'Unknown Device'),
                'platform':
                    f.properties?['platform'] ??
                    (f.description?.contains('Android') ?? false
                        ? 'android'
                        : 'ios'),
                'version': f.properties?['version'] ?? '2.0',
              },
              'fileName': f.name,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('CLOUD_BACKUP: Yedek listeleme hatası: $e');
      // Store error for UI to display
      if (e.toString().contains('network') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        lastError.value = 'network_error: İnternet bağlantınızı kontrol edin';
      } else {
        lastError.value = e.toString();
      }
      rethrow; // Rethrow to let UI handle it
    }
  }

  Future<bool> deleteCloudBackup(String backupId) async {
    try {
      await _driveService.deleteBackup(backupId);
      return true;
    } catch (e) {
      debugPrint('CLOUD_BACKUP: Bulut yedek silme hatası: $e');
      return false;
    }
  }

  Future<bool> syncWithCloud() async {
    try {
      // Unified auth kontrolü for Backup is less strict than FireStore,
      // but we still want to ensure we have auth.
      // For Drive Sync, we just upload if enabled.

      if (autoCloudBackupEnabled.value) {
        return await uploadToCloud();
      }
      return true;
    } catch (e) {
      debugPrint('CLOUD_BACKUP: Bulut senkronizasyon hatası: $e');
      cloudBackupStatus.value = CloudBackupStatus.error;
      return false;
    }
  }

  Future<void> enableAutoCloudBackup(bool enabled) async {
    autoCloudBackupEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_cloud_backup_enabled', enabled);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    autoCloudBackupEnabled.value =
        prefs.getBool('auto_cloud_backup_enabled') ?? false;
    lastCloudBackupDate.value = prefs.getString('last_cloud_backup_date');
  }

  String getCloudBackupStatusText() {
    switch (cloudBackupStatus.value) {
      case CloudBackupStatus.uploading:
        return 'Buluta yükleniyor...';
      case CloudBackupStatus.downloading:
        return 'Buluttan indiriliyor...';
      case CloudBackupStatus.syncing:
        return 'Senkronize ediliyor...';
      case CloudBackupStatus.error:
        return 'Hata oluştu';
      case CloudBackupStatus.idle:
        return 'Hazır';
    }
  }
}
