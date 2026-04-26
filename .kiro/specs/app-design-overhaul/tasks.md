# Uygulama Planı: Parion Uygulama Tasarım Yenilemesi

## Genel Bakış

Bu plan, Parion uygulamasının tasarım yenilemesini kademeli (incremental) adımlarla hayata geçirir. Önce Design System token'ları ve Component Library oluşturulur, ardından navigasyon ve ekranlar güncellenir. Her adım bir öncekinin üzerine inşa edilir; hiçbir kod yalnız bırakılmaz.

## Görevler

- [x] 1. Design System — Renk, Tipografi ve Spacing Token'ları
  - `lib/core/design/` dizinini oluştur
  - `app_colors.dart` dosyasını oluştur: light ve dark tema için tüm `AppColors` static const token'larını tanımla (`primary`, `primaryVariant`, `secondary`, `background`, `surface`, `onPrimary`, `onSurface`, `error`, `success`, `warning`, `incomeColor`, `expenseColor` ve dark karşılıkları)
  - `app_text_styles.dart` dosyasını oluştur: `AppTextStyles` sınıfını tüm tipografi rolleriyle tanımla (`displayLarge`…`labelSmall`)
  - `app_spacing.dart` dosyasını oluştur: `AppSpacing` sınıfını 4px tabanlı tüm sabitlerle tanımla (`xs`=4, `sm`=8, `md`=12, `lg`=16, `xl`=20, `xxl`=24, `xxxl`=32, `huge`=48)
  - `app_theme.dart` dosyasını oluştur: `AppTheme` sınıfını `lightTheme()` ve `darkTheme()` factory metodlarıyla tanımla; mevcut `ThemeService`'i wrap et
  - _Gereksinimler: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3_

  - [x] 1.1 AppSpacing 4px tabanlılık özellik testi yaz
    - **Özellik 2: AppSpacing değerleri 4px tabanlıdır**
    - `test/core/design/app_spacing_test.dart` dosyasını oluştur; `glados` paketi ile tüm `AppSpacing` sabitlerinin `value % 4 == 0` koşulunu sağladığını doğrula
    - **Doğrular: Gereksinim 2.3**

- [x] 2. Component Library — Temel Widget'lar
  - `lib/widgets/common/` dizinini oluştur
  - `app_card.dart`: `AppCard` widget'ını `child`, `padding`, `onTap`, `color` parametreleriyle oluştur; padding, border radius ve gölge değerlerini `AppSpacing` ve `AppColors` token'larından al
  - `app_button.dart`: `AppButton` widget'ını `primary`, `secondary`, `text` varyantlarıyla oluştur; `label`, `onPressed`, `variant`, `icon`, `isLoading` parametrelerini destekle; `onPressed` null olduğunda buton devre dışı görünsün; minimum 44x44px dokunma hedefi sağla
  - `app_text_field.dart`: `AppTextField` widget'ını `label`, `hint`, `controller`, `validator`, `keyboardType`, `obscureText` parametreleriyle oluştur; `validator` hata döndürdüğünde hata mesajını görünür yap
  - `section_header.dart`: `SectionHeader` widget'ını `title`, `actionLabel`, `onAction` parametreleriyle oluştur
  - `amount_display.dart`: `AmountDisplay` widget'ını `amount`, `isIncome`, `style`, `showSign` parametreleriyle oluştur; `isIncome == true` → `AppColors.incomeColor`, `isIncome == false` → `AppColors.expenseColor` kullan
  - `app_page_scaffold.dart`: `AppPageScaffold` widget'ını `title`, `body`, `showBackButton`, `actions`, `floatingActionButton`, `bottomNavigationBar` parametreleriyle oluştur
  - _Gereksinimler: 3.1, 3.2, 3.3, 3.4, 3.5, 9.1, 9.2, 10.1_

  - [x] 2.1 AmountDisplay renk tutarlılığı özellik testi yaz
    - **Özellik 1: AmountDisplay renk tutarlılığı**
    - `test/widgets/common/amount_display_test.dart` dosyasını oluştur; `glados` paketi ile rastgele `double` ve `bool` değerleri üretilerek `isIncome` bayrağına göre doğru renk token'ının kullanıldığını doğrula
    - **Doğrular: Gereksinim 3.5**

  - [x] 2.2 AppTextField doğrulama tutarlılığı özellik testi yaz
    - **Özellik 5: AppTextField doğrulama tutarlılığı**
    - `test/widgets/common/app_text_field_test.dart` dosyasını oluştur; `glados` paketi ile rastgele geçersiz giriş değerleri üretilerek validator hata döndürdüğünde widget'ın hata durumunu görsel olarak yansıttığını doğrula
    - **Doğrular: Gereksinim 3.3**

  - [x] 2.3 AppButton ve AppCard dokunma hedefi özellik testi yaz
    - **Özellik 7: Dokunma hedefi minimum boyutu**
    - `test/widgets/common/touch_target_test.dart` dosyasını oluştur; `glados` paketi ile rastgele boyutlarda render edilen `AppButton` ve `onTap` parametreli `AppCard` widget'larının her zaman minimum 44x44px dokunma hedefine sahip olduğunu doğrula
    - **Doğrular: Gereksinim 10.1**

- [x] 3. Component Library — Durum Widget'ları
  - `app_empty_state.dart`: `AppEmptyState` widget'ını `icon`, `title`, `description`, `actionLabel`, `onAction` parametreleriyle oluştur; `onAction` null olduğunda aksiyon butonu gösterilmesin; renkleri `Theme.of(context)` token'larından al
  - `app_error_state.dart`: `AppErrorState` widget'ını `message`, `onRetry` parametreleriyle oluştur; `onRetry` null olduğunda "Tekrar Dene" butonu gösterilmesin; renkleri `Theme.of(context)` token'larından al
  - `app_loading_state.dart`: `AppLoadingState` widget'ını `itemCount`, `itemHeight` parametreleriyle oluştur; `shimmer` paketi ile skeleton animasyonu uygula; paket bulunamazsa `CircularProgressIndicator` fallback'i kullan; renkleri `Theme.of(context)` token'larından al
  - _Gereksinimler: 4.1, 4.2, 4.3, 4.7, 8.2, 10.2_

  - [x] 3.1 Durum widget'ları tema uyumu özellik testi yaz
    - **Özellik 3: Durum widget'ları tema uyumu**
    - `test/widgets/common/state_widgets_theme_test.dart` dosyasını oluştur; `glados` paketi ile light ve dark `ThemeData` ile `AppEmptyState`, `AppErrorState`, `AppLoadingState` widget'larının hardcoded renk yerine `Theme.of(context)` token'larını kullandığını doğrula
    - **Doğrular: Gereksinim 4.7, 8.2**

  - [x] 3.2 Ekran durum yönetimi tutarlılığı özellik testi yaz
    - **Özellik 6: Ekran durum yönetimi tutarlılığı**
    - `test/widgets/common/screen_state_test.dart` dosyasını oluştur; `glados` paketi ile rastgele ekran durumu (loading/empty/error) verildiğinde yalnızca ilgili durum widget'ının widget ağacında bulunduğunu, diğer ikisinin bulunmadığını doğrula
    - **Doğrular: Gereksinim 4.4, 4.5, 4.6**

- [x] 4. Kontrol Noktası — Tüm testlerin geçtiğinden emin ol
  - Tüm testlerin geçtiğinden emin ol; sorular varsa kullanıcıya sor.

- [x] 5. Onboarding Servisi ve Akışı
  - `lib/services/onboarding_service.dart` dosyasını oluştur: `OnboardingService` sınıfını `isOnboardingCompleted()` ve `markOnboardingCompleted()` metodlarıyla oluştur; `SharedPreferences` ile `'onboarding_completed'` anahtarını kullan; `SharedPreferences` erişim hatası durumunda `false` döndür (güvenli varsayılan)
  - `lib/screens/onboarding/onboarding_page.dart` dosyasını oluştur: tek bir onboarding sayfasını temsil eden widget'ı oluştur; `AppColors`, `AppTextStyles`, `AppSpacing` token'larını kullan
  - `lib/screens/onboarding/onboarding_screen.dart` dosyasını oluştur: 3 adımlı `PageView` tabanlı onboarding akışını oluştur (1. Karşılama, 2. Özellik tanıtımı, 3. İlk kurulum); "Atla" butonu ile doğrudan Dashboard'a yönlendir; tamamlandığında `markOnboardingCompleted()` çağır; `AppButton`, `AppPageScaffold` ve diğer Component Library widget'larını kullan
  - _Gereksinimler: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

  - [x] 5.1 Onboarding tamamlanma kalıcılığı özellik testi yaz
    - **Özellik 4: Onboarding tamamlanma kalıcılığı (round-trip)**
    - `test/services/onboarding_service_test.dart` dosyasını oluştur; `glados` paketi ile `markOnboardingCompleted()` çağrıldıktan sonra `isOnboardingCompleted()` her zaman `true` döndürdüğünü doğrula; mock `SharedPreferences` kullan
    - **Doğrular: Gereksinim 7.1, 7.4**

- [x] 6. 5 Tab'lı Bottom Navigation
  - `lib/widgets/common/app_bottom_nav_bar.dart` dosyasını oluştur: 5 tab'lı `BottomNavigationBar` widget'ını oluştur (Ana Sayfa, Kredi Kartı, KMH, İstatistik, Ayarlar); `LucideIcons` kullan; aktif tab'ı `AppColors.primary` ile vurgula; light/dark temada doğru arka plan rengini `Theme.of(context)` üzerinden al
  - `lib/screens/home_screen.dart` dosyasını güncelle: mevcut `CustomBottomNavBar`'ı yeni `AppBottomNavBar` ile değiştir; `IndexedStack` kullanarak 5 ekranı yönet (`DashboardScreen`, `CreditCardListScreen`, `KmhListScreen`, `StatisticsScreen`, `SettingsScreen`); tab geçişlerinde gereksiz rebuild'leri önle
  - _Gereksinimler: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 10.3_

- [x] 7. Dashboard Ekranı Yeniden Tasarımı
  - `lib/screens/dashboard_screen.dart` dosyasını oluştur: mevcut `HomeScreen`'deki dashboard içeriğini bu yeni widget'a taşı ve yeniden tasarla
  - Üst kısım: kullanıcı adı + selamlama mesajı
  - Net Bakiye kartı: `AppCard` + `AmountDisplay` kullan
  - "Bu Ay" bölümü: toplam gelir ve gider yan yana `AppCard` + `AmountDisplay` ile göster
  - Kredi Kartı Borcu ve KMH Değeri metrikleri: `AppCard` + `AmountDisplay` kullan
  - Son 5 İşlem listesi: `SectionHeader` + işlem kartları; `ListView.builder` ile lazy loading uygula
  - Loading state: `AppLoadingState` göster
  - Empty state: `AppEmptyState` ile kullanıcıyı cüzdan eklemeye yönlendir
  - Error state: `AppErrorState` göster; "Tekrar Dene" butonu `_loadData()` metodunu tetiklesin
  - `RefreshIndicator` ile pull-to-refresh desteği ekle
  - Tüm renk ve stil değerlerini `AppColors`, `AppTextStyles`, `AppSpacing` token'larından al
  - _Gereksinimler: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 4.4, 4.5, 4.6, 10.4_

- [x] 8. AppTheme'i ThemeService ile Entegre Et ve main.dart'ı Güncelle
  - `lib/core/design/app_theme.dart` dosyasını mevcut `ThemeService` ile entegre et: `AppTheme.lightTheme()` ve `AppTheme.darkTheme()` metodlarını `ThemeService`'in mevcut tema yönetimiyle bağla
  - `lib/main.dart` dosyasını güncelle: `_getInitialScreen()` metodunu onboarding durumunu kontrol edecek şekilde güncelle; `OnboardingService.isOnboardingCompleted()` false ise `OnboardingScreen`, true ise `HomeScreen` döndür; `AppTheme.lightTheme()` ve `AppTheme.darkTheme()` metodlarını `MaterialApp`'e bağla
  - _Gereksinimler: 1.3, 1.4, 7.1, 8.1, 8.4_

- [x] 9. Kontrol Noktası — Tüm testlerin geçtiğinden emin ol
  - Tüm testlerin geçtiğinden emin ol; sorular varsa kullanıcıya sor.

## Notlar

- `*` ile işaretli görevler isteğe bağlıdır; daha hızlı MVP için atlanabilir
- Her görev, izlenebilirlik için ilgili gereksinimlere referans verir
- Özellik tabanlı testler `glados` paketi ile yazılır; her test minimum 100 iterasyon çalıştırılır
- Birim testleri belirli örnekleri ve kenar durumları doğrular; özellik testleri evrensel doğruluk özelliklerini doğrular
- Kontrol noktaları kademeli doğrulama sağlar
