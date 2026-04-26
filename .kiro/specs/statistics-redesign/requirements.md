# Gereksinimler Belgesi: İstatistik Ekranı Yeniden Tasarımı

## Giriş

Bu belge, Parion kişisel finans uygulamasının istatistik ekranının kapsamlı yeniden tasarımını tanımlar. Mevcut yapıda beş ayrı istatistik ekranı (ana istatistik ekranı, borç istatistikleri, tekrarlayan işlem istatistikleri, kart raporları ve varlık analizi) dağınık biçimde konumlanmaktadır. Yeniden tasarımın amacı; bu ekranları tutarlı bir navigasyon yapısı altında birleştirmek, eksik analiz bölümlerini (bütçe takibi, tasarruf oranı trendi, net değer trendi, harcama alışkanlıkları, gelir kaynakları dağılımı) eklemek, mevcut içerikleri iyileştirmek, Design System token'larını (AppColors, AppTextStyles, AppSpacing) tam olarak uygulamak ve performansı artırmaktır.

## Sözlük

- **Statistics_Screen**: Uygulamanın tüm finansal analiz ve raporlama işlevlerini barındıran ana istatistik ekranı.
- **Time_Filter**: Günlük, haftalık, aylık, yıllık ve özel tarih aralığı seçeneklerini sunan zaman filtresi bileşeni.
- **Tab_Controller**: İstatistik ekranındaki sekmeleri yöneten Flutter TabController.
- **Budget_Tracker**: Kategori bazlı bütçe hedefleri ile gerçek harcamaları karşılaştıran bölüm.
- **Savings_Rate**: Belirli bir dönemde (gelir - gider) / gelir formülüyle hesaplanan tasarruf oranı yüzdesi.
- **Net_Worth**: Toplam varlıklar (nakit + banka + yatırım) eksi toplam borçlar (kredi kartı + KMH + krediler + borçlar) olarak hesaplanan net değer.
- **Spending_Habits**: Harcamaların haftanın günlerine ve günün saatlerine göre dağılımını gösteren analiz bölümü.
- **Income_Sources**: Gelir işlemlerinin kategorilere göre dağılımını gösteren pasta/bar grafik bölümü.
- **Bill_History**: Fatura şablonlarına ait ödeme geçmişini ve ödeme oranını özetleyen bölüm.
- **Financial_Health_Score**: Likidite, borç yönetimi, tasarruf ve yatırım alt skorlarından oluşan 0-100 arası genel finansal sağlık skoru.
- **Design_System**: AppColors, AppTextStyles ve AppSpacing sınıflarından oluşan merkezi tasarım altyapısı.
- **Statistics_Loading_State**: Veri yüklenirken gösterilen iskelet (skeleton) animasyonlu yükleme widget'ı.
- **Statistics_Empty_State**: Veri bulunmadığında gösterilen yönlendirici boş durum widget'ı.
- **Statistics_Error_State**: Hata oluştuğunda gösterilen ve yeniden deneme seçeneği sunan hata durumu widget'ı.
- **KMH**: Kredili Mevduat Hesabı; negatif bakiyeli özel hesap türü.
- **Cache_Manager**: İstatistik verilerini bellekte önbelleğe alan ve gereksiz servis çağrılarını önleyen yönetici sınıf.

---

## Gereksinimler

### Gereksinim 1: Navigasyon ve Tab Yapısının Yeniden Düzenlenmesi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, tüm finansal analizlere tek bir ekrandan erişmek istiyorum; böylece borç istatistikleri, kart raporları ve tekrarlayan işlem analizleri için ayrı ekranlara gitmem gerekmez.

#### Kabul Kriterleri

1. THE Statistics_Screen SHALL 7 sekme içermelidir: Özet, Harcama, Nakit Akışı, Varlıklar, Borç/Alacak, Kartlar ve Tekrarlayan.
2. THE Statistics_Screen SHALL mevcut `debt_statistics_screen.dart` içeriğini Borç/Alacak sekmesine taşımalıdır.
3. THE Statistics_Screen SHALL mevcut `card_reporting_screen.dart` içeriğini Kartlar sekmesine taşımalıdır.
4. THE Statistics_Screen SHALL mevcut `recurring_statistics_screen.dart` içeriğini Tekrarlayan sekmesine taşımalıdır.
5. THE Tab_Controller SHALL sekme geçişlerinde `IndexedStack` kullanarak gereksiz widget rebuild'lerini önlemelidir.
6. WHEN kullanıcı bir sekmeye ilk kez geçtiğinde, THE Statistics_Screen SHALL o sekmenin verilerini lazy olarak yüklemelidir.
7. THE Statistics_Screen SHALL sekme başlıklarını kaydırılabilir (scrollable) TabBar ile göstermelidir; böylece dar ekranlarda tüm sekmeler erişilebilir olur.
8. WHEN Statistics_Screen açıldığında, THE Tab_Controller SHALL varsayılan olarak Özet sekmesini göstermelidir.

---

### Gereksinim 2: Evrensel Zaman Filtresi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, seçtiğim zaman filtresinin tüm sekmelere aynı anda uygulanmasını istiyorum; böylece farklı sekmelerde farklı dönemlere ait veriler görmem.

#### Kabul Kriterleri

1. THE Time_Filter SHALL Statistics_Screen'in üst kısmında tüm sekmeler için ortak bir konumda gösterilmelidir.
2. THE Time_Filter SHALL şu seçenekleri içermelidir: Günlük, Haftalık, Aylık, Yıllık ve Özel.
3. WHEN kullanıcı Time_Filter'da bir seçenek değiştirdiğinde, THE Statistics_Screen SHALL tüm sekmelerdeki verileri seçilen zaman aralığına göre yeniden hesaplamalıdır.
4. WHEN kullanıcı Özel seçeneğini seçtiğinde, THE Time_Filter SHALL başlangıç ve bitiş tarihi seçimi için bir tarih aralığı seçici göstermelidir.
5. IF kullanıcı Özel seçeneğinde bitiş tarihini başlangıç tarihinden önce seçerse, THEN THE Time_Filter SHALL bir hata mesajı göstermeli ve geçersiz aralığı uygulamamalıdır.
6. THE Time_Filter SHALL seçili filtreyi uygulama oturumu boyunca hatırlamalıdır; sekme değiştirildiğinde sıfırlanmamalıdır.

---

### Gereksinim 3: Özet Sekmesi — Finansal Genel Bakış

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, istatistik ekranını açtığımda seçili dönemin finansal özetini tek bakışta görmek istiyorum; böylece gelir, gider, tasarruf oranı ve net değerimi hızlıca anlayabilirim.

#### Kabul Kriterleri

1. THE Özet_Sekmesi SHALL seçili dönem için toplam gelir, toplam gider ve net nakit akışını özet kartlarda göstermelidir.
2. THE Özet_Sekmesi SHALL Savings_Rate değerini yüzde olarak göstermelidir; Savings_Rate = (gelir - gider) / gelir × 100 formülü kullanılmalıdır.
3. THE Özet_Sekmesi SHALL Financial_Health_Score'u görsel bir gösterge (gauge veya progress ring) ile göstermelidir; skor rengi 80+ için yeşil, 60-79 için açık yeşil, 40-59 için turuncu, 0-39 için kırmızı olmalıdır.
4. THE Özet_Sekmesi SHALL dönem karşılaştırmasını (önceki dönemle fark ve yüzde değişim) göstermelidir.
5. THE Özet_Sekmesi SHALL ödeme yöntemi dağılımını (nakit, banka, kredi kartı) pasta grafik ile göstermelidir.
6. THE Özet_Sekmesi SHALL gelir/borç oranını göstermelidir.
7. WHEN Özet_Sekmesi yüklendiğinde ve veri mevcut değilse, THE Özet_Sekmesi SHALL Statistics_Empty_State widget'ını göstermelidir.
8. WHEN Özet_Sekmesi yüklenirken, THE Özet_Sekmesi SHALL Statistics_Loading_State widget'ını göstermelidir.
9. IF Özet_Sekmesi veri yüklemede hata alırsa, THEN THE Özet_Sekmesi SHALL Statistics_Error_State widget'ını ve "Tekrar Dene" butonunu göstermelidir.

---

### Gereksinim 4: Bütçe Takibi Bölümü

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, her kategori için belirlediğim bütçeye karşı gerçek harcamalarımı görmek istiyorum; böylece hangi kategorilerde bütçemi aştığımı anlık olarak takip edebilirim.

#### Kabul Kriterleri

1. THE Budget_Tracker SHALL Özet sekmesinde veya ayrı bir Bütçe alt bölümünde kategori bazlı bütçe vs gerçek harcama karşılaştırmasını göstermelidir.
2. THE Budget_Tracker SHALL her kategori için bütçe tutarı, harcanan tutar, kalan tutar ve kullanım yüzdesini göstermelidir.
3. THE Budget_Tracker SHALL bütçeyi aşan kategorileri kırmızı renk ve uyarı ikonu ile vurgulamalıdır.
4. THE Budget_Tracker SHALL genel bütçe özetini (toplam bütçe, toplam harcanan, kontrol altındaki kategori sayısı) göstermelidir.
5. WHEN bir kategorinin harcaması bütçesinin %80'ini geçtiğinde, THE Budget_Tracker SHALL o kategori için sarı renk uyarısı göstermelidir.
6. WHEN bir kategorinin harcaması bütçesini aştığında, THE Budget_Tracker SHALL o kategori için kırmızı renk uyarısı ve aşım miktarını göstermelidir.
7. IF hiçbir kategori için bütçe tanımlanmamışsa, THEN THE Budget_Tracker SHALL kullanıcıyı bütçe oluşturmaya yönlendiren bir boş durum mesajı göstermelidir.
8. THE Budget_Tracker SHALL Time_Filter ile senkronize çalışmalıdır; seçili dönemin harcamaları kullanılmalıdır.

---

### Gereksinim 5: Tasarruf Oranı Trendi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, aylık tasarruf oranımın zaman içindeki değişimini görmek istiyorum; böylece finansal alışkanlıklarımın iyileşip iyileşmediğini anlayabilirim.

#### Kabul Kriterleri

1. THE Savings_Rate_Trend SHALL Özet sekmesinde çizgi grafik olarak gösterilmelidir.
2. THE Savings_Rate_Trend SHALL son 12 aya ait aylık Savings_Rate değerlerini göstermelidir.
3. THE Savings_Rate_Trend SHALL pozitif tasarruf oranlarını yeşil, negatif oranları kırmızı renk ile göstermelidir.
4. THE Savings_Rate_Trend SHALL grafiğin üzerinde ortalama tasarruf oranını yatay referans çizgisi olarak göstermelidir.
5. WHEN kullanıcı grafik üzerindeki bir noktaya dokunduğunda, THE Savings_Rate_Trend SHALL o aya ait gelir, gider ve tasarruf oranı değerlerini tooltip olarak göstermelidir.
6. IF seçili dönemde gelir sıfır ise, THEN THE Savings_Rate_Trend SHALL o dönem için tasarruf oranını "Veri Yok" olarak göstermelidir.

---

### Gereksinim 6: Net Değer (Net Worth) Trendi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, net değerimin aylık değişimini görmek istiyorum; böylece toplam varlıklarımın ve borçlarımın zaman içindeki seyrini takip edebilirim.

#### Kabul Kriterleri

1. THE Net_Worth_Trend SHALL Varlıklar sekmesinde çizgi grafik olarak gösterilmelidir.
2. THE Net_Worth_Trend SHALL son 12 aya ait aylık Net_Worth, toplam varlık ve toplam borç değerlerini ayrı çizgilerle göstermelidir.
3. THE Net_Worth_Trend SHALL her çizgi için açma/kapama toggle'ları içermelidir.
4. WHEN kullanıcı grafik üzerindeki bir noktaya dokunduğunda, THE Net_Worth_Trend SHALL o aya ait Net_Worth, varlık ve borç değerlerini ve bir önceki aya göre değişimi göstermelidir.
5. WHERE kullanıcı bir hedef net değer belirlemiş ise, THE Net_Worth_Trend SHALL hedef değeri yatay referans çizgisi olarak göstermeli ve hedefe olan mesafeyi ilerleme çubuğu ile göstermelidir.
6. THE Net_Worth_Trend SHALL mevcut `net_worth_trend_chart.dart` widget'ını kullanmalı ve Design_System token'larıyla uyumlu hale getirmelidir.

---

### Gereksinim 7: Harcama Alışkanlıkları Analizi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, haftanın hangi günlerinde ve günün hangi saatlerinde en çok harcama yaptığımı görmek istiyorum; böylece harcama alışkanlıklarımı daha iyi anlayabilirim.

#### Kabul Kriterleri

1. THE Spending_Habits SHALL Harcama sekmesinde bar grafik olarak gösterilmelidir.
2. THE Spending_Habits SHALL haftanın 7 günü için harcama dağılımını bar grafik ile göstermelidir; en yüksek harcama günü kırmızı renk ile vurgulanmalıdır.
3. THE Spending_Habits SHALL günün 24 saatini 3'er saatlik dilimlere bölerek harcama dağılımını bar grafik ile göstermelidir.
4. THE Spending_Habits SHALL gün ve saat görünümleri arasında geçiş için SegmentedButton içermelidir.
5. THE Spending_Habits SHALL en çok harcama yapılan gün, en yoğun saat ve günlük ortalama harcama değerlerini özet kutucuklarda göstermelidir.
6. THE Spending_Habits SHALL harcama alışkanlığına göre otomatik içgörü mesajı üretmelidir (örn. "Hafta sonu harcamalarınız daha yüksek").
7. THE Spending_Habits SHALL Time_Filter ile senkronize çalışmalıdır.
8. IF seçili dönemde yeterli veri yoksa (10'dan az işlem), THEN THE Spending_Habits SHALL "Yeterli veri bulunmamaktadır" mesajı göstermelidir.

---

### Gereksinim 8: Gelir Kaynakları Dağılımı

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, gelirimin hangi kategorilerden geldiğini görmek istiyorum; böylece gelir çeşitlendirmemi değerlendirebilirim.

#### Kabul Kriterleri

1. THE Income_Sources SHALL Özet veya Nakit Akışı sekmesinde interaktif pasta grafik olarak gösterilmelidir.
2. THE Income_Sources SHALL her gelir kategorisinin toplam gelir içindeki yüzdesini ve tutarını göstermelidir.
3. THE Income_Sources SHALL kategorileri yüzdeye göre büyükten küçüğe sıralı liste olarak pasta grafiğin yanında göstermelidir.
4. WHEN kullanıcı pasta grafiğin bir dilimine dokunduğunda, THE Income_Sources SHALL o kategorinin adını, tutarını ve yüzdesini vurgulamalıdır.
5. THE Income_Sources SHALL Time_Filter ile senkronize çalışmalıdır.
6. IF seçili dönemde gelir işlemi yoksa, THEN THE Income_Sources SHALL Statistics_Empty_State widget'ını göstermelidir.

---

### Gereksinim 9: Fatura Ödeme Geçmişi Özeti

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, faturalarımın ödeme geçmişini ve ödeme oranımı görmek istiyorum; böylece hangi faturaları düzenli ödediğimi ve hangilerini atladığımı anlayabilirim.

#### Kabul Kriterleri

1. THE Bill_History SHALL Özet sekmesinde fatura şablonu bazlı ödeme özeti göstermelidir.
2. THE Bill_History SHALL her fatura şablonu için toplam ödeme sayısı, ödenen sayısı ve ödeme oranı yüzdesini göstermelidir.
3. THE Bill_History SHALL ödeme oranı %100 olan faturaları yeşil, %50-99 arasındakileri sarı, %50'nin altındakileri kırmızı renk ile göstermelidir.
4. THE Bill_History SHALL son ödeme tarihini ve bir sonraki beklenen ödeme tarihini göstermelidir.
5. IF hiç fatura şablonu tanımlanmamışsa, THEN THE Bill_History SHALL kullanıcıyı fatura eklemeye yönlendiren bir boş durum mesajı göstermelidir.

---

### Gereksinim 10: Finansal Sağlık Skoru İyileştirmesi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, finansal sağlık skorumun nasıl hesaplandığını ve nasıl iyileştirebileceğimi net biçimde görmek istiyorum; böylece soyut bir sayı yerine eyleme dönüştürebileceğim öneriler alabilirim.

#### Kabul Kriterleri

1. THE Financial_Health_Score SHALL Özet sekmesinde görsel bir gauge (yarım daire gösterge) ile gösterilmelidir.
2. THE Financial_Health_Score SHALL dört alt skoru (Likidite, Borç Yönetimi, Tasarruf, Yatırım) ayrı ilerleme çubukları ile göstermelidir.
3. THE Financial_Health_Score SHALL her alt skor için kısa bir açıklama ve iyileştirme önerisi göstermelidir.
4. THE Financial_Health_Score SHALL skor değişimini önceki dönemle karşılaştırarak artış/azalış göstermelidir.
5. THE Financial_Health_Score SHALL mevcut `financial_health_score_card.dart` widget'ını kullanmalı ve Design_System token'larıyla uyumlu hale getirmelidir.
6. WHEN Financial_Health_Score hesaplanırken, THE Statistics_Screen SHALL StatisticsService.analyzeAssets() metodunu kullanmalıdır.

---

### Gereksinim 11: Varlık Analizi İyileştirmesi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, nakit, banka hesapları ve KMH hesaplarımı ayrı ayrı görmek istiyorum; böylece varlık dağılımımı net biçimde anlayabilirim.

#### Kabul Kriterleri

1. THE Varlıklar_Sekmesi SHALL normal cüzdanları (nakit + banka) ve KMH hesaplarını ayrı bölümlerde göstermelidir.
2. THE Varlıklar_Sekmesi SHALL toplam pozitif varlıklar, toplam KMH borcu ve net varlık değerini özet kartlarda göstermelidir.
3. THE Varlıklar_Sekmesi SHALL her cüzdan için bakiye, tür ikonu ve renk göstermelidir.
4. THE Varlıklar_Sekmesi SHALL KMH hesapları için kullanılan limit yüzdesini ilerleme çubuğu ile göstermelidir.
5. THE Varlıklar_Sekmesi SHALL Net_Worth_Trend grafiğini içermelidir.
6. THE Varlıklar_Sekmesi SHALL mevcut `kmh_dashboard.dart`, `kmh_asset_card.dart` ve `net_worth_trend_chart.dart` widget'larını kullanmalıdır.
7. WHEN Varlıklar_Sekmesi yüklendiğinde ve hiç cüzdan yoksa, THE Varlıklar_Sekmesi SHALL Statistics_Empty_State widget'ını göstermelidir.

---

### Gereksinim 12: Kredi Sekmesi İyileştirmesi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, aktif kredilerimin durumunu ve ödeme takvimini görmek istiyorum; böylece toplam kredi yükümü ve yaklaşan ödemeleri takip edebilirim.

#### Kabul Kriterleri

1. THE Kredi_Sekmesi SHALL aktif kredilerin toplam kalan borcunu, aylık toplam ödeme tutarını ve aktif kredi sayısını özet kartlarda göstermelidir.
2. THE Kredi_Sekmesi SHALL her kredi için ödeme ilerleme çubuğu, kalan borç, toplam borç ve sıradaki taksit tarihini göstermelidir.
3. THE Kredi_Sekmesi SHALL kredi türüne göre (konut, taşıt, ihtiyaç) ikon ve renk ataması yapmalıdır.
4. WHEN tüm krediler ödenmiş ise, THE Kredi_Sekmesi SHALL kutlama mesajı içeren bir boş durum göstermelidir.
5. WHEN hiç kredi yoksa, THE Kredi_Sekmesi SHALL Statistics_Empty_State widget'ını göstermelidir.

---

### Gereksinim 13: Design System Entegrasyonu

**Kullanıcı Hikayesi:** Bir geliştirici olarak, istatistik ekranındaki tüm renk, tipografi ve boşluk değerlerinin Design System token'larından gelmesini istiyorum; böylece tema değişikliklerinde tüm ekran otomatik olarak güncellenir.

#### Kabul Kriterleri

1. THE Statistics_Screen VE tüm istatistik widget'ları SHALL hardcoded `Color(0xFF...)` değerleri yerine `AppColors` token'larını kullanmalıdır.
2. THE Statistics_Screen VE tüm istatistik widget'ları SHALL inline `TextStyle` tanımları yerine `AppTextStyles` sınıfından ilgili stilleri kullanmalıdır.
3. THE Statistics_Screen VE tüm istatistik widget'ları SHALL hardcoded padding/margin değerleri yerine `AppSpacing` sabitlerini kullanmalıdır.
4. THE Statistics_Screen SHALL hem light hem dark temada görsel olarak doğru görünmelidir; `Theme.of(context)` üzerinden renk ve stil değerlerine erişilmelidir.
5. IF bir istatistik widget'ında `Colors.white`, `Colors.black` veya `Colors.grey` hardcoded renk kullanılıyorsa, THEN THE widget SHALL bu rengi ilgili `AppColors` token'ı veya `Theme.of(context)` değeri ile değiştirmelidir.
6. THE fatura kategorisi renk haritası (`_billCategoryColors`) SHALL `AppColors` token'larına taşınmalıdır.

---

### Gereksinim 14: Durum Yönetimi Tutarlılığı

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, her sekme yüklenirken, veri yokken veya hata oluştuğunda tutarlı ve anlaşılır geri bildirimler görmek istiyorum.

#### Kabul Kriterleri

1. THE Statistics_Screen'deki her sekme SHALL veri yüklenirken `statistics_loading_state.dart` widget'ını göstermelidir.
2. THE Statistics_Screen'deki her sekme SHALL veri boş olduğunda `statistics_empty_state.dart` widget'ını göstermelidir.
3. THE Statistics_Screen'deki her sekme SHALL hata oluştuğunda `statistics_error_state.dart` widget'ını ve "Tekrar Dene" butonunu göstermelidir.
4. WHEN "Tekrar Dene" butonuna basıldığında, THE Statistics_Screen SHALL ilgili sekmenin verilerini yeniden yüklemelidir.
5. THE Statistics_Loading_State SHALL skeleton animasyonu kullanmalıdır; düz `CircularProgressIndicator` kullanılmamalıdır.
6. THE Statistics_Empty_State SHALL kullanıcıyı ilgili veriyi oluşturmaya yönlendiren bir aksiyon butonu içermelidir.

---

### Gereksinim 15: Performans ve Önbellekleme

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, istatistik ekranının hızlı açılmasını ve sekme geçişlerinde tekrar yükleme beklememek istiyorum.

#### Kabul Kriterleri

1. THE Statistics_Screen SHALL sekme içeriklerini lazy loading ile yüklemelidir; yalnızca aktif sekmenin verisi yüklenmelidir.
2. THE Statistics_Screen SHALL `Cache_Manager` kullanarak hesaplanan istatistik verilerini önbelleğe almalıdır; aynı zaman filtresi ve sekme için tekrar servis çağrısı yapılmamalıdır.
3. WHEN Time_Filter değiştiğinde, THE Statistics_Screen SHALL ilgili sekmenin önbelleğini geçersiz kılmalı ve veriyi yeniden yüklemelidir.
4. WHEN bir liste 50'den fazla öğe içerdiğinde, THE Statistics_Screen SHALL `ListView.builder` ile lazy rendering kullanmalıdır.
5. THE Statistics_Screen SHALL pull-to-refresh desteği sunmalıdır; yenileme işlemi tüm sekmelerin önbelleğini temizlemelidir.
6. THE Statistics_Screen SHALL ağır hesaplamaları (istatistik agregasyonu, grafik veri hazırlama) ana thread'i bloke etmemek için `compute` veya `Isolate` kullanmalıdır.

---

### Gereksinim 16: Borç/Alacak Sekmesi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, verdiğim ve aldığım borçların istatistiklerini ana istatistik ekranından görmek istiyorum; böylece ayrı bir ekrana geçmem gerekmez.

#### Kabul Kriterleri

1. THE Borç_Alacak_Sekmesi SHALL toplam alacak, toplam borç, net durum ve aktif borç sayısını özet kartlarda göstermelidir.
2. THE Borç_Alacak_Sekmesi SHALL vadesi geçmiş borç/alacak sayısını uyarı rengi ile göstermelidir.
3. THE Borç_Alacak_Sekmesi SHALL borç/alacak kategorisi dağılımını (arkadaş, aile, iş, diğer) pasta grafik ile göstermelidir.
4. THE Borç_Alacak_Sekmesi SHALL en yüksek tutarlı 5 borç/alacağı liste olarak göstermelidir.
5. THE Borç_Alacak_Sekmesi SHALL mevcut `debt_statistics_screen.dart` içeriğini kullanmalı ve Design_System token'larıyla uyumlu hale getirmelidir.
6. IF hiç borç/alacak kaydı yoksa, THEN THE Borç_Alacak_Sekmesi SHALL Statistics_Empty_State widget'ını göstermelidir.

---

### Gereksinim 17: Kartlar Sekmesi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, kredi kartı raporlarıma ana istatistik ekranından erişmek istiyorum; böylece kart harcama trendlerimi ve faiz ödemelerimi tek yerden görebilirim.

#### Kabul Kriterleri

1. THE Kartlar_Sekmesi SHALL mevcut `card_reporting_screen.dart` içeriğini (Genel Bakış, Harcama Trendi, Kategori Analizi, Faiz Raporu, Kart Karşılaştırma) iç sekmeler veya kaydırılabilir bölümler olarak içermelidir.
2. THE Kartlar_Sekmesi SHALL kart seçici dropdown'ı ile belirli bir kart için filtreleme yapabilmelidir.
3. THE Kartlar_Sekmesi SHALL limit kullanım oranlarını ilerleme çubukları ile göstermelidir.
4. THE Kartlar_Sekmesi SHALL aylık harcama trendini çizgi grafik ile göstermelidir.
5. THE Kartlar_Sekmesi SHALL Design_System token'larını kullanmalıdır; mevcut hardcoded `Color(0xFF00BFA5)` değerleri `AppColors` token'larıyla değiştirilmelidir.
6. IF hiç kredi kartı tanımlanmamışsa, THEN THE Kartlar_Sekmesi SHALL Statistics_Empty_State widget'ını göstermelidir.

---

### Gereksinim 18: Tekrarlayan İşlemler Sekmesi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, tekrarlayan gelir ve giderlerimin istatistiklerini ana istatistik ekranından görmek istiyorum.

#### Kabul Kriterleri

1. THE Tekrarlayan_Sekmesi SHALL toplam tekrarlayan gelir, toplam tekrarlayan gider ve net değeri özet kartlarda göstermelidir.
2. THE Tekrarlayan_Sekmesi SHALL kategori bazlı tekrarlayan işlem dağılımını pasta grafik ile göstermelidir.
3. THE Tekrarlayan_Sekmesi SHALL kategori detaylarını yüzde ve tutar bilgisiyle liste olarak göstermelidir.
4. THE Tekrarlayan_Sekmesi SHALL mevcut `recurring_statistics_screen.dart` içeriğini kullanmalı ve Design_System token'larıyla uyumlu hale getirmelidir.
5. IF hiç tekrarlayan işlem tanımlanmamışsa, THEN THE Tekrarlayan_Sekmesi SHALL Statistics_Empty_State widget'ını göstermelidir.

---

### Gereksinim 19: Erişilebilirlik

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, istatistik ekranındaki tüm etkileşimli öğelerin yeterince büyük dokunma hedeflerine sahip olmasını ve ekran okuyucularla uyumlu çalışmasını istiyorum.

#### Kabul Kriterleri

1. THE Statistics_Screen'deki tüm dokunulabilir widget'lar SHALL minimum 44×44 piksel dokunma hedefi boyutuna sahip olmalıdır.
2. THE Statistics_Screen'deki tüm grafikler SHALL `Semantics` widget'ı ile ekran okuyucu için açıklayıcı etiket içermelidir.
3. THE Statistics_Screen'deki renk kodlamaları SHALL renk körü kullanıcılar için ikon veya metin ile desteklenmelidir; yalnızca renge bağımlı bilgi aktarımından kaçınılmalıdır.
4. THE Statistics_Screen SHALL sistem yazı boyutu ayarlarına (large text) uyum sağlamalıdır; metin taşmaları önlenmelidir.
