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
⭐ **Parion**'u beğendiyseniz yıldız vermeyi unutmayın!
