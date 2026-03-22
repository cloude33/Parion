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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

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
        if (connectivityResult.contains(ConnectivityResult.none)) {
          debugPrint(
            'CLOUD_BACKUP: ⚠️ No network connection detected by Connectivity package',
          );
          // Don't return false immediately, try DNS just in case connectivity_plus is wrong
          // But log it as a potential cause
          _lastConnectionError = 'Connectivity check returned none';
        } else {
          debugPrint('CLOUD_BACKUP: ✅ General connectivity check passed');
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
    return await _googleSignIn.isSignedIn();
  }

  Future<void> signIn() async {
    if (_isTestMode) return;
    try {
      debugPrint('CLOUD_BACKUP: 🔐 Starting Google Drive sign-in process...');
      _driveApi = null;

      // 0. First check if we can actually reach Google services
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

      // 1. Try silent sign-in first
      try {
        debugPrint('CLOUD_BACKUP: 🔍 Attempting silent sign-in...');
        await _googleSignIn.signInSilently();
        debugPrint('CLOUD_BACKUP: ✅ Silent sign-in completed');
      } catch (e) {
        debugPrint('CLOUD_BACKUP: ⚠️ Silent sign-in failed: $e');
      }

      // 2. Check if we have a user and can get a client
      if (_googleSignIn.currentUser != null) {
        try {
          debugPrint('CLOUD_BACKUP: 🔍 Getting authenticated HTTP client...');
          final httpClient = await _googleSignIn.authenticatedClient();
          if (httpClient != null) {
            _driveApi = drive.DriveApi(httpClient);
            debugPrint(
              'CLOUD_BACKUP: ✅ Google Drive silent sign-in successful',
            );
            return;
          } else {
            debugPrint(
              'CLOUD_BACKUP: ❌ Failed to get authenticated HTTP client',
            );
          }
        } catch (e) {
          debugPrint('CLOUD_BACKUP: ⚠️ Silent sign-in client error: $e');
        }
      }

      // 3. Force explicit sign out to clear state if silent failed
      try {
        debugPrint('CLOUD_BACKUP: 🔍 Signing out to clear state...');
        await _googleSignIn.signOut();
        debugPrint('CLOUD_BACKUP: ✅ Sign out completed');
      } catch (e) {
        debugPrint('CLOUD_BACKUP: ⚠️ Sign out error (ignorable): $e');
      }

      // 4. Explicit sign-in
      debugPrint('CLOUD_BACKUP: 🔍 Starting explicit sign-in...');
      final account = await _googleSignIn.signIn();
      if (account != null) {
        debugPrint('CLOUD_BACKUP: ✅ Google account selected: ${account.email}');
        final httpClient = await _googleSignIn.authenticatedClient();
        if (httpClient != null) {
          _driveApi = drive.DriveApi(httpClient);
          debugPrint(
            'CLOUD_BACKUP: ✅ Google Drive explicit sign-in successful: ${account.email}',
          );
        } else {
          debugPrint(
            'CLOUD_BACKUP: ❌ Failed to get authenticated HTTP client after explicit sign-in',
          );
          throw Exception(
            'Google Sign-In succeeded but failed to obtain authenticated HTTP client. Please try again.',
          );
        }
      } else {
        debugPrint('CLOUD_BACKUP: ❌ Google Sign-In canceled by user');
        throw Exception('Google Sign-In canceled by user.');
      }
    } catch (e) {
      debugPrint('CLOUD_BACKUP: ❌ Google Drive Sign In Error: $e');
      _driveApi = null;
      rethrow;
    }
  }

  Future<bool> isOnline() async {
    try {
      // Check general connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // If there's a connection, verify we can reach external services
      return await checkGoogleConnectivity();
    } catch (e) {
      debugPrint('CLOUD_BACKUP: ⚠️ Online status check failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
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
