# 💰 Parion - Kişisel Finans Uygulaması v1.0

Modern Flutter tabanlı kişisel bütçe, kredi kartı, fatura takip ve finansal analiz uygulaması.

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)](https://github.com/cloude33/Parion/releases/latest)

## 🌟 Hakkında

**Parion**, kişisel finans yönetimini kolaylaştırmak, harcamaları takip etmek ve finansal özgürlüğünüze ulaşmanıza yardımcı olmak için tasarlanmış kapsamlı ve kullanıcı dostu bir uygulamadır. Modern arayüzü, güçlü analiz araçları ve gelişmiş özellikleriyle gelir, gider, borç ve yatırımlarınızı tek bir yerden yönetmenizi sağlar.

## ✨ Özellikler

### 💳 Finansal Yönetim
- **Gelir/Gider Takibi**: Tüm finansal işlemlerinizi detaylı kategorilerle kaydedin.
- **Cüzdan Yönetimi**: Nakit, banka hesapları, kredi kartları ve diğer varlıklarınızı yönetin.
- **KMH (Kredili Mevduat Hesabı) Yönetimi**: 
  - Kredili hesaplarınızı, limitlerinizi ve faizlerinizi takip edin.
  - Otomatik günlük faiz hesaplama ve akıllı limit uyarıları (%80 ve %95).
  - Ödeme planları oluşturma ve karşılaştırma.
- **Kredi Kartı Yönetimi**: Ekstre takibi, taksit yönetimi, limit kontrolleri.
- **Borç/Alacak Takibi**: Ödeme ve tahsilatlarınızı hatırlatıcılarla organize edin.
- **Fatura Takibi**: 
  - Geniş servis sağlayıcı veritabanı (81 İl, tüm sektörler).
  - Akıllı fatura girişi ve düzenli takip.
  - Detaylı fatura istatistikleri ve ödeme durumu takibi.
- **Taksit Sistemi**: Taksitli alışverişlerinizi ve gelecek ödemelerinizi planlayın.

### 🔄 Otomasyon ve Akıllı Özellikler
- **Tekrarlayan İşlemler**: Kira, abonelikler gibi düzenli ödemeleri otomatikleştirin.
- **Akıllı Bildirimler**: Fatura son ödeme tarihleri, bütçe aşımları ve KMH limit uyarıları.
- **Yedekleme**: Firebase destekli güvenli bulut yedekleme ve cihazlar arası senkronizasyon.

### 📊 Gelişmiş Analiz ve Raporlama
- **Detaylı İstatistikler**: Nakit akışı, harcama dağılımı, net varlık değişimi.
- **Finansal Sağlık Skoru**: Finansal durumunuzu özetleyen akıllı skorlama sistemi.
- **Trend Analizi**: Harcama alışkanlıklarınızı ve kategorisel değişimleri inceleyin.
- **Karşılaştırmalar**: Dönemsel karşılaştırmalar (Geçen Ay vs Bu Ay).
- **Raporlar**: Excel, PDF ve CSV formatında detaylı finansal raporlar.

### 🔒 Güvenlik
- **Biyometrik Giriş**: Parmak izi ve yüz tanıma desteği.
- **PIN Koruması**: Uygulama içi ekstra güvenlik katmanı.
- **Veri Şifreleme**: Hassas verileriniz AES-256 ile şifrelenerek saklanır.
- **Gizlilik**: Verileriniz sizin kontrolünüzdedir.

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK (3.10.0 veya üzeri)
- Dart SDK
- Android Studio / VS Code

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

3. **Uygulamayı Çalıştırın:**
```bash
# Android için
flutter run -d android

# iOS için (Mac gerektirir)
flutter run -d ios
```

## 🛠️ Teknoloji Yığını
- **Core**: Flutter & Dart
- **State Management**: Provider / Riverpod (veya kullandığınız yapı)
- **Database**: Hive (Yerel), Firebase (Bulut)
- **Charts**: fl_chart
- **Auth**: Firebase Auth & Local Auth

## 🤝 Katkıda Bulunma
Katkılarınızı bekliyoruz! Lütfen bir "Pull Request" göndermeden önce mevcut sorunları kontrol edin veya yeni bir özellik önerisi için konu açın.

1. Forklayın
2. Feature branch oluşturun (`git checkout -b feature/YeniOzellik`)
3. Değişikliklerinizi commit edin (`git commit -m 'Yeni özellik eklendi'`)
4. Branch'inizi push edin (`git push origin feature/YeniOzellik`)
5. Pull Request oluşturun

## 📄 Lisans
Bu proje MIT Lisansı ile lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakabilirsiniz.

## 📞 İletişim
Proje ile ilgili sorularınız veya önerileriniz için GitHub Issues üzerinden iletişime geçebilirsiniz.

---

---

# 🇺🇸 Parion - Personal Finance App v1.0

Modern Flutter-based personal budget, credit card, bill tracking, and financial analysis application.

## 🌟 About

**Parion** is a comprehensive and user-friendly application designed to simplify personal finance management, track expenses, and help you reach financial freedom. With its modern interface, powerful analysis tools, and advanced features, it allows you to manage your income, expenses, debts, and investments from a single place.

## ✨ Features

### 💳 Financial Management
- **Income/Expense Tracking**: Record all financial transactions with detailed categories.
- **Wallet Management**: Manage cash, bank accounts, credit cards, and other assets.
- **Overdraft Account (KMH) Management**:
  - Track overdraft accounts, limits, and interest rates.
  - Automatic daily interest calculation and smart limit alerts (at 80% and 95%).
  - Create and compare payment plans.
- **Credit Card Management**: Statement tracking, installment management, limit checks.
- **Debt/Receivable Tracking**: Organize payments and collections with reminders.
- **Bill Tracking**:
  - Extensive service provider database (81 Provinces, all sectors).
  - Smart bill entry and regular tracking.
  - Detailed bill statistics and payment status tracking.
- **Installment System**: Plan installment purchases and future payments.

### 🔄 Automation and Smart Features
- **Recurring Transactions**: Automate regular payments like rent and subscriptions.
- **Smart Notifications**: Due date reminders, budget overruns, and overdraft limit alerts.
- **Backup**: Firebase-backed secure cloud backup and cross-device synchronization.

### 📊 Advanced Analytics and Reporting
- **Detailed Statistics**: Cash flow, expense distribution, net worth change.
- **Financial Health Score**: Smart scoring system summarizing your financial status.
- **Trend Analysis**: Examine spending habits and categorical changes.
- **Comparisons**: Periodical comparisons (Last Month vs This Month).
- **Reports**: Detailed financial reports in Excel, PDF, and CSV formats.

### 🔒 Security
- **Biometric Login**: Fingerprint and Face ID support.
- **PIN Protection**: Extra in-app security layer.
- **Data Encryption**: Your sensitive data is stored encrypted with AES-256.
- **Privacy**: Your data is under your control.

## 🚀 Installation

### Requirements
- Flutter SDK (3.10.0 or higher)
- Dart SDK
- Android Studio / VS Code

### Installation Steps

1. **Clone the Project:**
```bash
git clone https://github.com/cloude33/Parion.git
cd Parion
```

2. **Install Dependencies:**
```bash
flutter pub get
```

3. **Run the Application:**
```bash
# For Android
flutter run -d android

# For iOS (Requires Mac)
flutter run -d ios
```

## 🛠️ Tech Stack
- **Core**: Flutter & Dart
- **State Management**: Provider / Riverpod
- **Database**: Hive (Local), Firebase (Cloud)
- **Charts**: fl_chart
- **Auth**: Firebase Auth & Local Auth

## 🤝 Contribution
Contributions are welcome! Please check existing issues before sending a "Pull Request" or open a topic for a new feature suggestion.

1. Fork it
2. Create your feature branch (`git checkout -b feature/NewFeature`)
3. Commit your changes (`git commit -m 'Added new feature'`)
4. Push to the branch (`git push origin feature/NewFeature`)
5. Create a Pull Request

## 📄 License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 📞 Contact
For questions or suggestions regarding the project, you can contact us via GitHub Issues.

---
⭐ Don't forget to star **Parion** if you like it!
