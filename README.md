# 💰 Parion - Kişisel Finans Uygulaması v1.0.12

Modern Flutter tabanlı, kapsamlı kişisel finans yönetimi uygulaması. Bütçe, kredi kartı, KMH, yatırım, döviz, fatura, abonelik, hedef, borç ve daha fazlasını tek yerden yönetin.

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.12-brightgreen.svg)](https://github.com/cloude33/Parion/releases/latest)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-orange.svg)]()

## 📑 İçindekiler

- [Hakkında](#-hakkında)
- [Ekran Görüntüleri](#-ekran-görüntüleri)
- [Özellikler](#-özellikler)
- [Mimari](#-mimari)
- [Kurulum](#-kurulum)
- [Yapılandırma](#-yapılandırma)
- [Çalıştırma](#-çalıştırma)
- [Test](#-test)
- [Build](#-build)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Bilinen Sınırlamalar](#-bilinen-sınırlamalar)
- [Yol Haritası](#-yol-haritası)
- [Katkıda Bulunma](#-katkıda-bulunma)
- [Lisans](#-lisans)
- [English Summary](#-english-summary)

## 🌟 Hakkında

**Parion**, kişisel finans yönetimini kolaylaştırmak, harcamaları takip etmek ve finansal özgürlüğünüze ulaşmanıza yardımcı olmak için tasarlanmış kapsamlı ve modern bir Flutter uygulamasıdır. Çoklu kullanıcı desteği, bulut senkronizasyonu, gelişmiş analiz araçları ve 60+ ekran ile gelir, gider, borç, yatırım, kripto, döviz ve daha fazlasını tek bir yerden yönetmenizi sağlar.

## ✨ Özellikler

### 💳 Finansal Yönetim (Core)

- **Gelir/Gider Takibi**: 30+ hazır kategori, özel kategori ekleme, etiket sistemi.
- **Cüzdan Yönetimi**: Nakit, banka, kredi kartı, KMH, yatırım hesapları.
- **Çoklu Kullanıcı**: Aile bireyleri veya ortak hesaplar için ayrı profil yönetimi.
- **Misafir Modu**: Kayıt olmadan hızlı kullanım.
- **Hızlı İşlem**: Tek tıkla gelir/gider kaydı, ana sayfadan erişim.

### 🏦 KMH (Kredili Mevduat Hesabı)

- **Otomatik Günlük Faiz Hesaplama**: Bakiye bazlı, kesin matematiksel hesaplama.
- **Akıllı Limit Uyarıları**: %80 ve %95 eşiklerinde bildirim.
- **Ödeme Planlayıcı**: Birden fazla plan yan yana karşılaştırma.
- **Karşılaştırma Ekranı**: Planları yan yana analiz ederek en uygununu seçin.
- **Faiz Hesaplayıcı**: Detaylı senaryo analizi.
- **Hesap Özeti & Ekstre**: Tarih bazlı hareket ve faiz dökümü.
- **Hatırlatıcılar**: Ödeme tarihi yaklaşınca push notification.
- **Para Yatırma/Çekme**: Ayrı ekranlar ile kolay işlem.

### 💳 Kredi Kartı Yönetimi

- **Ekstre Takibi**: Aylık ekstre görüntüleme, analiz ve dışa aktarma.
- **Taksit Yönetimi**: Taksitli alışverişler, ertelenmiş taksit takibi.
- **Nakit Avans**: Hızlı nakit avans işlemleri ve geri ödeme planı.
- **Limit Kontrolleri**: Toplam kullanım, kullanılabilir limit ve uyarılar.
- **Otomatik Ekstre Üretimi**: Periyodik ekstre oluşturma.
- **Bildirimler**: Ekstre kesim ve son ödeme hatırlatıcıları.
- **Raporlama**: Aylık/yıllık kart bazlı detaylı raporlar.
- **Ödeme Simülasyonu**: Farklı ödeme senaryoları.

### 🪙 Yatırım & Kripto

- **Kripto Portföy**: Anlık fiyat takibi (CoinGecko API entegrasyonu).
- **Al/Sat İşlemleri**: Alış fiyatı, miktar, tarih ve notlar.
- **Kar/Zarar Analizi**: Anlık P&L hesaplaması.
- **Detaylı Görünüm**: Her yatırım için ayrıntılı performans ekranı.
- **Çoklu Coin Desteği**: 10.000+ kripto para birimi.

### 💱 Döviz Kurları

- **Anlık Kur Takibi**: 35+ para birimi (USD, EUR, GBP, JPY, vb.).
- **Türk Lirası Karşılığı**: "1 USD = 43,68 ₺" formatında premium gösterim.
- **Çevirici**: İki yönlü döviz hesaplayıcı.
- **Featured Kartlar**: USD, EUR, GBP öne çıkan kartlar.
- **Arama/Filtreleme**: Anlık para birimi arama.
- **Son Güncelleme**: Her kurların zaman damgası.
- **Para Birimi Ayarları**: Varsayılan para birimi seçimi.

### 💸 Borç & Alacak

- **Borç/Alacak Takibi**: Borç verdiğiniz ve aldığınız tutarlar.
- **Hatırlatıcılar**: Vade yaklaşınca bildirim.
- **Ödeme Planı**: Taksitli borç yönetimi.
- **Detay Ekranı**: Borç geçmişi ve ödeme logu.
- **İstatistikler**: Borç dağılımı ve trend analizi.

### 📋 Bütçe Yönetimi

- **Aylık Bütçeler**: Kategori bazlı harcama limitleri.
- **Bütçe Takibi**: Gerçekleşen vs planlanan görselleştirme.
- **Uyarılar**: Bütçe aşımında bildirim.
- **Geçmiş Analiz**: Aylar arası karşılaştırma.

### 🔄 Tekrarlayan İşlemler

- **Otomasyon**: Kira, abonelik, fatura gibi düzenli ödemeler.
- **Esnek Sıklık**: Günlük, haftalık, aylık, yızlık.
- **Otomatik Oluşturma**: Tarih geldiğinde otomatik işlem ekleme.
- **Şablonlar**: Sık kullanılan tekrar eden işlemler.
- **İstatistikler**: Tekrarlayan işlem bazlı analiz.

### 🧾 Fatura Takibi

- **Geniş Servis Sağlayıcı Veritabanı**: 81 il, tüm sektörler.
- **Akıllı Fatura Girişi**: Mükerrer kayıt önleme.
- **Ödeme Durumu**: Ödendi/beklemede/geç ödeme.
- **Detaylı İstatistik**: Fatura bazlı analiz.
- **Şablonlar**: Hızlı fatura girişi için.

### 🎯 Hedefler

- **Tasarruf Hedefleri**: Belirli bir amaç için birikim.
- **İlerleme Takibi**: Görsel ilerleme çubuğu.
- **Hedef Tarihi**: Zaman sınırı ile planlama.
- **Hedef Listesi**: Tüm hedeflerinizi tek yerden yönetin.

### 🎁 Ödül Puanları

- **Kredi Kartı Puanları**: Harcamalardan kazanılan puanlar.
- **Puan Geçmişi**: Kazanım ve kullanım dökümü.
- **Puan Raporları**: Kategori bazlı puan analizi.

### 📊 Gelişmiş Analiz ve Raporlama

- **Detaylı İstatistikler**: Nakit akışı, harcama dağılımı, kategori analizi.
- **Finansal Sağlık Skoru**: Akıllı skorlama sistemi (0-100).
- **Trend Analizi**: Harcama alışkanlıkları ve kategorisel değişimler.
- **Karşılaştırmalar**: Geçen ay vs bu ay, yıllık bazda.
- **Yıllık Rapor**: Yıl sonu özet raporu.
- **İstatistik Arka Plan Servisi**: Arka planda otomatik hesaplama.
- **Günlük Özet**: Günlük finansal özet.
- **Çoklu Rapor Formatları**: Excel, PDF, CSV, QIF, OFX.

### 📲 Bildirimler

- **Yerel Bildirimler**: `flutter_local_notifications` ile offline bildirim.
- **Push Bildirimler (FCM)**: Firebase Cloud Messaging.
- **Akıllı Bildirimler**:
  - Fatura son ödeme tarihleri
  - Bütçe aşımları
  - KMH limit uyarıları
  - Borç hatırlatıcıları
  - Tekrarlayan işlem bildirimleri
- **Bildirim Geçmişi**: Tüm bildirimleri görüntüleme.
- **Bildirim Tercihleri**: Kategori bazlı açma/kapama.
- **Zaman Dilimi Desteği**: `timezone` ile doğru zamanlama.

### 📸 OCR & Fiş Tarama

- **Otomatik Fiş Tanıma**: `google_mlkit_text_recognition` ile.
- **Akıllı Kategori Önerisi**: Tutar ve açıklamadan kategori tahmini.
- **Hızlı İşlem Oluşturma**: Tek tıkla fişten işlem ekleme.
- **Galeri/Kamera**: Çoklu kaynak desteği.

### ☁️ Yedekleme & Senkronizasyon

- **Google Drive Yedekleme**: Otomatik cloud backup.
- **Firebase Firestore Senkronizasyon**: Çapraz cihaz senkronizasyonu.
- **Otomatik Yedekleme**: Zamanlayıcı ile periyodik yedek.
- **Offline Senkronizasyon**: Çevrimdışı işlem kuyruğu.
- **Veri İçe/Dışa Aktarma**: Excel, PDF, CSV, QIF, OFX formatlarında.
- **Yedekleme Geçmişi**: Tüm yedekleri listeleme ve geri yükleme.

### 🔐 Güvenlik

- **Çoklu Kimlik Doğrulama**:
  - E-posta/Şifre (Firebase Auth)
  - Google Sign-In (Native + Web)
  - Apple Sign-In (iOS)
- **Biyometrik Giriş**: Parmak izi ve yüz tanıma (Android/iOS).
- **PIN Koruması**: 4-6 haneli uygulama içi PIN.
- **App Lock**: Arka plana alındığında otomatik kilit.
- **Veri Şifreleme**: Hassas veriler AES-256 ile şifrelenmiş.
- **Güvenli Depolama**: `flutter_secure_storage` ile keychain/keystore.
- **Oturum Yönetimi**: Session timeout ve otomatik çıkış.
- **Güvenlik Olay Logu**: Tüm güvenlik olaylarını kayıt altına alma.
- **Hata Loglama**: Detaylı hata raporlama sistemi.

### 🎨 Kullanıcı Deneyimi

- **Light/Dark Tema**: Sistem temasına otomatik uyum veya manuel seçim.
- **Çoklu Dil**: Türkçe (varsayılan) ve İngilizce desteği.
- **Onboarding**: İlk açılışta rehberli tanıtım.
- **Yardım Ekranı**: SSS ve kullanım kılavuzu.
- **Hakkında Ekranı**: Versiyon bilgisi ve lisans detayları.
- **Modern UI**: Material 3 tasarım sistemi, gradient'ler, animasyonlar.
- **Premium Ekranlar**: Kurlar, dashboard gibi ekranlarda özel tasarım.
- **Pull-to-Refresh**: Tüm listelerde.
- **Sonsuz Kaydırma (Pagination)**: Performans optimizasyonu.
- **Görsel Önbellek**: `cache_service` ile hızlı yükleme.
- **Performans Monitörü**: Frame timing ve memory takibi.
- **Görsel Optimizasyon**: Otomatik resim sıkıştırma.

### 🔋 Cihaz Entegrasyonu

- **Pil Optimizasyonu Muafiyeti**: OnePlus HANS ve agresif pil yönetimi olan cihazlar için native handler.
- **Bağlantı Kontrolü**: Çevrimdışı/çevrimiçi durumu takibi.
- **İzin Yönetimi**: Storage, kamera, bildirim vb. izinler.
- **Uygulama Yaşam Döngüsü**: Foreground/background state tracking.
- **Paylaşım**: `share_plus` ile işlem ve rapor paylaşımı.

### 📅 Planlama & Organizasyon

- **Takvim Görünümü**: Tüm işlemleri takvimde görüntüleme.
- **Tüm İşlemler**: Tarih ve kategori bazlı filtreleme.
- **Akıllı Kategori Servisi**: Açıklamadan otomatik kategori tahmini.
- **Etiket Sistemi**: İşlemleri etiketlerle organize etme.
- **İşlem Filtreleme**: Gelişmiş filtreleme servisi.

### 🏗️ Mimari (Yazılım)

- **Dependency Injection**: `get_it` tabanlı service locator.
- **Modern DI Pattern**: Lazy initialization ve singleton yönetimi.
- **Hive**: Yerel veritabanı (10+ box tipi).
- **Firebase**: Auth, Firestore, Storage, Analytics, Messaging.
- **REST API**: HTTP tabanlı 3rd parti API entegrasyonları.
- **State Management**: Provider + Service Layer pattern.
- **Error Handling**: Merkezi hata yakalama ve loglama.
- **Background Services**: Arka plan servisleri (lock, statistics, KMH).

## 🚀 Kurulum

### Gereksinimler

- **Flutter SDK**: 3.10.0 veya üzeri
- **Dart SDK**: 3.10.0 veya üzeri
- **Android Studio** (Android geliştirme için) veya **Xcode** (iOS, Mac gerektirir)
- **VS Code** veya tercih ettiğiniz IDE
- **Git**

### Kurulum Adımları

1. **Projeyi Klonlayın:**
```bash
git clone https://github.com/cloude33/Parion.git
cd Parion
```

2. **Bağımlılıkları Yükleyin:**
```bash
flutter pub get
```

3. **Firebase Yapılandırması:**
```bash
# FlutterFire CLI'yi yükleyin (bir kez)
dart pub global activate flutterfire_cli

# Firebase yapılandırmasını oluşturun
flutterfire configure --project=YOUR_PROJECT_ID
```

4. **Android için ek ayarlar:**
   - `android/app/google-services.json` dosyasının doğru yerleştirildiğinden emin olun.
   - `android/key.properties` dosyasını oluşturun (release build için).

5. **iOS için ek ayarlar:**
   - `ios/Runner/GoogleService-Info.plist` dosyasını ekleyin.
   - CocoaPods kurulumu: `cd ios && pod install`

## ⚙️ Yapılandırma

### Firebase Projesi

- Firebase Console'dan yeni proje oluşturun
- Authentication > Sign-in method'dan **E-posta/Şifre** ve **Google**'u etkinleştirin
- Android, iOS ve Web uygulamalarını ekleyin
- `flutterfire configure` çalıştırın

### Döviz Kurları (Exchange Rate API)

`lib/services/exchange_rate_service.dart` dosyasında API endpoint'i:
- Şu an: `https://open.er-api.com/v6/latest/TRY` (ücretsiz, anahtar gerektirmez)
- Alternatif: ExchangeRate-API, Frankfurter, vb.

### Kripto Fiyatları (CoinGecko)

`lib/services/investment_service.dart`:
- Endpoint: CoinGecko public API
- API key gerektirmez (free tier yeterli)

## 🏃 Çalıştırma

```bash
# Geliştirme modu - Android
flutter run -d android

# Geliştirme modu - iOS (Mac gerektirir)
flutter run -d ios

# Geliştirme modu - Web (Chrome)
flutter run -d chrome

# Sıcak yeniden yükleme
r (terminalde)

# Sıcak yeniden başlatma
R (terminalde)
```

## 🧪 Test

```bash
# Tüm testleri çalıştır
flutter test

# Belirli bir test dosyası
flutter test test/widget_test.dart

# Coverage raporu
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Lint & Analiz

```bash
# Statik analiz
flutter analyze

# Format kontrolü
dart format --set-exit-if-changed lib/

# Otomatik format
dart format lib/
```

## 📦 Build

### Android (APK)

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### Android Split Per ABI

```bash
flutter build apk --release --split-per-abi
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 🛠️ Teknoloji Yığını

### Frontend
- **Framework**: Flutter 3.10+
- **Dil**: Dart 3.10+
- **UI**: Material 3, Custom gradients, fl_chart

### State Management & DI
- **DI**: `get_it` (Service Locator pattern)
- **State**: Provider + ChangeNotifier

### Backend & Database
- **Auth**: Firebase Auth (Email/Google/Apple)
- **Cloud DB**: Cloud Firestore
- **Storage**: Firebase Storage
- **Local DB**: Hive (10+ box)
- **Push**: Firebase Cloud Messaging

### 3rd Party APIs
- **Döviz**: open.er-api.com
- **Kripto**: CoinGecko
- **Google Drive Backup**: googleapis + extension_google_sign_in_as_googleapis_auth

### Güvenlik
- **Encryption**: AES-256, `crypto` paketi
- **Storage**: `flutter_secure_storage` (Android Keystore / iOS Keychain)
- **Biometric**: `local_auth`

### Diğer
- **Charts**: fl_chart
- **Notifications**: flutter_local_notifications + timezone
- **OCR**: google_mlkit_text_recognition
- **Icons**: font_awesome_flutter, line_icons, lucide_icons_flutter
- **Reporting**: excel, pdf, csv, archive
- **Import/Export**: qif, ofx
- **Images**: image_picker, image_cropper, image
- **PDF/Excel**: pdf, excel
- **Connectivity**: connectivity_plus
- **Permissions**: permission_handler
- **Sharing**: share_plus
- **Performance**: cache_service, performance_monitor, pagination_service

## ⚠️ Bilinen Sınırlamalar

- **OnePlus Cihazlar**: OnePlus HANS sistemi uygulamayı agresif şekilde dondurabilir. **Ayarlar > Pil > Pil optimizasyonu > Parion > Optimize etme** seçeneğini etkinleştirin (uygulama bunu otomatik olarak ister).
- **Web Platformu**: Google Sign-In Web'de OAuth Client ID yapılandırması gerektirir. Email/Password için `localhost` Firebase Console'da yetkili domain olarak eklenmiş olmalıdır.
- **iOS**: macOS olmadan build alınamaz.
- **Çoklu Kullanıcı**: Aynı anda birden fazla kullanıcı oturumu desteklenmez, ancak hızlı geçiş yapılabilir.

## 🗺️ Yol Haritası

- [ ] Yapay zeka destekli harcama tahmini
- [ ] Bütçe önerileri
- [ ] Yatırım portföy analizi ve öneriler
- [ ] Sesli komut ile işlem ekleme
- [ ] Widget desteği (ana ekran)
- [ ] Apple Watch / Wear OS uygulaması
- [ ] Ortak hesaplar (eş, aile)
- [ ] Daha fazla dil desteği (Almanca, Arapça, vb.)
- [ ] Fatura otomatik okuma (e-Fatura entegrasyonu)

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz!

1. **Fork**'layın
2. Feature branch oluşturun:
   ```bash
   git checkout -b feature/YeniOzellik
   ```
3. Değişikliklerinizi commit edin:
   ```bash
   git commit -m 'feat: Yeni özellik eklendi'
   ```
4. Branch'inizi push edin:
   ```bash
   git push origin feature/YeniOzellik
   ```
5. **Pull Request** oluşturun

### Commit Mesaj Formatı

- `feat:` Yeni özellik
- `fix:` Hata düzeltme
- `docs:` Dokümantasyon
- `style:` Kod formatı
- `refactor:` Kod yeniden yapılandırma
- `test:` Test ekleme/düzenleme
- `chore:` Build, CI, dependencies

## 📄 Lisans

Bu proje MIT Lisansı ile lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakabilirsiniz.

## 📞 İletişim

- **GitHub Issues**: [github.com/cloude33/Parion/issues](https://github.com/cloude33/Parion/issues)
- **E-posta**: Proje ile ilgili sorularınız için GitHub Issues kullanın

---

---

# 🇺🇸 Parion - Personal Finance App v1.0.12

Modern, comprehensive Flutter-based personal finance management application. Manage budgets, credit cards, overdraft accounts, investments, currency exchange, bills, subscriptions, goals, debts, and more from a single place.

## 🌟 About

**Parion** is a comprehensive and modern Flutter application designed to simplify personal finance management, track expenses, and help you reach financial freedom. With multi-user support, cloud synchronization, advanced analytics, and 60+ screens, it allows you to manage income, expenses, debts, investments, crypto, currency exchange, and more from a single place.

## ✨ Features

### 💳 Core Financial Management
- **Income/Expense Tracking**: 30+ predefined categories, custom categories, tag system.
- **Wallet Management**: Cash, bank, credit card, overdraft, investment accounts.
- **Multi-User Support**: Separate profile management for family members.
- **Guest Mode**: Quick use without registration.
- **Quick Transaction**: One-tap income/expense entry from home.

### 🏦 Overdraft Account (KMH)
- **Automatic Daily Interest Calculation**: Balance-based, precise math.
- **Smart Limit Alerts**: 80% and 95% thresholds.
- **Payment Planner**: Compare multiple plans side-by-side.
- **Comparison Screen**: Choose the best plan.
- **Interest Calculator**: Detailed scenario analysis.
- **Account Summary & Statement**: Date-based transaction history.
- **Reminders**: Push notifications for due dates.
- **Deposit/Withdraw**: Separate screens for quick operations.

### 💳 Credit Card Management
- **Statement Tracking**: Monthly statements, analysis, export.
- **Installment Management**: Installment purchases, deferred installments.
- **Cash Advance**: Quick cash advance and repayment plan.
- **Limit Controls**: Total usage, available limit, alerts.
- **Auto Statement Generation**: Periodic statement generation.
- **Notifications**: Statement cut and payment due reminders.
- **Reporting**: Monthly/yearly detailed reports.
- **Payment Simulation**: Different payment scenarios.

### 🪙 Investment & Crypto
- **Crypto Portfolio**: Real-time price tracking (CoinGecko).
- **Buy/Sell**: Purchase price, amount, date, notes.
- **Profit/Loss Analysis**: Real-time P&L.
- **Detailed View**: Per-investment performance.
- **Multi-Coin Support**: 10,000+ cryptocurrencies.

### 💱 Currency Exchange Rates
- **Real-time Tracking**: 35+ currencies (USD, EUR, GBP, JPY, etc.).
- **TRY Conversion**: "1 USD = 43.68 ₺" premium display.
- **Converter**: Two-way currency calculator.
- **Featured Cards**: USD, EUR, GBP highlighted.
- **Search/Filter**: Instant currency search.
- **Last Updated**: Timestamp for rates.
- **Currency Settings**: Default currency selection.

### 💸 Debt & Receivable
- **Debt/Receivable Tracking**: Money lent and borrowed.
- **Reminders**: Due date notifications.
- **Payment Plan**: Installment debt management.
- **Detail Screen**: Debt history and payment log.
- **Statistics**: Distribution and trend analysis.

### 📋 Budget Management
- **Monthly Budgets**: Category-based spending limits.
- **Budget Tracking**: Realized vs planned visualization.
- **Alerts**: Over-budget notifications.
- **Historical Analysis**: Month-over-month comparison.

### 🔄 Recurring Transactions
- **Automation**: Regular payments like rent, subscriptions, bills.
- **Flexible Frequency**: Daily, weekly, monthly, yearly.
- **Auto-Generation**: Automatic transaction creation.
- **Templates**: Frequent recurring transactions.
- **Statistics**: Recurring transaction analytics.

### 🧾 Bill Tracking
- **Extensive Provider Database**: 81 provinces, all sectors.
- **Smart Bill Entry**: Duplicate prevention.
- **Payment Status**: Paid/pending/late.
- **Detailed Statistics**: Bill-based analysis.
- **Templates**: Quick bill entry.

### 🎯 Goals
- **Savings Goals**: Specific purpose accumulation.
- **Progress Tracking**: Visual progress bars.
- **Target Date**: Time-bound planning.
- **Goal List**: Manage all goals from one place.

### 🎁 Reward Points
- **Credit Card Points**: Points earned from spending.
- **Points History**: Earnings and redemptions.
- **Points Reports**: Category-based analysis.

### 📊 Advanced Analytics & Reporting
- **Detailed Statistics**: Cash flow, expense distribution, category analysis.
- **Financial Health Score**: Smart 0-100 scoring.
- **Trend Analysis**: Spending habits and category changes.
- **Comparisons**: Last month vs this month, yearly.
- **Annual Report**: Year-end summary.
- **Background Statistics Service**: Auto-calculation.
- **Daily Summary**: Daily financial summary.
- **Multiple Report Formats**: Excel, PDF, CSV, QIF, OFX.

### 📲 Notifications
- **Local Notifications**: `flutter_local_notifications`.
- **Push Notifications (FCM)**: Firebase Cloud Messaging.
- **Smart Notifications**:
  - Bill due dates
  - Budget overruns
  - Overdraft limit alerts
  - Debt reminders
  - Recurring transaction alerts
- **Notification History**: View all notifications.
- **Notification Preferences**: Category-based toggles.
- **Timezone Support**: `timezone` for correct scheduling.

### 📸 OCR & Receipt Scanning
- **Auto Receipt Recognition**: `google_mlkit_text_recognition`.
- **Smart Category Suggestion**: Auto-categorize from amount/description.
- **Quick Transaction Creation**: One-tap receipt-to-transaction.
- **Gallery/Camera**: Multi-source support.

### ☁️ Backup & Sync
- **Google Drive Backup**: Automatic cloud backup.
- **Firebase Firestore Sync**: Cross-device sync.
- **Auto Backup**: Scheduled periodic backups.
- **Offline Sync**: Offline operation queue.
- **Import/Export**: Excel, PDF, CSV, QIF, OFX.
- **Backup History**: List and restore all backups.

### 🔐 Security
- **Multi-Factor Auth**:
  - Email/Password (Firebase Auth)
  - Google Sign-In (Native + Web)
  - Apple Sign-In (iOS)
- **Biometric Login**: Fingerprint and Face ID.
- **PIN Protection**: 4-6 digit in-app PIN.
- **App Lock**: Auto-lock on background.
- **Data Encryption**: Sensitive data encrypted with AES-256.
- **Secure Storage**: `flutter_secure_storage` (Keystore/Keychain).
- **Session Management**: Session timeout, auto-logout.
- **Security Event Log**: All security events logged.
- **Error Logging**: Detailed error reporting.

### 🎨 User Experience
- **Light/Dark Theme**: Auto or manual.
- **Multi-Language**: Turkish (default) and English.
- **Onboarding**: Guided intro on first launch.
- **Help Screen**: FAQ and user guide.
- **About Screen**: Version info and license.
- **Modern UI**: Material 3, gradients, animations.
- **Premium Screens**: Special design for rates, dashboard.
- **Pull-to-Refresh**: All lists.
- **Pagination**: Performance optimization.
- **Image Cache**: Fast loading with `cache_service`.
- **Performance Monitor**: Frame timing, memory tracking.
- **Image Optimization**: Auto compression.

### 🔋 Device Integration
- **Battery Optimization Exemption**: Native handler for OnePlus HANS.
- **Connectivity Check**: Online/offline state tracking.
- **Permission Management**: Storage, camera, notifications.
- **App Lifecycle**: Foreground/background state tracking.
- **Sharing**: Share transactions and reports.

### 📅 Planning & Organization
- **Calendar View**: All transactions on calendar.
- **All Transactions**: Date and category filters.
- **Smart Category Service**: Auto-categorize from description.
- **Tag System**: Organize transactions with tags.
- **Transaction Filtering**: Advanced filtering service.

### 🏗️ Software Architecture
- **Dependency Injection**: `get_it` service locator.
- **Modern DI Pattern**: Lazy init, singleton management.
- **Hive**: Local database (10+ box types).
- **Firebase**: Auth, Firestore, Storage, Analytics, Messaging.
- **REST API**: HTTP-based 3rd party API integration.
- **State Management**: Provider + Service Layer pattern.
- **Error Handling**: Centralized error catching and logging.
- **Background Services**: Lock, statistics, KMH.

## 🚀 Installation

### Requirements
- **Flutter SDK**: 3.10.0+
- **Dart SDK**: 3.10.0+
- **Android Studio** or **Xcode** (Mac required for iOS)
- **VS Code** or preferred IDE
- **Git**

### Steps

1. **Clone the project:**
```bash
git clone https://github.com/cloude33/Parion.git
cd Parion
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Firebase Configuration:**
```bash
# Install FlutterFire CLI (once)
dart pub global activate flutterfire_cli

# Generate Firebase configuration
flutterfire configure --project=YOUR_PROJECT_ID
```

4. **Android extras:**
   - Ensure `android/app/google-services.json` is in place.
   - Create `android/key.properties` for release builds.

5. **iOS extras:**
   - Add `ios/Runner/GoogleService-Info.plist`.
   - Run `cd ios && pod install`

## ⚙️ Configuration

### Firebase Project
- Create new project in Firebase Console
- Enable **Email/Password** and **Google** in Authentication > Sign-in method
- Add Android, iOS, Web apps
- Run `flutterfire configure`

### Exchange Rate API
Configured in `lib/services/exchange_rate_service.dart`:
- Default: `https://open.er-api.com/v6/latest/TRY` (free, no key)
- Alternatives: ExchangeRate-API, Frankfurter, etc.

### Crypto Prices (CoinGecko)
`lib/services/investment_service.dart`:
- Endpoint: CoinGecko public API
- No API key required (free tier sufficient)

## 🏃 Run

```bash
# Development - Android
flutter run -d android

# Development - iOS (Mac required)
flutter run -d ios

# Development - Web (Chrome)
flutter run -d chrome

# Hot reload: r (in terminal)
# Hot restart: R (in terminal)
```

## 🧪 Test

```bash
# Run all tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Lint & Analyze

```bash
flutter analyze
dart format --set-exit-if-changed lib/
dart format lib/
```

## 📦 Build

### Android

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
flutter build apk --release --split-per-abi
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.10+
- **Language**: Dart 3.10+
- **UI**: Material 3, Custom gradients, fl_chart

### State & DI
- **DI**: `get_it` (Service Locator)
- **State**: Provider + ChangeNotifier

### Backend & DB
- **Auth**: Firebase Auth (Email/Google/Apple)
- **Cloud DB**: Cloud Firestore
- **Storage**: Firebase Storage
- **Local DB**: Hive (10+ boxes)
- **Push**: Firebase Cloud Messaging

### 3rd Party APIs
- **Exchange**: open.er-api.com
- **Crypto**: CoinGecko
- **Google Drive Backup**: googleapis

### Security
- **Encryption**: AES-256
- **Storage**: `flutter_secure_storage`
- **Biometric**: `local_auth`

### Other
- **Charts**: fl_chart
- **Notifications**: flutter_local_notifications + timezone
- **OCR**: google_mlkit_text_recognition
- **Icons**: font_awesome_flutter, line_icons, lucide_icons_flutter
- **Reporting**: excel, pdf, csv, archive
- **Import/Export**: qif, ofx
- **Images**: image_picker, image_cropper, image
- **Performance**: cache_service, performance_monitor, pagination_service

## ⚠️ Known Limitations

- **OnePlus Devices**: OnePlus HANS can aggressively freeze the app. Enable **Settings > Battery > Battery optimization > Parion > Don't optimize** (app requests this automatically).
- **Web Platform**: Google Sign-In on Web requires OAuth Client ID configuration. For Email/Password, add `localhost` as authorized domain in Firebase Console.
- **iOS**: Cannot build without macOS.

## 🗺️ Roadmap

- [ ] AI-powered expense prediction
- [ ] Budget recommendations
- [ ] Investment portfolio analysis
- [ ] Voice command transaction entry
- [ ] Home screen widget
- [ ] Apple Watch / Wear OS app
- [ ] Shared accounts (family, partners)
- [ ] More languages (German, Arabic, etc.)
- [ ] e-Invoice integration

## 🤝 Contribution

Contributions welcome!

1. **Fork** the repo
2. Create your feature branch:
   ```bash
   git checkout -b feature/NewFeature
   ```
3. Commit your changes:
   ```bash
   git commit -m 'feat: Add new feature'
   ```
4. Push to the branch:
   ```bash
   git push origin feature/NewFeature
   ```
5. Open a **Pull Request**

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) file.

## 📞 Contact

- **GitHub Issues**: [github.com/cloude33/Parion/issues](https://github.com/cloude33/Parion/issues)

---

⭐ Don't forget to star **Parion** if you like it!
