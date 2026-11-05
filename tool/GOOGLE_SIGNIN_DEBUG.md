# Parion - Google Sign-In Hata Ayıklama Rehberi

## Yapılan Düzeltmeler (otomatik uygulandı)

| # | Sorun | Düzeltme | Dosya |
|---|---|---|---|
| 1 | Yedek MainActivity.kt dosyaları (2 kopya) | Silindi | `android/app/src/main/kotlin/com/{bulut/parion, example/bulut}/` |
| 2 | `default_web_client_id` string resource yoktu | Eklendi | `android/app/src/main/res/values/strings.xml` (yeni) |
| 3 | Üç ayrı `GoogleSignIn` instance → platform singleton çakışması | Tek singleton'a birleştirildi | `google_sign_in_helper.dart`, `auth_service.dart`, `google_drive_service.dart`, `social_login_service.dart`, `firebase_auth_service.dart` |
| 4 | `google-services.json`'da 3 SHA-1, hepsi yerinde | Dokunulmadı (doğru) | — |
| 5 | `firebase_options.dart` ios/macos'ta yanlış `androidClientId` | Temizlendi | `lib/firebase_options.dart` |
| 6 | Hata logları yetersiz | Tüm `🔐 [GSIH]` log'ları eklendi | `google_sign_in_helper.dart` |

## Yapılması Gereken (manuel)

### 🔴 KRİTİK: Play Store SHA'sı Firebase Console'a eklenmeli

**Google Play Store dağıtılan APK'lar Play App Signing kullanır → Play Store'un kendi SHA-1'i ile imzalanır. Bu SHA Firebase'te kayıtlı değilse Google Sign-In "10 / DeveloperError" hatası verir.**

1. https://play.google.com/console → Parion uygulaması
2. **Kurulum (Setup) → Uygulama imzalama (App signing)**
3. **"Uygulama imzalama anahtarı sertifikası"** bölümünden **SHA-1** ve **SHA-256** kopyala
4. https://console.firebase.google.com → `walletapp-ece89` projesi
5. **Project Settings (⚙️) → General → Your apps → Android app → Fingerprint**
6. **"Add fingerprint"** → SHA-1 ve SHA-256'yı yapıştır
7. Kaydet (birkaç dakika sürebilir)

## Cihazda Debug (sizin yapmanız gereken)

```powershell
# Cihazı USB ile bağlayın (USB Debug açık)
cd E:\KODLAMA\Parion
flutter clean
flutter pub get
flutter run --debug
```

Hata mesajı ekranda veya `adb logcat` çıktısında görünecek. **Paylaşırsanız tam kök nedeni söylerim.**

### Yardımcı script

```powershell
# SHA'ları görmek için
powershell -ExecutionPolicy Bypass -File E:\KODLAMA\Parion\tool\debug_google_signin.ps1 -ShaOnly

# Veya interaktif menü
powershell -ExecutionPolicy Bypass -File E:\KODLAMA\Parion\tool\debug_google_signin.ps1

# Sadece logcat izlemek için (ayrı terminal)
powershell -ExecutionPolicy Bypass -File E:\KODLAMA\Parion\tool\debug_google_signin.ps1 -WatchLogs
```

## Beklenen Hata Kodları ve Anlamları

| Hata | Anlam | Çözüm |
|---|---|---|
| `ApiException: 10` / `DeveloperError` / `12500` | SHA-1 uyuşmazlığı | Play Store SHA'sını Firebase'e ekle |
| `No id token` | OAuth client_id yanlış veya SHA eksik | `default_web_client_id` kontrol et |
| `network-request-failed` | İnternet yok | WiFi/mobil veri kontrol |
| `sign_in_canceled` | Kullanıcı iptal etti | Sorun değil |
| `PlatformException(sign_in_failed, ...)` | Genel hata | Tam mesajı paylaş |
