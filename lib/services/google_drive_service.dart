import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  bool _isTestMode = false;

  @visibleForTesting
  void setTestMode(bool value) {
    _isTestMode = value;
  }

  drive.DriveApi? _driveApi;

  String? _lastConnectionError;
  String? get lastConnectionError => _lastConnectionError;

  /// Checks if we can actually reach Google services (not just WiFi connected)
  Future<bool> checkGoogleConnectivity() async {
    if (_isTestMode) return true;
    _lastConnectionError = null; // Reset error
    try {
      debugPrint('CLOUD_BACKUP: 🔍 Starting Google connectivity check...');

      // First check general connectivity using connectivity_plus
      try {
        debugPrint('CLOUD_BACKUP: 📡 Checking general connectivity...');
        final connectivityResult = await Connectivity().checkConnectivity();
        debugPrint('CLOUD_BACKUP: 📡 Connectivity result: $connectivityResult');
        
        // If we have any active connection, immediately return true to avoid flaky DNS checks
        if (!connectivityResult.contains(ConnectivityResult.none) && connectivityResult.isNotEmpty) {
          debugPrint('CLOUD_BACKUP: ✅ General connectivity check passed (has active connection)');
          return true;
        } else {
          debugPrint(
            'CLOUD_BACKUP: ⚠️ No network connection detected by Connectivity package',
          );
          _lastConnectionError = 'Connectivity check returned none';
        }
      } catch (e) {
        // If connectivity check fails, continue with DNS/HTTP checks
        debugPrint(
          'CLOUD_BACKUP: ⚠️ Connectivity check failed, proceeding with DNS/HTTP checks: $e',
        );
        _lastConnectionError = 'Connectivity check threw: $e';
      }

      // Try multiple endpoints to increase chances of detecting connectivity
      List<String> testEndpoints = [
        'google.com',
        'www.google.com',
        'clients3.google.com',
      ];

      debugPrint(
        'CLOUD_BACKUP: 🌐 Testing DNS resolution for Google endpoints...',
      );
      bool dnsSuccess = false;
      for (String endpoint in testEndpoints) {
        try {
          debugPrint('CLOUD_BACKUP: 🔍 Testing DNS lookup for: $endpoint');
          final result = await InternetAddress.lookup(endpoint);
          debugPrint(
            'CLOUD_BACKUP: ✅ DNS lookup successful for $endpoint: ${result.length} addresses found',
          );
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            debugPrint('CLOUD_BACKUP: ✅ Google connectivity verified via DNS');
            dnsSuccess = true;
            break;
          }
        } catch (e) {
          debugPrint('CLOUD_BACKUP: ❌ DNS lookup failed for $endpoint: $e');
          _lastConnectionError = 'DNS lookup failed for $endpoint: $e';
          // Continue to next endpoint
          continue;
        }
      }

      if (dnsSuccess) return true;

      // If DNS lookup fails, try a simple HTTP request as fallback
      debugPrint('CLOUD_BACKUP: 🌐 Testing HTTP connectivity to Google...');
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        debugPrint(
          'CLOUD_BACKUP: 🔍 Sending HTTP request to https://www.google.com/generate_204',
        );
        final request = await client.getUrl(
          Uri.parse('https://www.google.com/generate_204'),
        );
        final response = await request.close();
        final success =
            response.statusCode == 204 || response.statusCode == 200;
        debugPrint(
          'CLOUD_BACKUP: ✅ HTTP request completed with status: ${response.statusCode}',
        );
        client.close();
        if (success) {
          debugPrint('CLOUD_BACKUP: ✅ Google connectivity verified via HTTP');
          return true;
        } else {
          debugPrint(
            'CLOUD_BACKUP: ❌ HTTP request failed with status: ${response.statusCode}',
          );
          _lastConnectionError =
              'HTTP request failed with status: ${response.statusCode}';
          return false;
        }
      } catch (e) {
        debugPrint(
          'CLOUD_BACKUP: ⚠️ Google API connectivity check failed with HTTP fallback: $e',
        );
        _lastConnectionError = 'HTTP check failed: $e';
        return false;
      }
    } catch (e) {
      debugPrint('CLOUD_BACKUP: ⚠️ Google API connectivity check failed: $e');
      _lastConnectionError = 'General check failed: $e';
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    if (_isTestMode) return true;
    final GoogleSignInAccount? account = await GoogleSignIn.instance.attemptLightweightAuthentication();
    if (account == null) {
      await GoogleSignIn.instance.authenticate();
      return true;
    }
    return true;
  }

  Future<void> signIn() async {
    if (_isTestMode) return;
    try {
      debugPrint('CLOUD_BACKUP: 🔐 Starting Google Drive sign-in process...');
      _driveApi = null;

      await GoogleSignIn.instance.initialize(
        serverClientId: '195092382674-ca5q05m7idrstrqpfb5bc6e00thqiu20.apps.googleusercontent.com',
      );

      debugPrint(
        'CLOUD_BACKUP: 🔍 Checking Google connectivity before sign-in...',
      );
      final hasConnectivity = await checkGoogleConnectivity();
      debugPrint(
        'CLOUD_BACKUP: 🔍 Connectivity check result: $hasConnectivity',
      );
      if (!hasConnectivity) {
        debugPrint('CLOUD_BACKUP: ❌ Google connectivity check failed');
        throw Exception(
          'network_error: Google Drive hizmetlerine erişilemiyor. Lütfen internet bağlantınızı kontrol edin. (Hata: ${_lastConnectionError ?? "Bilinmeyen ağ hatası"})',
        );
      }
      debugPrint(
        'CLOUD_BACKUP: ✅ Google connectivity verified, proceeding with sign-in',
      );

      try {
        debugPrint('CLOUD_BACKUP: 🔍 Attempting silent sign-in...');
        final GoogleSignInAccount? account = await GoogleSignIn.instance.attemptLightweightAuthentication();
        if (account != null) {
          final auth = await account.authorizationClient.authorizeScopes([drive.DriveApi.driveAppdataScope]);
          _driveApi = drive.DriveApi(auth.authClient(scopes: [drive.DriveApi.driveAppdataScope]));
          debugPrint('CLOUD_BACKUP: ✅ Google Drive silent sign-in successful');
          return;
        }
        debugPrint('CLOUD_BACKUP: ⚠️ Silent sign-in failed');
      } catch (e) {
        debugPrint('CLOUD_BACKUP: ⚠️ Silent sign-in failed: $e');
      }

      try {
        debugPrint('CLOUD_BACKUP: 🔍 Signing out to clear state...');
        await GoogleSignIn.instance.signOut();
        debugPrint('CLOUD_BACKUP: ✅ Sign out completed');
      } catch (e) {
        debugPrint('CLOUD_BACKUP: ⚠️ Sign out error (ignorable): $e');
      }

      debugPrint('CLOUD_BACKUP: 🔍 Starting explicit sign-in...');
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      debugPrint('CLOUD_BACKUP: ✅ Google account selected: ${account.email}');
      final auth = await account.authorizationClient.authorizeScopes([drive.DriveApi.driveAppdataScope]);
      _driveApi = drive.DriveApi(auth.authClient(scopes: [drive.DriveApi.driveAppdataScope]));
      debugPrint('CLOUD_BACKUP: ✅ Google Drive explicit sign-in successful: ${account.email}');
    } catch (e) {
      debugPrint('CLOUD_BACKUP: ❌ Google Drive Sign In Error: $e');
      _driveApi = null;
      rethrow;
    }
  }

  Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      return await checkGoogleConnectivity();
    } catch (e) {
      debugPrint('CLOUD_BACKUP: ⚠️ Online status check failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _driveApi = null;
  }

  Future<drive.File?> uploadBackup(
    File file,
    String fileName, {
    String? description,
    Map<String, String>? properties,
  }) async {
    if (_isTestMode) {
      return drive.File()
        ..id = 'test_file_id'
        ..name = fileName;
    }
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Google Drive API not initialized');

    try {
      final uploadMedia = drive.Media(file.openRead(), await file.length());

      final driveFile = drive.File()
        ..name = fileName
        ..description = description
        ..parents = ['appDataFolder'];

      if (properties != null) {
        driveFile.properties = properties;
      }

      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: uploadMedia,
      );

      debugPrint('CLOUD_BACKUP: Drive Upload Success: ${result.id}');
      return result;
    } catch (e) {
      debugPrint('CLOUD_BACKUP: Drive Upload Error: $e');
      rethrow; // Rethrow to show actual error
    }
  }

  Future<List<drive.File>> listBackups() async {
    if (_isTestMode) return [];
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Google Drive API not initialized');

    try {
      final fileList = await _driveApi!.files.list(
        q: "name contains 'money_backup_' and 'appDataFolder' in parents and trashed = false",
        $fields: "files(id, name, createdTime, size, description, properties)",
        orderBy: "createdTime desc",
        spaces: 'appDataFolder',
      );

      return fileList.files ?? [];
    } catch (e) {
      debugPrint('CLOUD_BACKUP: Drive List Error: $e');
      rethrow;
    }
  }

  Future<File?> downloadBackup(String fileId, String savePath) async {
    if (_isTestMode) {
      final file = File(savePath);
      await file.writeAsString('test backup content');
      return file;
    }
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Google Drive API not initialized');

    try {
      final media =
          await _driveApi!.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final file = File(savePath);
      final sink = file.openWrite();

      await media.stream.pipe(sink);
      await sink.close();

      return file;
    } catch (e) {
      debugPrint('CLOUD_BACKUP: Drive Download Error: $e');
      rethrow;
    }
  }

  Future<void> deleteBackup(String fileId) async {
    if (_isTestMode) return;
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Google Drive API not initialized');

    try {
      await _driveApi!.files.delete(fileId);
      debugPrint('CLOUD_BACKUP: Drive Delete Success: $fileId');
    } catch (e) {
      debugPrint('CLOUD_BACKUP: Drive Delete Error: $e');
      rethrow;
    }
  }
}
