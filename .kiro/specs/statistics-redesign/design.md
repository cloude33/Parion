# Tasarım Belgesi: İstatistik Ekranı Yeniden Tasarımı

## Genel Bakış

Bu belge, Parion kişisel finans uygulamasının istatistik ekranının kapsamlı yeniden tasarımını tanımlar. Mevcut yapıda beş ayrı ekrana dağılmış olan finansal analiz işlevleri, tek bir `StatisticsScreen` altında 7 sekmeli tutarlı bir navigasyon yapısına taşınmaktadır.

### Temel Tasarım Kararları

**1. IndexedStack ile Sekme Durumu Koruması**
`TabBarView` yerine `IndexedStack` tercih edilmiştir. `TabBarView` her sekme geçişinde widget'ı yeniden oluşturur; `IndexedStack` ise sekme durumunu (scroll pozisyonu, form değerleri, yüklü veri) bellekte tutar. Bu, kullanıcı deneyimini önemli ölçüde iyileştirir.

**2. Lazy Loading ile Performans**
Her sekme için `_tabLoaded[i]` bayrağı tutulur. Bir sekme ilk kez ziyaret edildiğinde veri yüklenir; sonraki ziyaretlerde önbellekten sunulur. Bu yaklaşım, ekran açılış süresini minimize eder.

**3. Mevcut Widget'ların Yeniden Kullanımı**
`debt_statistics_screen.dart`, `card_reporting_screen.dart` ve `recurring_statistics_screen.dart` içerikleri yeni wrapper widget'larla (`DebtStatisticsTab`, `CardReportingTab`, `RecurringStatisticsTab`) sarılarak mevcut kodun büyük bölümü korunur.

**4. Design System Zorunluluğu**
Tüm renk değerleri `AppColors` token'larından, tipografi `AppTextStyles`'dan, boşluklar `AppSpacing`'den gelmelidir. Hardcoded `Color(0xFF...)` değerleri yasaktır.

**5. Evrensel Zaman Filtresi**
`TimeFilter` ve tarih aralığı `StatisticsScreen` state'inde tutulur ve tüm sekmelere prop olarak iletilir. Filtre değiştiğinde tüm `_tabLoaded` bayrakları sıfırlanır.

---

## Mimari

### Klasör Yapısı

```
lib/
├── screens/
│   └── statistics_screen.dart          ← GÜNCELLEME (7 sekme, IndexedStack)
└── widgets/statistics/
    ├── savings_rate_trend_chart.dart    ← YENİ
    ├── bill_history_summary_card.dart   ← YENİ
    ├── debt_statistics_tab.dart         ← YENİ (wrapper)
    ├── card_reporting_tab.dart          ← YENİ (wrapper)
    ├── recurring_statistics_tab.dart    ← YENİ (wrapper)
    │
    ├── [MEVCUT — değişmeden kullanılır]
    ├── financial_health_score_card.dart
    ├── budget_tracker_card.dart
    ├── spending_habits_card.dart
    ├── net_worth_trend_chart.dart
    ├── time_filter_bar.dart
    ├── cash_flow_tab.dart
    ├── spending_tab.dart
    ├── kmh_dashboard.dart
    ├── kmh_asset_card.dart
    ├── kmh_utilization_indicator.dart
    ├── statistics_empty_state.dart
    ├── statistics_error_state.dart
    ├── statistics_loading_state.dart
    ├── statistics_state_builder.dart
    ├── interactive_pie_chart.dart
    ├── interactive_bar_chart.dart
    ├── interactive_line_chart.dart
    ├── period_comparison_card.dart
    ├── average_comparison_card.dart
    └── responsive_statistics_layout.dart
```

### Bağımlılık Akışı

```
StatisticsScreen
  │
  ├── state: TimeFilter, _tabLoaded[7], _customStartDate, _customEndDate
  │
  ├── TimeFilterBar (üst bar — tüm sekmelere ortak)
  │
  └── IndexedStack
        ├── [0] _buildSummaryTab()
        │     ├── SummaryCardsRow (gelir/gider/net)
        │     ├── SavingsRateTrendChart ← YENİ
        │     ├── FinancialHealthScoreCard
        │     ├── BudgetSummaryCard + BudgetTrackerCard
        │     ├── PeriodComparisonCard
        │     ├── InteractivePieChart (ödeme yöntemi)
        │     ├── IncomeDebtRatioCard
        │     └── BillHistorySummaryCard ← YENİ
        │
        ├── [1] SpendingTab (mevcut)
        │     ├── SpendingHabitsCard
        │     └── InteractivePieChart (gelir kaynakları)
        │
        ├── [2] CashFlowTab (mevcut)
        │
        ├── [3] _buildAssetsTab()
        │     ├── AssetSummaryCards (toplam varlık, KMH borcu, net varlık)
        │     ├── KmhDashboard
        │     ├── WalletListSection (normal + KMH ayrı)
        │     └── NetWorthTrendChart
        │
        ├── [4] DebtStatisticsTab ← YENİ wrapper
        ├── [5] CardReportingTab ← YENİ wrapper
        └── [6] RecurringStatisticsTab ← YENİ wrapper
```

### Servis Bağımlılıkları

```
StatisticsScreen
  ├── StatisticsService   — istatistik hesaplamaları
  ├── DataService         — ham veri erişimi
  ├── BillPaymentService  — fatura ödeme geçmişi
  ├── BillTemplateService — fatura şablonları
  └── CacheManager        — önbellekleme
```

---

## Bileşenler ve Arayüzler

### StatisticsScreen (Güncelleme)

```dart
class StatisticsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Wallet> wallets;
  final List<Loan> loans;
  final List<CreditCardTransaction> creditCardTransactions;
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;           // length: 7
  final List<bool> _tabLoaded = List.filled(7, false);
  TimeFilter _selectedTimeFilter = TimeFilter.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Sekme indeksleri
  static const int kTabSummary    = 0;
  static const int kTabSpending   = 1;
  static const int kTabCashFlow   = 2;
  static const int kTabAssets     = 3;
  static const int kTabDebt       = 4;
  static const int kTabCards      = 5;
  static const int kTabRecurring  = 6;
}
```

**Sekme geçiş mantığı:**
```dart
void _onTabChanged() {
  final i = _tabController.index;
  if (!_tabLoaded[i]) {
    setState(() => _tabLoaded[i] = true);
  }
}
```

**Filtre değişim mantığı:**
```dart
void _onFilterChanged(TimeFilter filter) {
  setState(() {
    _selectedTimeFilter = filter;
    // Tüm sekmeleri geçersiz kıl
    for (int i = 0; i < _tabLoaded.length; i++) {
      _tabLoaded[i] = false;
    }
    // Aktif sekmeyi hemen yeniden yükle
    _tabLoaded[_tabController.index] = true;
  });
}
```

**Önbellek anahtarı formatı:**
```
stats_{tabIndex}_{filterKey}_{startDate}_{endDate}
```

---

### SavingsRateTrendChart (YENİ)

12 aylık tasarruf oranı trendi çizgi grafiği.

```dart
class SavingsRateTrendChart extends StatefulWidget {
  final List<SavingsRateTrendData> trendData;
  final double? averageRate;  // Referans çizgisi için

  const SavingsRateTrendChart({
    super.key,
    required this.trendData,
    this.averageRate,
  });
}
```

**Davranış:**
- Pozitif oranlar: `AppColors.success` (yeşil) ile doldurulmuş alan
- Negatif oranlar: `AppColors.error` (kırmızı) ile doldurulmuş alan
- Ortalama referans çizgisi: kesikli yatay çizgi
- Dokunma tooltip'i: ay adı, gelir, gider, tasarruf oranı
- Gelir = 0 olan aylar: "Veri Yok" etiketi ile gösterilir

---

### BillHistorySummaryCard (YENİ)

Fatura şablonu bazlı ödeme geçmişi özeti.

```dart
class BillHistorySummaryCard extends StatelessWidget {
  final List<BillHistorySummary> summaries;
  final VoidCallback? onAddBill;  // Boş durum aksiyonu

  const BillHistorySummaryCard({
    super.key,
    required this.summaries,
    this.onAddBill,
  });
}
```

**Renk kodlaması:**
- `paymentRate >= 100%` → `AppColors.success`
- `50% <= paymentRate < 100%` → `AppColors.warning`
- `paymentRate < 50%` → `AppColors.error`

---

### DebtStatisticsTab (YENİ Wrapper)

```dart
class DebtStatisticsTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const DebtStatisticsTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });
}
```

`debt_statistics_screen.dart` içeriğini `StatelessWidget` olarak sarar. Design System token'larını uygular.

---

### CardReportingTab (YENİ Wrapper)

```dart
class CardReportingTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const CardReportingTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });
}
```

`card_reporting_screen.dart` içeriğini sarar. İç sekmeler `NestedScrollView` ile yönetilir.

---

### RecurringStatisticsTab (YENİ Wrapper)

```dart
class RecurringStatisticsTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const RecurringStatisticsTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });
}
```

---

## Veri Modelleri

### SavingsRateTrendData (YENİ)

```dart
class SavingsRateTrendData {
  final DateTime month;       // Ayın ilk günü
  final double income;        // Toplam gelir
  final double expense;       // Toplam gider
  final double? savingsRate;  // null ise gelir = 0 (Veri Yok)

  SavingsRateTrendData({
    required this.month,
    required this.income,
    required this.expense,
    this.savingsRate,
  });

  /// Tasarruf oranını hesaplar.
  /// Gelir > 0 ise: (gelir - gider) / gelir × 100
  /// Gelir = 0 ise: null döner
  static double? calculateRate(double income, double expense) {
    if (income <= 0) return null;
    return (income - expense) / income * 100;
  }

  factory SavingsRateTrendData.fromMonthlyData({
    required DateTime month,
    required double income,
    required double expense,
  }) {
    return SavingsRateTrendData(
      month: month,
      income: income,
      expense: expense,
      savingsRate: calculateRate(income, expense),
    );
  }
}
```

### BillHistorySummary (YENİ)

```dart
class BillHistorySummary {
  final String templateId;
  final String templateName;
  final BillTemplateCategory category;
  final int totalPayments;      // Toplam ödeme sayısı
  final int paidPayments;       // Ödenen sayısı
  final double paymentRate;     // paidPayments / totalPayments × 100
  final DateTime? lastPaidDate; // Son ödeme tarihi
  final DateTime? nextDueDate;  // Sonraki beklenen ödeme

  BillHistorySummary({
    required this.templateId,
    required this.templateName,
    required this.category,
    required this.totalPayments,
    required this.paidPayments,
    required this.paymentRate,
    this.lastPaidDate,
    this.nextDueDate,
  });

  /// Ödeme oranını hesaplar.
  /// totalPayments > 0 ise: paidPayments / totalPayments × 100
  /// totalPayments = 0 ise: 0.0 döner
  static double calculatePaymentRate(int paid, int total) {
    if (total <= 0) return 0.0;
    return (paid / total) * 100;
  }
}
```

### Mevcut Modeller (Değişmeden Kullanılır)

| Model | Kullanım Yeri |
|---|---|
| `NetWorthTrendData` | `NetWorthTrendChart` — Varlıklar sekmesi |
| `FinancialHealthScore` | `FinancialHealthScoreCard` — Özet sekmesi |
| `AssetAnalysis` | `StatisticsService.analyzeAssets()` |
| `SpendingAnalysis` | `SpendingHabitsCard`, `BudgetTrackerCard` |
| `CashFlowData` | `CashFlowTab` |
| `BudgetComparison` | `BudgetTrackerCard` |
| `BillPayment` | `BillHistorySummaryCard` |
| `BillTemplate` | `BillHistorySummaryCard` |

---

## Doğruluk Özellikleri

*Bir özellik (property), sistemin tüm geçerli çalışmalarında doğru olması gereken bir karakteristik veya davranıştır — temelde sistemin ne yapması gerektiğine dair biçimsel bir ifadedir. Özellikler, insan tarafından okunabilir spesifikasyonlar ile makine tarafından doğrulanabilir doğruluk garantileri arasında köprü görevi görür.*

### Özellik 1: Tasarruf Oranı Hesaplama Doğruluğu

*Herhangi bir* gelir > 0 ve gider değeri için, `SavingsRateTrendData.calculateRate(income, expense)` fonksiyonu `(income - expense) / income * 100` değerini döndürmelidir.

**Doğrular: Gereksinim 3.2, 5.2, 5.6**

---

### Özellik 2: Sıfır Gelirde Tasarruf Oranı Tanımsızlığı

*Herhangi bir* gelir = 0 durumunda, `SavingsRateTrendData.calculateRate(0, expense)` fonksiyonu `null` döndürmeli ve UI "Veri Yok" göstermelidir.

**Doğrular: Gereksinim 5.6**

> *Yansıma notu: Özellik 2, Özellik 1'in kenar durumudur. Özellik 1 yalnızca income > 0 için geçerlidir; Özellik 2 ise income = 0 durumunu ayrıca kapsar. İkisi birlikte tam bir kapsam sağlar.*

---

### Özellik 3: Fatura Ödeme Oranı Hesaplama Doğruluğu

*Herhangi bir* `paidCount >= 0` ve `totalCount > 0` değeri için, `BillHistorySummary.calculatePaymentRate(paidCount, totalCount)` fonksiyonu `(paidCount / totalCount) * 100` değerini döndürmelidir.

**Doğrular: Gereksinim 9.2**

---

### Özellik 4: Fatura Ödeme Oranı Renk Kodlaması Tutarlılığı

*Herhangi bir* `paymentRate` değeri için, renk seçimi şu kuralı her zaman karşılamalıdır:
- `paymentRate >= 100` → `AppColors.success`
- `50 <= paymentRate < 100` → `AppColors.warning`
- `paymentRate < 50` → `AppColors.error`

**Doğrular: Gereksinim 9.3**

---

### Özellik 5: Zaman Filtresi Değişiminde Sekme Sıfırlama

*Herhangi bir* `TimeFilter` değer değişikliğinde, `_tabLoaded` listesindeki tüm 7 elemanın `false` olarak sıfırlanması gerekir.

**Doğrular: Gereksinim 2.3, 15.3**

---

### Özellik 6: Geçersiz Tarih Aralığı Reddi

*Herhangi bir* `(startDate, endDate)` çifti için, `endDate < startDate` koşulu sağlandığında filtre uygulanmamalı ve hata mesajı gösterilmelidir.

**Doğrular: Gereksinim 2.5**

---

### Özellik 7: Lazy Loading Sekme Yükleme Sırası

*Herhangi bir* sekme indeksi `i` için, `_tabLoaded[i]` değeri yalnızca o sekme ilk kez ziyaret edildiğinde `true` olmalıdır; diğer sekmelerin `_tabLoaded` değerleri etkilenmemelidir.

**Doğrular: Gereksinim 1.6, 15.1**

---

## Hata Yönetimi

### Durum Widget'ı Münhasırlığı

Her sekme içinde herhangi bir anda yalnızca bir durum widget'ı görünür olabilir:

```
Yükleniyor  →  StatisticsSkeletonLoader (skeleton animasyonu)
Boş veri    →  StatisticsEmptyState (aksiyon butonu ile)
Hata        →  StatisticsErrorState ("Tekrar Dene" butonu ile)
Başarılı    →  İçerik widget'ları
```

Bu münhasırlık `StatisticsFutureBuilder` / `StatisticsStateBuilder` tarafından otomatik olarak yönetilir.

### Hata Senaryoları ve Yanıtlar

| Senaryo | Yanıt |
|---|---|
| Servis çağrısı başarısız | `StatisticsErrorState` + "Tekrar Dene" butonu |
| Veri boş | `StatisticsEmptyState` + ilgili aksiyon butonu |
| Geçersiz tarih aralığı | `SnackBar` ile hata mesajı, filtre uygulanmaz |
| Önbellek miss | Servis çağrısı yapılır, skeleton gösterilir |
| Hesaplama hatası (gelir = 0) | "Veri Yok" etiketi, uygulama çökmez |

### "Tekrar Dene" Mekanizması

```dart
void _retryTab(int tabIndex) {
  setState(() {
    _tabLoaded[tabIndex] = false;
  });
  // Bir sonraki frame'de yeniden yükle
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() => _tabLoaded[tabIndex] = true);
  });
}
```

### Pull-to-Refresh

`RefreshIndicator` ile sarılmış her sekme içeriği, yenileme işleminde tüm sekmelerin önbelleğini temizler:

```dart
Future<void> _onRefresh() async {
  CacheManager.instance.clearPrefix('stats_');
  setState(() {
    for (int i = 0; i < _tabLoaded.length; i++) {
      _tabLoaded[i] = false;
    }
    _tabLoaded[_tabController.index] = true;
  });
}
```

---

## Test Stratejisi

### Genel Yaklaşım

Bu özellik hem **birim testleri** hem de **özellik tabanlı testler (property-based testing)** gerektirir. Saf fonksiyonlar (tasarruf oranı hesaplama, ödeme oranı hesaplama, renk seçimi) property-based testing için idealdir; UI etkileşimleri ve durum yönetimi ise örnek tabanlı widget testleri ile kapsanır.

### Özellik Tabanlı Testler (Property-Based Testing)

**Kütüphane:** `dart_test` + `fast_check` (Dart için) veya `glados` paketi.

Her özellik testi minimum **100 iterasyon** çalıştırılmalıdır.

**Etiket formatı:** `// Feature: statistics-redesign, Property {N}: {property_text}`

#### Özellik 1 & 2: Tasarruf Oranı Hesaplama

```dart
// Feature: statistics-redesign, Property 1: savings rate calculation correctness
// Feature: statistics-redesign, Property 2: zero income returns null
test('savingsRate hesaplama özellikleri', () {
  // Property 1: income > 0 için doğru hesaplama
  forAll(
    arbitrary<double>().where((v) => v > 0),  // income
    arbitrary<double>(),                        // expense
    (income, expense) {
      final rate = SavingsRateTrendData.calculateRate(income, expense);
      expect(rate, closeTo((income - expense) / income * 100, 1e-9));
    },
  );

  // Property 2: income = 0 için null
  forAll(
    arbitrary<double>(),  // expense (herhangi bir değer)
    (expense) {
      final rate = SavingsRateTrendData.calculateRate(0, expense);
      expect(rate, isNull);
    },
  );
});
```

#### Özellik 3: Fatura Ödeme Oranı

```dart
// Feature: statistics-redesign, Property 3: bill payment rate calculation
test('fatura ödeme oranı hesaplama', () {
  forAll(
    arbitrary<int>().where((v) => v >= 0),  // paidCount
    arbitrary<int>().where((v) => v > 0),   // totalCount (> 0)
    (paid, total) {
      // paid <= total olmalı (gerçekçi senaryo)
      final actualPaid = paid % (total + 1);
      final rate = BillHistorySummary.calculatePaymentRate(actualPaid, total);
      expect(rate, closeTo((actualPaid / total) * 100, 1e-9));
    },
  );
});
```

#### Özellik 4: Renk Kodlaması

```dart
// Feature: statistics-redesign, Property 4: bill payment rate color coding
test('ödeme oranı renk kodlaması tutarlılığı', () {
  forAll(
    arbitrary<double>().where((v) => v >= 0 && v <= 200),
    (rate) {
      final color = BillHistorySummaryCard.colorForRate(rate);
      if (rate >= 100) {
        expect(color, equals(AppColors.success));
      } else if (rate >= 50) {
        expect(color, equals(AppColors.warning));
      } else {
        expect(color, equals(AppColors.error));
      }
    },
  );
});
```

#### Özellik 5: Filtre Değişiminde Sıfırlama

```dart
// Feature: statistics-redesign, Property 5: filter change resets all tabs
test('filtre değişiminde tüm sekmeler sıfırlanır', () {
  forAll(
    arbitrary<TimeFilter>(),  // herhangi bir filtre değeri
    (newFilter) {
      final state = createTestState();
      // Bazı sekmeleri yüklenmiş olarak işaretle
      state.tabLoaded[0] = true;
      state.tabLoaded[3] = true;

      state.onFilterChanged(newFilter);

      // Tüm sekmeler sıfırlanmış olmalı (aktif sekme hariç)
      for (int i = 0; i < 7; i++) {
        if (i != state.activeTabIndex) {
          expect(state.tabLoaded[i], isFalse);
        }
      }
    },
  );
});
```

#### Özellik 6: Geçersiz Tarih Aralığı

```dart
// Feature: statistics-redesign, Property 6: invalid date range rejection
test('geçersiz tarih aralığı reddedilir', () {
  forAll(
    arbitrary<DateTime>(),  // startDate
    arbitrary<DateTime>(),  // endDate
    (start, end) {
      if (end.isBefore(start)) {
        // Geçersiz aralık: filtre uygulanmamalı
        final result = validateDateRange(start, end);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, isNotNull);
      }
    },
  );
});
```

#### Özellik 7: Lazy Loading

```dart
// Feature: statistics-redesign, Property 7: lazy loading tab isolation
test('lazy loading sekme izolasyonu', () {
  forAll(
    arbitrary<int>().where((v) => v >= 0 && v < 7),  // sekme indeksi
    (tabIndex) {
      final state = createTestState();
      // Başlangıçta hiçbir sekme yüklü değil
      expect(state.tabLoaded.every((v) => !v), isTrue);

      state.visitTab(tabIndex);

      // Yalnızca ziyaret edilen sekme yüklü
      expect(state.tabLoaded[tabIndex], isTrue);
      for (int i = 0; i < 7; i++) {
        if (i != tabIndex) {
          expect(state.tabLoaded[i], isFalse);
        }
      }
    },
  );
});
```

### Birim Testleri (Örnek Tabanlı)

Birim testleri, property testlerinin kapsamadığı spesifik senaryolara odaklanır:

- **Sekme sayısı:** `TabController.length == 7`
- **Varsayılan sekme:** Ekran açıldığında Özet sekmesi (index 0) aktif
- **Durum widget'ı münhasırlığı:** Yükleme/boş/hata durumlarında yalnızca bir widget görünür
- **"Tekrar Dene" butonu:** Hata durumunda butona basıldığında `_tabLoaded[i] = false` → yeniden yükleme
- **Pull-to-refresh:** Tüm önbellek temizlenir, tüm `_tabLoaded` sıfırlanır
- **Özel tarih aralığı:** Geçerli aralık seçildiğinde filtre uygulanır

### Widget Testleri

- Her sekme için yükleme/boş/hata durumu render testleri
- `SavingsRateTrendChart`: pozitif/negatif oran renk doğrulaması
- `BillHistorySummaryCard`: boş durum ve dolu durum render testleri
- `TimeFilterBar`: filtre değişiminde callback tetiklenmesi

### Entegrasyon Testleri

- `StatisticsService.analyzeAssets()` ile `FinancialHealthScoreCard` entegrasyonu
- `CacheManager` önbellek hit/miss senaryoları
- Sekme geçişlerinde `IndexedStack` durum koruması

### PBT Uygulanmayan Alanlar

Aşağıdaki gereksinimler için PBT uygun değildir; bunun yerine belirtilen alternatif test stratejileri kullanılır:

| Gereksinim | Neden PBT Değil | Alternatif |
|---|---|---|
| Design System renk tutarlılığı (Gereksinim 13) | Kod kalitesi kuralı, fonksiyonel davranış değil | Statik analiz / kod incelemesi |
| IndexedStack kullanımı (Gereksinim 1.5) | Mimari yapı, girdi değişkenliği yok | Tek widget testi |
| Skeleton animasyonu (Gereksinim 14.5) | UI görsel davranışı | Snapshot testi |
| Erişilebilirlik (Gereksinim 19) | Manuel test + Semantics widget kontrolü | Accessibility audit |
