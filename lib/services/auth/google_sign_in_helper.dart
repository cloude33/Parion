import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../firebase_options.dart';

/// Sonuç modeli: Google Sign-In çıktısı
class GoogleSignInOutcome {
  final UserCredential? userCredential;
  final String? errorMessage;
  final String? errorCode;
  final bool isCancelled;

  const GoogleSignInOutcome.success(this.userCredential)
      : errorMessage = null,
        errorCode = null,
        isCancelled = false;

  const GoogleSignInOutcome.failure(this.errorMessage, {this.errorCode})
      : userCredential = null,
        isCancelled = false;

  const GoogleSignInOutcome.cancelled()
      : userCredential = null,
        errorMessage = 'Google ile giriş iptal edildi',
        errorCode = 'cancelled',
        isCancelled = true;

  bool get isSuccess => userCredential != null;
}

/// Google Sign-In akışını merkezileştiren servis (google_sign_in v6 API).
///
/// Tek bir `GoogleSignIn` instance'ı kullanır (platform tarafı singleton'dur;
/// birden fazla instance sessiz başarısızlığa yol açar). Hem Firebase
/// kimlik doğrulama hem de Google Drive yedekleme aynı instance üzerinden
/// yapılır; bu nedenle scope'lar baştan tanımlanır.
///
/// Tüm SHA-1 / OAuth client hataları burada açık Türkçe mesajlarla loglanır;
/// `adb logcat` üzerinden takip edilebilir.
class GoogleSignInHelper {
  // Web OAuth client (type 3) — Firebase ID token üretir.
  // android/app/src/main/res/values/strings.xml içindeki
  // default_web_client_id ile aynı değer.
  static const String _webClientId =
      '195092382674-ca5q05m7idrstrqpfb5bc6e00thqiu20.apps.googleusercontent.com';

  // Drive için gereken scope. Tüm sign-in akışlarında istenir; kullanıcı ilk
  // girişte tüm scope'ları onaylar, sonraki signIn() çağrılarında sessiz geçer.
  static const List<String> _driveScopes = <String>[
    drive.DriveApi.driveAppdataScope,
  ];

  GoogleSignInHelper._internal();
  static final GoogleSignInHelper instance = GoogleSignInHelper._internal();

  // v6 API: GoogleSignIn instance (singleton) — tüm akışlar bu instance'ı
  // kullanır. Web'de clientId, mobilde serverClientId ile Firebase ID token üretilir.
  late final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(clientId: _webClientId, scopes: _driveScopes)
      : GoogleSignIn(serverClientId: _webClientId, scopes: _driveScopes);

  /// Tüm Google Sign-In çağrılarının kullandığı instance.
  /// Başka servisler (Drive vb.) bu getter üzerinden erişir.
  GoogleSignIn get googleSignIn => _googleSignIn;

  /// Web redirect ile giriş yapılmışsa UserCredential döner.
  Future<UserCredential?> checkRedirectResult() async {
    if (!kIsWeb) return null;
    try {
      final credential = await FirebaseAuth.instance.getRedirectResult();
      return credential;
    } catch (e) {
      debugPrint('⚠️ [GSIH] checkRedirectResult: $e');
      return null;
    }
  }

  /// Google ile giriş yapıp Firebase credential döner.
  Future<GoogleSignInOutcome> signIn() async {
    try {
      // 🌐 WEB PLATFORMU:
      // Web üzerinde doğrudan Firebase Auth kullanılır.
      // Önce signInWithPopup denenir (anında tık event'inde açılır).
      // Pop-up engellenirse otomatik olarak signInWithRedirect fallback'i devreye girer.
      if (kIsWeb) {
        debugPrint('🌐 [GSIH] Web platformu: Google Provider oluşturuluyor...');
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });

        try {
          final userCredential = await FirebaseAuth.instance
              .signInWithPopup(googleProvider)
              .timeout(
                const Duration(seconds: 45),
                onTimeout: () =>
                    throw TimeoutException('Google ile giriş işlemi zaman aşımına uğradı'),
              );

          debugPrint('✅ [GSIH] Web Google Sign-In (Popup) başarılı: ${userCredential.user?.email}');
          return GoogleSignInOutcome.success(userCredential);
        } on FirebaseAuthException catch (e) {
          debugPrint('⚠️ [GSIH] Web Popup FirebaseAuthException: ${e.code} - ${e.message}');
          if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
            return const GoogleSignInOutcome.cancelled();
          }

          // Pop-up tarayıcı tarafından engellendiyse (Chrome COOP/third-party storage vb.)
          // doğrudan tam sayfa yönlendirme (redirect) fallback'ini çalıştır:
          if (e.code == 'popup-blocked' ||
              e.code == 'cancelled-popup-request' ||
              e.code.contains('popup')) {
            debugPrint('🔄 [GSIH] Pop-up engellendi, signInWithRedirect başlatılıyor...');
            try {
              await FirebaseAuth.instance.signInWithRedirect(googleProvider);
              return const GoogleSignInOutcome.cancelled();
            } catch (redirErr) {
              debugPrint('❌ [GSIH] signInWithRedirect hatası: $redirErr');
              return GoogleSignInOutcome.failure(
                'Google giriş sayfasına yönlendirilemedi: $redirErr',
                errorCode: 'redirect-failed',
              );
            }
          }

          if (e.code == 'unauthorized-domain') {
            final host = Uri.base.host;
            return GoogleSignInOutcome.failure(
              'Bu alan adı ($host) Firebase Console > Authentication > Settings > Authorized domains listesinde yetkilendirilmemiş. Lütfen ekleyin.',
              errorCode: 'unauthorized-domain',
            );
          }

          return GoogleSignInOutcome.failure(
            _mapFirebaseError(e),
            errorCode: e.code,
          );
        } on TimeoutException catch (_) {
          return const GoogleSignInOutcome.failure(
            'Google ile giriş zaman aşımına uğradı. Lütfen tekrar deneyin.',
            errorCode: 'timeout',
          );
        } catch (e) {
          debugPrint('❌ [GSIH] Web beklenmeyen hata, redirect deneniyor: $e');
          try {
            await FirebaseAuth.instance.signInWithRedirect(googleProvider);
            return const GoogleSignInOutcome.cancelled();
          } catch (_) {
            return GoogleSignInOutcome.failure(
              'Google ile giriş sırasında hata oluştu: $e',
              errorCode: 'web_unknown',
            );
          }
        }
      }

      // 📱 MOBİL PLATFORM (Android / iOS):
      // Eski oturumu temizle (hesap seçiciyi tekrar göstermek için)
      try {
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('🔐 [GSIH] signOut ignored: $e');
      }

      // v6 API: signIn() — hesap seçici gösterir
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw TimeoutException('Google hesap seçimi zaman aşımına uğradı'),
      );

      if (googleUser == null) {
        return const GoogleSignInOutcome.cancelled();
      }

      debugPrint('🔐 [GSIH] Google hesabı seçildi: ${googleUser.email}');

      // Token al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint(
          '❌ [GSIH] idToken boş. SHA-1 ekli mi? '
          'Firebase Console > Project Settings > Android app > Fingerprint',
        );
        return const GoogleSignInOutcome.failure(
          'Google hesabından kimlik token alınamadı. '
          'Firebase Console\'da SHA-1 parmak izini ve package name\'i kontrol edin.',
          errorCode: 'no_id_token',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('✅ [GSIH] Firebase auth başarılı: ${userCredential.user?.uid}');
      return GoogleSignInOutcome.success(userCredential);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [GSIH] FirebaseAuthException: ${e.code} - ${e.message}');
      return GoogleSignInOutcome.failure(
        _mapFirebaseError(e),
        errorCode: e.code,
      );
    } on PlatformException catch (e) {
      debugPrint('❌ [GSIH] PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_canceled' || e.code == '10') {
        return const GoogleSignInOutcome.cancelled();
      }
      return GoogleSignInOutcome.failure(
        _mapPlatformError(e),
        errorCode: e.code,
      );
    } on TimeoutException catch (e) {
      debugPrint('❌ [GSIH] TimeoutException: $e');
      return GoogleSignInOutcome.failure(
        e.message ?? 'Google ile giriş zaman aşımına uğradı.',
        errorCode: 'timeout',
      );
    } catch (e, st) {
      debugPrint('❌ [GSIH] Unexpected: $e\n$st');
      return GoogleSignInOutcome.failure(
        'Google ile giriş sırasında beklenmeyen bir hata oluştu: $e',
        errorCode: 'unknown',
      );
    }
  }

  /// Drive API için authenticated HTTP client döner.
  /// Sign-in yapılmamışsa null döner; çağıran taraf sessiz sign-in denemelidir.
  Future<drive.DriveApi?> getDriveApi() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return null;
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return null;
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('❌ [GSIH] getDriveApi failed: $e');
      return null;
    }
  }

  /// Sign-in durumunu kontrol eder.
  Future<bool> isSignedIn() async {
    if (kIsWeb) {
      return FirebaseAuth.instance.currentUser != null;
    }
    try {
      final account = await _googleSignIn.signInSilently();
      return account != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('⚠️ [GSIH] googleSignIn.signOut: $e');
      }
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('⚠️ [GSIH] Firebase.signOut: $e');
    }
  }

  /// Build'te kullanılan proje kimliğini döner (debug log için).
  static String get projectId => DefaultFirebaseOptions.currentPlatform.projectId;

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'popup-closed-by-user':
      case 'cancelled':
        return 'Google ile giriş iptal edildi.';
      case 'popup-blocked':
        return 'Tarayıcınız açılır pencereyi (pop-up) engelledi. Lütfen adres çubuğundan pop-up izni verin.';
      case 'unauthorized-domain':
        return 'Bu alan adı Firebase Console > Authentication > Settings > Authorized domains listesinde yetkilendirilmemiş.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok veya Firebase sunucularına ulaşılamıyor.';
      case 'invalid-credential':
        return 'Google kimlik bilgisi geçersiz. Lütfen tekrar deneyin.';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta farklı bir giriş yöntemiyle kayıtlı.';
      case 'operation-not-allowed':
        return 'Firebase Console\'da Google ile giriş etkinleştirilmemiş.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      default:
        return e.message ?? 'Firebase kimlik doğrulama hatası (${e.code}).';
    }
  }

  String _mapPlatformError(PlatformException e) {
    final msg = e.message ?? '';
    if (e.code == 'sign_in_failed') {
      if (msg.contains('12500') ||
          msg.contains('10') ||
          msg.contains('DeveloperError') ||
          msg.contains('ApiException: 10')) {
        return 'Google yapılandırma hatası (DeveloperError / 10).\n'
            'Kontrol edin:\n'
            '  1. Firebase Console > Project Settings > Android app\'e tüm SHA-1 (debug, upload, Play Store) ekli mi\n'
            '  2. default_web_client_id string resource tanımlı mı\n'
            '  3. package_name com.bulut.wallet ile OAuth client eşleşiyor mu';
      }
      return 'Google Sign-In başarısız: ${msg.isNotEmpty ? msg : e.code}';
    }
    return 'Cihaz seviyesinde hata (${e.code}): ${msg.isNotEmpty ? msg : ''}';
  }
}
