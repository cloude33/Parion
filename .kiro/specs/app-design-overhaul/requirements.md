# Gereksinimler Belgesi

## Giriş

Bu belge, Parion kişisel finans uygulamasının kapsamlı tasarım yenilemesini (design overhaul) tanımlar. Uygulama; kişisel bütçe yönetimi, kredi kartı takibi ve KMH (Kredili Mevduat Hesabı) taksit takibi modüllerini barındırmaktadır. Mevcut yapıda 70+ ekran, 60+ servis ve 60+ model bulunmaktadır. Tasarım yenilemesinin amacı; tutarlı bir design system kurmak, modern/vibrant bir renk paleti oluşturmak, navigasyonu iyileştirmek, tüm ekranlarda tutarlı durum yönetimi sağlamak ve yeni kullanıcılar için onboarding akışı eklemektir.

## Sözlük

- **Design_System**: Uygulamanın tüm ekranlarında kullanılan renk token'ları, tipografi ölçeği, spacing sistemi ve yeniden kullanılabilir widget'lardan oluşan merkezi tasarım altyapısı.
- **App_Theme**: Flutter `ThemeData` tabanlı, light ve dark modları destekleyen tema yapılandırması.
- **Color_Token**: Renk paletindeki her rengin semantik bir isimle tanımlandığı sabit değer (örn. `primaryColor`, `surfaceColor`).
- **Component_Library**: Uygulamada tekrar eden UI parçalarının (kart, buton, boş durum, hata durumu, yükleme durumu) merkezi widget koleksiyonu.
- **Bottom_Nav**: Uygulamanın ana navigasyon çubuğu (5 tab: Ana Sayfa, Kredi Kartı, KMH, İstatistik, Ayarlar).
- **Dashboard**: Kullanıcının finansal durumunu tek bakışta görebildiği ana ekran.
- **Empty_State_Widget**: Veri olmadığında gösterilen, kullanıcıyı yönlendiren widget.
- **Error_State_Widget**: Hata oluştuğunda gösterilen, yeniden deneme seçeneği sunan widget.
- **Loading_State_Widget**: Veri yüklenirken gösterilen animasyonlu widget.
- **Onboarding_Flow**: Yeni kullanıcının uygulamayı ilk açışında karşılaştığı yönlendirici adım dizisi.
- **Spacing_Scale**: 4px tabanlı tutarlı boşluk sistemi (4, 8, 12, 16, 20, 24, 32, 48px).
- **Typography_Scale**: Uygulamada kullanılan font boyutu ve ağırlık hiyerarşisi.

---

## Gereksinimler

### Gereksinim 1: Design System — Renk Paleti ve Token'lar

**Kullanıcı Hikayesi:** Bir geliştirici olarak, tüm ekranlarda tutarlı renkler kullanmak istiyorum; böylece uygulamanın görsel kimliği bütünlüklü ve profesyonel görünür.

#### Kabul Kriterleri

1. THE Design_System SHALL `AppColors` adlı merkezi bir sınıfta tüm Color_Token'ları tanımlamalıdır.
2. THE Design_System SHALL en az şu semantik token'ları içermelidir: `primary`, `primaryVariant`, `secondary`, `background`, `surface`, `onPrimary`, `onSurface`, `error`, `success`, `warning`, `incomeColor`, `expenseColor`.
3. THE App_Theme SHALL light modda modern/vibrant bir palet kullanmalıdır; scaffold arka planı, bottom nav ve FAB renkleri aynı `primary` token'ından türetilmelidir.
4. THE App_Theme SHALL dark modda tüm Color_Token'ların karanlık tema karşılıklarını içermelidir.
5. WHEN bir ekranda renk kullanılması gerektiğinde, THE ekran SHALL hardcoded hex değeri yerine `AppColors` token'larını kullanmalıdır.
6. IF bir ekranda `Color(0xFF...)` şeklinde hardcoded renk tespit edilirse, THEN THE Design_System SHALL bu rengi ilgili token ile değiştirmelidir.

---

### Gereksinim 2: Design System — Tipografi ve Spacing

**Kullanıcı Hikayesi:** Bir geliştirici olarak, tüm ekranlarda aynı font boyutlarını ve boşluk değerlerini kullanmak istiyorum; böylece ekranlar arasında görsel tutarlılık sağlanır.

#### Kabul Kriterleri

1. THE Design_System SHALL `AppTextStyles` adlı merkezi bir sınıfta tipografi ölçeğini tanımlamalıdır.
2. THE Design_System SHALL en az şu tipografi rollerini içermelidir: `displayLarge`, `displayMedium`, `headlineLarge`, `headlineMedium`, `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelSmall`.
3. THE Design_System SHALL `AppSpacing` adlı merkezi bir sınıfta 4px tabanlı Spacing_Scale değerlerini tanımlamalıdır: `xs` (4), `sm` (8), `md` (12), `lg` (16), `xl` (20), `xxl` (24), `xxxl` (32), `huge` (48).
4. WHEN bir ekranda `TextStyle` tanımlanması gerektiğinde, THE ekran SHALL `AppTextStyles` sınıfından ilgili stili kullanmalıdır.
5. WHEN bir ekranda padding veya margin değeri girilmesi gerektiğinde, THE ekran SHALL `AppSpacing` sabitlerini kullanmalıdır.

---

### Gereksinim 3: Component Library — Temel Widget'lar

**Kullanıcı Hikayesi:** Bir geliştirici olarak, tekrar eden UI parçalarını merkezi widget'lardan oluşturmak istiyorum; böylece her ekranda aynı görünüm ve davranış sağlanır.

#### Kabul Kriterleri

1. THE Component_Library SHALL `AppCard` adlı yeniden kullanılabilir bir kart widget'ı içermelidir; bu widget padding, border radius ve gölge değerlerini Design_System token'larından almalıdır.
2. THE Component_Library SHALL `AppButton` adlı birincil, ikincil ve metin varyantlarına sahip bir buton widget'ı içermelidir.
3. THE Component_Library SHALL `AppTextField` adlı tutarlı stil ve doğrulama desteğine sahip bir metin alanı widget'ı içermelidir.
4. THE Component_Library SHALL `SectionHeader` adlı başlık + opsiyonel aksiyon butonu içeren bir bölüm başlığı widget'ı içermelidir.
5. THE Component_Library SHALL `AmountDisplay` adlı para miktarını tutarlı biçimde gösteren bir widget içermelidir; bu widget gelir/gider rengini otomatik uygulamalıdır.
6. WHEN bir ekranda kart, buton veya metin alanı kullanılması gerektiğinde, THE ekran SHALL Component_Library'deki ilgili widget'ı kullanmalıdır.

---

### Gereksinim 4: Component Library — Durum Widget'ları

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, veri olmadığında, hata oluştuğunda veya veri yüklenirken ne yapacağımı anlayan net geri bildirimler görmek istiyorum; böylece uygulamanın durumunu her zaman anlayabilirim.

#### Kabul Kriterleri

1. THE Component_Library SHALL `AppEmptyState` adlı, ikon, başlık, açıklama ve opsiyonel aksiyon butonu içeren bir Empty_State_Widget içermelidir.
2. THE Component_Library SHALL `AppErrorState` adlı, hata mesajı ve "Tekrar Dene" butonu içeren bir Error_State_Widget içermelidir.
3. THE Component_Library SHALL `AppLoadingState` adlı, animasyonlu yükleme göstergesi içeren bir Loading_State_Widget içermelidir.
4. WHEN bir liste ekranında veri bulunmadığında, THE ekran SHALL `AppEmptyState` widget'ını göstermelidir.
5. WHEN bir ekranda veri yükleme hatası oluştuğunda, THE ekran SHALL `AppErrorState` widget'ını göstermelidir.
6. WHEN bir ekranda veri yükleniyor olduğunda, THE ekran SHALL `AppLoadingState` widget'ını göstermelidir.
7. THE `AppEmptyState`, `AppErrorState` ve `AppLoadingState` widget'ları SHALL hem light hem dark temada doğru renkleri kullanmalıdır.

---

### Gereksinim 5: Navigasyon — 5 Tab Bottom Navigation

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, uygulamanın tüm ana modüllerine tek dokunuşla erişmek istiyorum; böylece KMH gibi önemli modüllere ulaşmak için birden fazla ekran geçmem gerekmez.

#### Kabul Kriterleri

1. THE Bottom_Nav SHALL 5 tab içermelidir: Ana Sayfa (home), Kredi Kartı (credit_card), KMH (precious_metal), İstatistik (bar_chart), Ayarlar (settings).
2. THE Bottom_Nav SHALL aktif tab'ı `primary` Color_Token rengiyle vurgulamalıdır.
3. THE Bottom_Nav SHALL her tab için ikon ve etiket göstermelidir.
4. THE Bottom_Nav SHALL light ve dark temada doğru arka plan rengini kullanmalıdır.
5. WHEN kullanıcı bir tab'a dokunduğunda, THE Bottom_Nav SHALL ilgili ekrana 200ms veya daha kısa sürede geçiş yapmalıdır.
6. WHEN kullanıcı KMH tab'ına dokunduğunda, THE Bottom_Nav SHALL `KmhListScreen` ekranını göstermelidir.
7. THE Bottom_Nav SHALL mevcut `CustomBottomNavBar` widget'ının yerini almalıdır.

---

### Gereksinim 6: Dashboard — Finansal Özet Ekranı

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, uygulamayı açtığımda finansal durumumu tek bakışta görmek istiyorum; böylece net bakiye, aylık gelir/gider, kredi kartı borcu ve KMH değerimi hızlıca anlayabilirim.

#### Kabul Kriterleri

1. THE Dashboard SHALL en üstte kullanıcı adını ve selamlama mesajını göstermelidir.
2. THE Dashboard SHALL "Net Bakiye" kartını göstermelidir; bu kart tüm cüzdanların toplam bakiyesini içermelidir.
3. THE Dashboard SHALL "Bu Ay" bölümünde toplam gelir ve toplam gideri yan yana göstermelidir.
4. THE Dashboard SHALL "Kredi Kartı Borcu" metriğini göstermelidir; bu metrik tüm kartların toplam borcunu içermelidir.
5. THE Dashboard SHALL "KMH Değeri" metriğini göstermelidir; bu metrik tüm KMH hesaplarının güncel toplam değerini içermelidir.
6. THE Dashboard SHALL son 5 işlemi "Son İşlemler" bölümünde göstermelidir.
7. WHEN Dashboard yüklendiğinde, THE Dashboard SHALL Loading_State_Widget göstermelidir.
8. WHEN Dashboard verisi boş olduğunda, THE Dashboard SHALL kullanıcıyı cüzdan eklemeye yönlendiren Empty_State_Widget göstermelidir.
9. THE Dashboard SHALL pull-to-refresh ile veriyi yenileyebilmelidir.

---

### Gereksinim 7: Onboarding Akışı

**Kullanıcı Hikayesi:** Yeni bir kullanıcı olarak, uygulamayı ilk açtığımda ne yapacağımı anlamak istiyorum; böylece hızlıca ilk cüzdanımı veya kredi kartımı ekleyebilirim.

#### Kabul Kriterleri

1. THE Onboarding_Flow SHALL yalnızca uygulamanın ilk açılışında gösterilmelidir; sonraki açılışlarda gösterilmemelidir.
2. THE Onboarding_Flow SHALL en az 3 adım içermelidir: karşılama ekranı, temel özelliklerin tanıtımı ve ilk kurulum adımı.
3. THE Onboarding_Flow SHALL ilk kurulum adımında kullanıcıya cüzdan ekleme veya kredi kartı ekleme seçeneği sunmalıdır.
4. WHEN kullanıcı onboarding'i tamamladığında, THE Onboarding_Flow SHALL bu durumu kalıcı olarak kaydetmelidir.
5. WHEN kullanıcı onboarding'i atlamak istediğinde, THE Onboarding_Flow SHALL "Atla" seçeneği sunmalı ve doğrudan Dashboard'a yönlendirmelidir.
6. THE Onboarding_Flow SHALL Design_System renk token'larını ve Component_Library widget'larını kullanmalıdır.
7. THE Onboarding_Flow SHALL hem light hem dark temada doğru görünmelidir.

---

### Gereksinim 8: Dark/Light Tema Tutarlılığı

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, dark moda geçtiğimde tüm ekranların doğru renkleri kullanmasını istiyorum; böylece bazı ekranlarda beyaz arka plan veya siyah metin gibi görsel hatalar oluşmaz.

#### Kabul Kriterleri

1. THE App_Theme SHALL tüm ekranlarda `Theme.of(context)` üzerinden renk ve stil değerlerine erişilmesini zorunlu kılmalıdır.
2. WHEN dark mod aktif olduğunda, THE App_Theme SHALL scaffold arka planının, kart renklerinin ve metin renklerinin dark tema token'larını kullanmasını sağlamalıdır.
3. IF bir ekranda `Colors.white` veya `Colors.black` hardcoded renk kullanılıyorsa, THEN THE ekran SHALL bu rengi ilgili tema token'ı ile değiştirmelidir.
4. THE App_Theme SHALL sistem teması değiştiğinde (light ↔ dark) tüm ekranların otomatik olarak güncellenmesini sağlamalıdır.
5. THE Component_Library'deki tüm widget'lar SHALL hem light hem dark temada görsel olarak doğru görünmelidir.

---

### Gereksinim 9: Ekran Tutarlılığı — AppBar ve Sayfa Yapısı

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, tüm ekranlarda benzer bir düzen ve navigasyon deneyimi yaşamak istiyorum; böylece hangi ekranda olduğumu kolayca anlayabilirim.

#### Kabul Kriterleri

1. THE Component_Library SHALL `AppPageScaffold` adlı standart sayfa iskelet widget'ı içermelidir; bu widget AppBar, body ve opsiyonel FAB alanlarını standartlaştırmalıdır.
2. THE `AppPageScaffold` SHALL başlık, opsiyonel geri butonu ve opsiyonel aksiyon ikonları parametrelerini desteklemelidir.
3. WHEN bir detay ekranı açıldığında, THE ekran SHALL standart geri butonu içeren AppBar göstermelidir.
4. THE tüm liste ekranları SHALL tutarlı padding değerleri kullanmalıdır; yatay padding `AppSpacing.lg` (16px) olmalıdır.
5. THE tüm form ekranları SHALL "Kaydet" ve "İptal" butonlarını tutarlı konumda göstermelidir.

---

### Gereksinim 10: Erişilebilirlik ve Performans

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, uygulamanın akıcı çalışmasını ve dokunma hedeflerinin yeterince büyük olmasını istiyorum; böylece kullanım sırasında gecikme veya yanlış dokunma yaşamam.

#### Kabul Kriterleri

1. THE Component_Library'deki tüm dokunulabilir widget'lar SHALL minimum 44x44 piksel dokunma hedefi boyutuna sahip olmalıdır.
2. THE Loading_State_Widget SHALL veri yükleme süresini gizlemek için skeleton (iskelet) animasyonu kullanmalıdır.
3. THE Bottom_Nav SHALL tab geçişlerinde gereksiz widget rebuild'lerini önlemek için `IndexedStack` veya eşdeğer bir yapı kullanmalıdır.
4. WHEN bir liste 50'den fazla öğe içerdiğinde, THE liste SHALL `ListView.builder` ile lazy loading kullanmalıdır.
5. THE tüm ikonlar SHALL `AppIcons` veya `LucideIcons` gibi merkezi bir ikon kaynağından alınmalıdır; karışık ikon kütüphanesi kullanımından kaçınılmalıdır.
