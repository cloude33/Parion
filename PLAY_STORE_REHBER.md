# Parion — Google Play Store Yükleme Rehberi

## 1. Hesap ve mağaza girişi
1. https://play.google.com/console adresine gir, geliştirici hesabı aç (tek seferlik 25$).
2. **Tüm uygulamalar → Uygulama oluştur**:
   - Uygulama adı: **Parion**
   - Varsayılan dil: **Türkçe**
   - Uygulama veya oyun: **Uygulama**
   - Ücretsiz veya ücretli: **Ücretsiz**
3. Mağaza girişindeki beyanları tamamla (KVKK, politikalar, geliştirici e-posta).

## 2. App Signing (uygulama imzalama)
**Kurulum → Uygulama bütünlüğü** sayfasında "App Signing by Google Play" otomatik aktiftir. "İmzalama anahtarı yükle" adımında:

- **Upload key sertifikası** olarak `android\upload_certificate.pem` dosyasını yükle.
- Play Console zaten bizim keystore'dan üretilen SHA-256 parmak izini doğrulayacak (`A8:23:36:08:…0C`).
- Google bir **App Signing Key** üretecek (cihazlara dağıtılan gerçek imza). Bu otomatik.

> Yeni sürüm güncellemesi için her zaman aynı `upload-keystore.jks` ile imzalanmış AAB yükle.

## 3. Veri güvenliği (zorunlu)
**Politika → Veri güvenliği**:
- **Veri toplama**: Evet (kişisel bilgiler, finansal bilgiler, cihaz kimliği, e-posta).
- **Toplanan veri türleri**:
  - Kişisel bilgiler: e-posta adresi, ad-soyad
  - Finansal bilgiler: işlemler, hesaplar, kredi kartı
  - Uygulama bilgileri: kilitlenme raporları (Firebase Crashlytics)
- **Veri paylaşımı**: Üçüncü taraflarla paylaşım **hayır**.
- **Veri silme talebi**: Uygulama içi hesap silme özelliği mevcut.
- **Şifreleme**: Tüm veriler HTTPS üzerinden aktarılır.
- **Gizlilik politikası URL**'si zorunlu — ücretsiz barındırma: GitHub Pages veya Notion.

## 4. Mağaza girişi (Store listing)
**Mağaza girişi → Ana mağaza girişi**:

| Alan | Değer |
|------|-------|
| Uygulama adı | Parion |
| Kısa açıklama (80) | "Gelir, gider, denge — kişisel bütçeni tek ekrandan yönet" |
| Tam açıklama (4000) | Aşağıda |
| Uygulama ikonu | 512×512 PNG (şu an `mipmap-xxxhdpi/ic_launcher.png` 192px — 512'ye büyüt) |
| Feature graphic | 1024×500 PNG (yoksa oluştur) |
| Ekran görüntüleri | Telefon için en az 2, ideal 4-8 (var olan `design_*.png`'ler kullanılabilir) |

### Tam açıklama taslağı
```
Parion, gelir ve giderlerini takip etmenin en sade yolu.

✓ Tek ekranda güncel bakiye
✓ Truncgil Finans'tan anlık altın, döviz, ons
✓ Kredi kartı ve nakit ayrımı
✓ Fatura okutma (OCR)
✓ Aile Paketi — hesapları birlikte yönet, harcamaları paylaş
✓ Hedefler — birikim amaçları koy, ilerleme takip et
✓ Türkçe ve İngilizce
✓ Tüm veriler Firebase'de güvenle saklanır

Gider ekle → grafikleri incele → kapat. Arka planda seni takip etmez.
```

## 5. İçerik derecelendirmesi
**Politika → İçerik derecelendirmesi** anketini doldur:
- Kategori: **Diğer / Finans** (Para/Finans sorularına "Hayır")
- Şiddet, cinsellik, dil, uyuşturucu: Hepsi **Hayır**
- Sonuç: Genelde **3+** çıkar (zararsız).

## 6. Hedef kitle
**Hedef kitle ve içerik**:
- Hedef yaş grubu: **13+**
- Reklam: **Yok** (Firebase Analytics raporlama için pasif, kullanıcıya reklam göstermez)
- Kullanıcı etkileşimi: **Yok** (sosyal/sohbet yok)

## 7. Üretim (Production) yüklemesi
**Yayınla → Üretim → Yeni sürüm oluştur**:
1. **Android App Bundle**: `build\app\outputs\bundle\release\app-release.aab` (97.1 MB) sürükle-bırak.
2. Sürüm adı otomatik gelir: **1.0.13** (versionCode 13).
3. Sürüm notları (Türkçe):
   ```
   - Truncgil Finans API ile serbest piyasa kurları
   - Hafta sonu piyasa kapalı bilgilendirmesi
   - Daha kompakt ve responsive fiyat bar
   - Aile Paketi geliştirmeleri
   ```
4. **İncelemeye gönder**.

## 8. Önemli dosyalar
| Dosya | Yol | Açıklama |
|-------|-----|----------|
| AAB | `build\app\outputs\bundle\release\app-release.aab` | Play Console'a yüklenecek |
| Keystore | `android\upload-keystore.jks` | Tüm gelecek sürümler aynı keystore ile imzalanmalı |
| Upload cert | `android\upload_certificate.pem` | App Signing kurulumunda yüklenecek |
| Şifre | `app12345` (hem store hem key) | Güvenli yere kaydet (password manager) |

## 9. Kontrol listesi (yüklemeden önce)
- [ ] AAB versiyonu: 1.0.13+13 ✅
- [ ] `flutter analyze`: 0 hata ✅
- [ ] Arka plan diyaloğu kaldırıldı (manifest temizlendi) ✅
- [ ] Release keystore: SHA-256 `A8:23:36:08:…0C` ✅
- [ ] Cihazda son test ✅
- [ ] 512×512 uygulama ikonu hazır
- [ ] 1024×500 feature graphic hazır
- [ ] 4+ telefon ekran görüntüsü
- [ ] Gizlilik politikası URL'si

## 10. Sık karşılaşılan red gerekçeleri
- **Gizlilik politikası eksik** → GitHub Pages veya Notion'da ücretsiz barındır
- **Veri güvenliği formu eksik** → Tüm bölümleri "Evet/Hayır" doldur
- **Uygulama ikonu 512×512 değil** → Photoshop veya online resize ile çevir
- **Hedef API çok eski** → `targetSdk = flutter.targetSdkVersion` (`flutter.target` → 34/35 olmalı)
- **Yeni geliştirici hesabı** → ilk yükleme 3-7 gün sürebilir
