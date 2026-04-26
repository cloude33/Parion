# Uygulama Planı: İstatistik Ekranı Yeniden Tasarımı

## Genel Bakış

Bu plan, istatistik ekranının kapsamlı yeniden tasarımını adım adım uygular. Mevcut dağınık ekranlar tek bir `StatisticsScreen` altında 7 sekmeli yapıya taşınır; yeni analiz bölümleri eklenir; Design System token'ları tam olarak uygulanır ve performans iyileştirmeleri yapılır.

## Görevler

- [x] 1. Yeni veri modelleri ve saf hesaplama fonksiyonlarını oluştur
  - [x] 1.1 `SavingsRateTrendData` modelini ve `calculateRate` fonksiyonunu yaz
    - `lib/models/savings_rate_trend_data.dart` dosyasını oluştur
    - `calculateRate(double income, double expense) → double?` statik metodunu uygula: income > 0 ise `(income - expense) / income * 100`, income ≤ 0 ise `null`
    - `fromMonthlyData` factory constructor'ını ekle
    - _Gereksinimler: 3.2, 5.2, 5.6_

  - [x] 1.2 `SavingsRateTrendData.calculateRate` için property-based test yaz
    - **Özellik 1: Tasarruf Oranı Hesaplama Doğruluğu** — income > 0 için `(income - expense) / income * 100` döner
    - **Özellik 2: Sıfır Gelirde Tasarruf Oranı Tanımsızlığı** — income = 0 için `null` döner
    - **Doğrular: Gereksinim 3.2, 5.2, 5.6**

  - [x] 1.3 `BillHistorySummary` modelini ve `calculatePaymentRate` fonksiyonunu yaz
    - `lib/models/bill_history_summary.dart` dosyasını oluştur
    - `calculatePaymentRate(int paid, int total) → double` statik metodunu uygula: total > 0 ise `(paid / total) * 100`, total ≤ 0 ise `0.0`
    - _Gereksinimler: 9.2_

  - [x] 1.4 `BillHistorySummary.calculatePaymentRate` için property-based test yaz
    - **Özellik 3: Fatura Ödeme Oranı Hesaplama Doğruluğu** — paid ≥ 0, total > 0 için `(paid / total) * 100` döner
    - **Doğrular: Gereksinim 9.2**

- [x] 2. Durum yönetimi altyapısını ve `StatisticsScreen` iskeletini güncelle
  - [x] 2.1 `StatisticsScreen` state sınıfını 7 sekme için yeniden yapılandır
    - `lib/screens/statistics_screen.dart` dosyasını güncelle
    - `TabController` length'ini 7 olarak ayarla; sekme sabitlerini (`kTabSummary` … `kTabRecurring`) tanımla
    - `List<bool> _tabLoaded = List.filled(7, false)` state'ini ekle
    - `TimeFilter _selectedTimeFilter`, `_customStartDate`, `_customEndDate` state'lerini ekle
    - `_onTabChanged()` metodunu uygula: ziyaret edilen sekme için `_tabLoaded[i] = true`
    - `_onFilterChanged(TimeFilter)` metodunu uygula: tüm `_tabLoaded` sıfırla, aktif sekmeyi hemen yükle
    - `_retryTab(int)` metodunu uygula
    - `_onRefresh()` metodunu uygula: `CacheManager.clearPrefix('stats_')` + tüm `_tabLoaded` sıfırla
    - _Gereksinimler: 1.5, 1.6, 1.8, 2.3, 15.1, 15.3, 15.5_

  - [x] 2.2 `_onFilterChanged` için property-based test yaz
    - **Özellik 5: Zaman Filtresi Değişiminde Sekme Sıfırlama** — herhangi bir filtre değişiminde aktif sekme dışındaki tüm `_tabLoaded[i]` değerleri `false` olur
    - **Doğrular: Gereksinim 2.3, 15.3**

  - [x] 2.3 `_onTabChanged` (lazy loading) için property-based test yaz
    - **Özellik 7: Lazy Loading Sekme Yükleme Sırası** — yalnızca ziyaret edilen sekmenin `_tabLoaded[i]` değeri `true` olur, diğerleri etkilenmez
    - **Doğrular: Gereksinim 1.6, 15.1**

  - [x] 2.4 Tarih aralığı doğrulama fonksiyonunu yaz
    - `validateDateRange(DateTime start, DateTime end) → DateRangeValidationResult` fonksiyonunu `lib/core/utils/` altına ekle
    - `end < start` ise `isValid: false` ve hata mesajı döndür
    - _Gereksinimler: 2.5_

  - [x] 2.5 `validateDateRange` için property-based test yaz
    - **Özellik 6: Geçersiz Tarih Aralığı Reddi** — `endDate < startDate` koşulunda `isValid: false` ve `errorMessage != null` döner
    - **Doğrular: Gereksinim 2.5**

- [x] 3. Kontrol noktası — Temel altyapı testleri geçmeli
  - Tüm testlerin geçtiğini doğrula, sorun varsa kullanıcıya sor.

- [x] 4. `StatisticsScreen` ana yapısını ve `IndexedStack` düzenini uygula
  - [x] 4.1 `StatisticsScreen` build metodunu `IndexedStack` ile yeniden yaz
    - `TabBarView` yerine `IndexedStack` kullan; 7 sekme içeriğini `_buildSummaryTab()`, `SpendingTab`, `CashFlowTab`, `_buildAssetsTab()`, `DebtStatisticsTab`, `CardReportingTab`, `RecurringStatisticsTab` olarak yerleştir
    - Kaydırılabilir `TabBar` (isScrollable: true) ile 7 sekme başlığını göster
    - `TimeFilterBar`'ı tüm sekmelerin üstüne yerleştir
    - `RefreshIndicator` ile pull-to-refresh desteği ekle
    - Varsayılan sekme olarak Özet (index 0) ayarla
    - _Gereksinimler: 1.1, 1.5, 1.7, 1.8, 2.1, 15.5_

  - [x] 4.2 `TimeFilterBar` bileşenini güncelle
    - Günlük, Haftalık, Aylık, Yıllık, Özel seçeneklerini içer
    - Özel seçildiğinde tarih aralığı seçici göster
    - Geçersiz aralıkta `SnackBar` ile hata mesajı göster, filtreyi uygulama
    - Seçili filtreyi oturum boyunca koru
    - `AppColors`, `AppTextStyles`, `AppSpacing` token'larını kullan
    - _Gereksinimler: 2.1, 2.2, 2.4, 2.5, 2.6, 13.1, 13.2, 13.3_

  - [x] 4.3 `StatisticsScreen` için birim testleri yaz
    - Sekme sayısının 7 olduğunu doğrula
    - Varsayılan sekmenin Özet (index 0) olduğunu doğrula
    - `TimeFilterBar` filtre değişiminde callback'in tetiklendiğini doğrula
    - _Gereksinimler: 1.1, 1.8, 2.3_

- [x] 5. Wrapper sekme bileşenlerini oluştur
  - [x] 5.1 `DebtStatisticsTab` wrapper widget'ını oluştur
    - `lib/widgets/statistics/debt_statistics_tab.dart` dosyasını oluştur
    - `debt_statistics_screen.dart` içeriğini `StatelessWidget` olarak sar
    - `startDate` ve `endDate` parametrelerini al ve mevcut içeriğe ilet
    - Hardcoded renkleri `AppColors` token'larıyla değiştir
    - `Statistics_Loading_State`, `Statistics_Empty_State`, `Statistics_Error_State` widget'larını entegre et
    - _Gereksinimler: 1.2, 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 13.1, 14.1, 14.2, 14.3_

  - [x] 5.2 `CardReportingTab` wrapper widget'ını oluştur
    - `lib/widgets/statistics/card_reporting_tab.dart` dosyasını oluştur
    - `card_reporting_screen.dart` içeriğini sar; iç sekmeler `NestedScrollView` ile yönetilsin
    - Kart seçici dropdown ekle
    - `Color(0xFF00BFA5)` gibi hardcoded renkleri `AppColors` token'larıyla değiştir
    - `Statistics_Empty_State` widget'ını entegre et
    - _Gereksinimler: 1.3, 17.1, 17.2, 17.3, 17.4, 17.5, 17.6, 13.1_

  - [x] 5.3 `RecurringStatisticsTab` wrapper widget'ını oluştur
    - `lib/widgets/statistics/recurring_statistics_tab.dart` dosyasını oluştur
    - `recurring_statistics_screen.dart` içeriğini sar
    - `Statistics_Empty_State` widget'ını entegre et
    - Design System token'larını uygula
    - _Gereksinimler: 1.4, 18.1, 18.2, 18.3, 18.4, 18.5, 13.1_

- [x] 6. `SavingsRateTrendChart` widget'ını oluştur
  - [x] 6.1 `SavingsRateTrendChart` widget'ını yaz
    - `lib/widgets/statistics/savings_rate_trend_chart.dart` dosyasını oluştur
    - Son 12 aya ait `SavingsRateTrendData` listesini çizgi grafik olarak göster
    - Pozitif oranlar `AppColors.success`, negatif oranlar `AppColors.error` rengi ile doldurulmuş alan
    - Ortalama referans çizgisini kesikli yatay çizgi olarak göster
    - Dokunma tooltip'i: ay adı, gelir, gider, tasarruf oranı
    - Gelir = 0 olan aylar için "Veri Yok" etiketi göster
    - `Semantics` widget'ı ile ekran okuyucu etiketi ekle
    - _Gereksinimler: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 19.2_

  - [x] 6.2 `SavingsRateTrendChart` için widget testleri yaz
    - Pozitif oran için `AppColors.success` rengi kullanıldığını doğrula
    - Negatif oran için `AppColors.error` rengi kullanıldığını doğrula
    - Gelir = 0 olan ay için "Veri Yok" etiketinin gösterildiğini doğrula
    - _Gereksinimler: 5.3, 5.6_

- [x] 7. `BillHistorySummaryCard` widget'ını oluştur
  - [x] 7.1 `BillHistorySummaryCard` widget'ını yaz
    - `lib/widgets/statistics/bill_history_summary_card.dart` dosyasını oluştur
    - Her fatura şablonu için ödeme oranı, son ödeme tarihi, sonraki ödeme tarihini göster
    - Renk kodlaması: `paymentRate >= 100` → `AppColors.success`, `50 ≤ rate < 100` → `AppColors.warning`, `rate < 50` → `AppColors.error`
    - Renk körü erişilebilirlik için renk yanında ikon kullan
    - Boş durum: `onAddBill` callback'i ile fatura eklemeye yönlendiren `Statistics_Empty_State`
    - _Gereksinimler: 9.1, 9.2, 9.3, 9.4, 9.5, 13.1, 19.3_

  - [x] 7.2 `BillHistorySummaryCard.colorForRate` için property-based test yaz
    - **Özellik 4: Fatura Ödeme Oranı Renk Kodlaması Tutarlılığı** — her `paymentRate` değeri için doğru renk döner
    - **Doğrular: Gereksinim 9.3**

  - [x] 7.3 `BillHistorySummaryCard` için widget testleri yaz
    - Boş durum render testini yaz
    - Dolu durum render testini yaz (3 farklı renk kategorisi)
    - _Gereksinimler: 9.3, 9.5_

- [x] 8. Özet sekmesini oluştur
  - [x] 8.1 `_buildSummaryTab()` metodunu uygula
    - Toplam gelir, toplam gider, net nakit akışı özet kartlarını göster
    - `FinancialHealthScoreCard` widget'ını entegre et; `StatisticsService.analyzeAssets()` kullan
    - `SavingsRateTrendChart` widget'ını entegre et
    - `BudgetTrackerCard` widget'ını entegre et
    - `PeriodComparisonCard` widget'ını entegre et
    - Ödeme yöntemi dağılımı için `InteractivePieChart` ekle
    - Gelir/borç oranı kartını ekle
    - `BillHistorySummaryCard` widget'ını entegre et
    - `Statistics_Loading_State`, `Statistics_Empty_State`, `Statistics_Error_State` durumlarını uygula
    - _Gereksinimler: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

  - [x] 8.2 Özet sekmesi için widget testleri yaz
    - Yükleme durumunda `Statistics_Loading_State` gösterildiğini doğrula
    - Boş veri durumunda `Statistics_Empty_State` gösterildiğini doğrula
    - Hata durumunda `Statistics_Error_State` ve "Tekrar Dene" butonunun gösterildiğini doğrula
    - _Gereksinimler: 3.7, 3.8, 3.9, 14.1, 14.2, 14.3_

- [x] 9. Varlıklar sekmesini oluştur
  - [x] 9.1 `_buildAssetsTab()` metodunu uygula
    - Toplam pozitif varlıklar, toplam KMH borcu, net varlık özet kartlarını göster
    - Normal cüzdanlar ve KMH hesaplarını ayrı bölümlerde göster
    - `KmhDashboard`, `KmhAssetCard` widget'larını entegre et
    - KMH hesapları için limit kullanım yüzdesini ilerleme çubuğu ile göster
    - `NetWorthTrendChart` widget'ını entegre et; Design System token'larıyla uyumlu hale getir
    - Boş durum: `Statistics_Empty_State` widget'ı
    - _Gereksinimler: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_

  - [x] 9.2 Varlıklar sekmesi için widget testleri yaz
    - Cüzdan yokken `Statistics_Empty_State` gösterildiğini doğrula
    - KMH ve normal cüzdanların ayrı bölümlerde gösterildiğini doğrula
    - _Gereksinimler: 11.1, 11.7_

- [x] 10. Kontrol noktası — Tüm sekmeler ve widget testleri geçmeli
  - Tüm testlerin geçtiğini doğrula, sorun varsa kullanıcıya sor.

- [x] 11. Harcama sekmesini güncelle
  - [x] 11.1 `SpendingTab` içine `SpendingHabitsCard` ve `Income_Sources` bölümlerini entegre et
    - `SpendingHabitsCard` widget'ını Harcama sekmesine ekle
    - Gün/saat görünümleri için `SegmentedButton` ekle
    - En çok harcama yapılan gün, en yoğun saat, günlük ortalama özet kutucuklarını ekle
    - Otomatik içgörü mesajı üretimini uygula
    - Gelir kaynakları dağılımı için `InteractivePieChart` ekle; kategorileri yüzdeye göre sıralı liste olarak göster
    - Yetersiz veri (< 10 işlem) durumunda uyarı mesajı göster
    - `Statistics_Empty_State` widget'ını entegre et
    - _Gereksinimler: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [x] 11.2 Harcama sekmesi için widget testleri yaz
    - Yetersiz veri durumunda uyarı mesajının gösterildiğini doğrula
    - Gelir yokken `Statistics_Empty_State` gösterildiğini doğrula
    - _Gereksinimler: 7.8, 8.6_

- [x] 12. Design System token'larını tüm istatistik widget'larına uygula
  - [x] 12.1 Mevcut istatistik widget'larındaki hardcoded renkleri `AppColors` token'larıyla değiştir
    - `Color(0xFF...)` değerlerini tara ve `AppColors` karşılıklarıyla değiştir
    - `Colors.white`, `Colors.black`, `Colors.grey` kullanımlarını `AppColors` veya `Theme.of(context)` ile değiştir
    - `_billCategoryColors` haritasını `AppColors` token'larına taşı
    - _Gereksinimler: 13.1, 13.5, 13.6_

  - [x] 12.2 Mevcut istatistik widget'larındaki inline `TextStyle` tanımlarını `AppTextStyles` ile değiştir
    - Tüm istatistik widget'larında inline `TextStyle(...)` kullanımlarını `AppTextStyles` sınıfından ilgili stillerle değiştir
    - _Gereksinimler: 13.2_

  - [x] 12.3 Mevcut istatistik widget'larındaki hardcoded padding/margin değerlerini `AppSpacing` ile değiştir
    - Tüm istatistik widget'larında hardcoded `EdgeInsets.all(16)` gibi değerleri `AppSpacing` sabitleriyle değiştir
    - _Gereksinimler: 13.3_

  - [x] 12.4 Light/dark tema uyumluluğunu doğrula
    - `Theme.of(context)` üzerinden renk ve stil değerlerine erişildiğini doğrula
    - Her iki temada görsel doğruluğu kontrol et
    - _Gereksinimler: 13.4_

- [x] 13. Durum widget'larını ve erişilebilirlik gereksinimlerini uygula
  - [x] 13.1 `Statistics_Loading_State` skeleton animasyonunu doğrula ve güncelle
    - `statistics_loading_state.dart` widget'ının skeleton animasyonu kullandığını doğrula; `CircularProgressIndicator` varsa değiştir
    - _Gereksinimler: 14.5_

  - [x] 13.2 `Statistics_Empty_State` aksiyon butonlarını güncelle
    - Her sekme için ilgili veriyi oluşturmaya yönlendiren aksiyon butonu içerdiğini doğrula
    - _Gereksinimler: 14.6_

  - [x] 13.3 "Tekrar Dene" mekanizmasını tüm sekmelere uygula
    - `_retryTab(int)` metodunun tüm sekmelerde `Statistics_Error_State` "Tekrar Dene" butonuna bağlandığını doğrula
    - _Gereksinimler: 14.3, 14.4_

  - [x] 13.4 Erişilebilirlik gereksinimlerini uygula
    - Tüm grafik widget'larına `Semantics` widget'ı ile açıklayıcı etiket ekle
    - Renk kodlamalarına ikon veya metin desteği ekle (renk körü erişilebilirlik)
    - Dokunma hedeflerinin minimum 44×44 piksel olduğunu doğrula
    - Sistem yazı boyutu ayarlarına uyum için metin taşmalarını önle
    - _Gereksinimler: 19.1, 19.2, 19.3, 19.4_

- [x] 14. Performans ve önbellekleme katmanını uygula
  - [x] 14.1 `CacheManager` entegrasyonunu uygula
    - `CacheManager` kullanarak hesaplanan istatistik verilerini önbelleğe al
    - Önbellek anahtarı formatını uygula: `stats_{tabIndex}_{filterKey}_{startDate}_{endDate}`
    - Aynı filtre ve sekme için tekrar servis çağrısı yapılmadığını doğrula
    - _Gereksinimler: 15.2_

  - [x] 14.2 Ağır hesaplamaları `compute` ile ana thread'den ayır
    - İstatistik agregasyonu ve grafik veri hazırlama işlemlerini `compute` veya `Isolate` kullanarak arka planda çalıştır
    - _Gereksinimler: 15.6_

  - [x] 14.3 50'den fazla öğe içeren listelerde `ListView.builder` kullan
    - Borç/Alacak, Kartlar ve Tekrarlayan sekmelerindeki uzun listelerde `ListView.builder` ile lazy rendering uygula
    - _Gereksinimler: 15.4_

- [x] 15. Eski ekranların navigasyon bağlantılarını güncelle
  - [x] 15.1 `debt_statistics_screen.dart`, `card_reporting_screen.dart`, `recurring_statistics_screen.dart` ekranlarına olan navigasyon bağlantılarını güncelle
    - Bu ekranlara yönlendiren tüm `Navigator.push` / `go_router` çağrılarını `StatisticsScreen`'in ilgili sekmesine yönlendirecek şekilde güncelle
    - _Gereksinimler: 1.2, 1.3, 1.4_

- [x] 16. Son kontrol noktası — Tüm testler geçmeli
  - Tüm birim, widget ve property-based testlerin geçtiğini doğrula.
  - Sorun varsa kullanıcıya sor.

## Notlar

- `*` ile işaretlenmiş görevler isteğe bağlıdır; daha hızlı MVP için atlanabilir
- Her görev, izlenebilirlik için ilgili gereksinimlere referans verir
- Kontrol noktaları artımlı doğrulama sağlar
- Property-based testler evrensel doğruluk özelliklerini doğrular
- Birim testleri spesifik örnekleri ve kenar durumları kapsar
- Tasarım belgesi Dart/Flutter kullanmaktadır; tüm kod örnekleri Dart ile yazılmalıdır
