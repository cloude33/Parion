import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @cards.
  ///
  /// In tr, this message translates to:
  /// **'Kartlar'**
  String get cards;

  /// No description provided for @stats.
  ///
  /// In tr, this message translates to:
  /// **'İstatistik'**
  String get stats;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @income.
  ///
  /// In tr, this message translates to:
  /// **'Gelir'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In tr, this message translates to:
  /// **'Gider'**
  String get expense;

  /// No description provided for @addTransaction.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Ekle'**
  String get addTransaction;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @generalSettings.
  ///
  /// In tr, this message translates to:
  /// **'Genel Ayarlar'**
  String get generalSettings;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @netWorth.
  ///
  /// In tr, this message translates to:
  /// **'Net Varlık'**
  String get netWorth;

  /// No description provided for @totalAssets.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Varlık'**
  String get totalAssets;

  /// No description provided for @totalDebts.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Borç'**
  String get totalDebts;

  /// No description provided for @selectLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçin'**
  String get selectLanguage;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @transactions.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get transactions;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterday;

  /// No description provided for @addExpense.
  ///
  /// In tr, this message translates to:
  /// **'Gider Ekle'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In tr, this message translates to:
  /// **'Gelir Ekle'**
  String get addIncome;

  /// No description provided for @addBill.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Ekle'**
  String get addBill;

  /// No description provided for @addWallet.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan Ekle'**
  String get addWallet;

  /// No description provided for @addCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Ekle'**
  String get addCategory;

  /// No description provided for @addDebt.
  ///
  /// In tr, this message translates to:
  /// **'Borç/Alacak Ekle'**
  String get addDebt;

  /// No description provided for @netLoss.
  ///
  /// In tr, this message translates to:
  /// **'Net Kayıp'**
  String get netLoss;

  /// No description provided for @netGain.
  ///
  /// In tr, this message translates to:
  /// **'Net Kâr'**
  String get netGain;

  /// No description provided for @accountSection.
  ///
  /// In tr, this message translates to:
  /// **'HESAP'**
  String get accountSection;

  /// No description provided for @generalSection.
  ///
  /// In tr, this message translates to:
  /// **'GENEL'**
  String get generalSection;

  /// No description provided for @dataSection.
  ///
  /// In tr, this message translates to:
  /// **'VERİ YÖNETİMİ'**
  String get dataSection;

  /// No description provided for @securitySection.
  ///
  /// In tr, this message translates to:
  /// **'GÜVENLİK'**
  String get securitySection;

  /// No description provided for @otherSection.
  ///
  /// In tr, this message translates to:
  /// **'DİĞER'**
  String get otherSection;

  /// No description provided for @dangerZone.
  ///
  /// In tr, this message translates to:
  /// **'TEHLİKELİ BÖLGE'**
  String get dangerZone;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @changePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get changePassword;

  /// No description provided for @myWallets.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlarım'**
  String get myWallets;

  /// No description provided for @myBills.
  ///
  /// In tr, this message translates to:
  /// **'Faturalarım'**
  String get myBills;

  /// No description provided for @categories.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get categories;

  /// No description provided for @debts.
  ///
  /// In tr, this message translates to:
  /// **'Borç/Alacak Takibi'**
  String get debts;

  /// No description provided for @loans.
  ///
  /// In tr, this message translates to:
  /// **'Kredilerim'**
  String get loans;

  /// No description provided for @manageLoansDesc.
  ///
  /// In tr, this message translates to:
  /// **'Banka kredilerinizi takip edin'**
  String get manageLoansDesc;

  /// No description provided for @recurringTransactions.
  ///
  /// In tr, this message translates to:
  /// **'Tekrarlayan İşlemler'**
  String get recurringTransactions;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @currency.
  ///
  /// In tr, this message translates to:
  /// **'Para Birimi'**
  String get currency;

  /// No description provided for @export.
  ///
  /// In tr, this message translates to:
  /// **'Dışa Aktar'**
  String get export;

  /// No description provided for @backup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükle'**
  String get restore;

  /// No description provided for @cloudBackup.
  ///
  /// In tr, this message translates to:
  /// **'Bulut Yedekleme'**
  String get cloudBackup;

  /// No description provided for @autoLock.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik Kilit'**
  String get autoLock;

  /// No description provided for @biometricAuth.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik Kimlik Doğrulama'**
  String get biometricAuth;

  /// No description provided for @help.
  ///
  /// In tr, this message translates to:
  /// **'Yardım'**
  String get help;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @resetApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Sıfırla'**
  String get resetApp;

  /// No description provided for @userDefault.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get userDefault;

  /// No description provided for @notSpecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmemiş'**
  String get notSpecified;

  /// No description provided for @updatePasswordDesc.
  ///
  /// In tr, this message translates to:
  /// **'Giriş şifrenizi güncelleyin'**
  String get updatePasswordDesc;

  /// No description provided for @manageWalletsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlarınızı ve hesaplarınızı yönetin'**
  String get manageWalletsDesc;

  /// No description provided for @manageBillsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Fatura şablonlarınızı yönetin'**
  String get manageBillsDesc;

  /// No description provided for @manageCategoriesDesc.
  ///
  /// In tr, this message translates to:
  /// **'Gelir ve gider kategorilerini yönetin'**
  String get manageCategoriesDesc;

  /// No description provided for @trackDebtsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Borç ve alacaklarınızı takip edin'**
  String get trackDebtsDesc;

  /// No description provided for @manageRecurringDesc.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik işlemlerinizi yönetin'**
  String get manageRecurringDesc;

  /// No description provided for @notificationsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmalar ve uyarılar'**
  String get notificationsDesc;

  /// No description provided for @exportDesc.
  ///
  /// In tr, this message translates to:
  /// **'Verileri dışa aktar'**
  String get exportDesc;

  /// No description provided for @backupDesc.
  ///
  /// In tr, this message translates to:
  /// **'Verilerinizi yedekleyin'**
  String get backupDesc;

  /// No description provided for @restoreDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yedekten geri yükleyin'**
  String get restoreDesc;

  /// No description provided for @cloudBackupDesc.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive yedekleme'**
  String get cloudBackupDesc;

  /// No description provided for @biometricDesc.
  ///
  /// In tr, this message translates to:
  /// **'Parmak izi ile kilidi aç'**
  String get biometricDesc;

  /// No description provided for @faqDesc.
  ///
  /// In tr, this message translates to:
  /// **'SSS ve destek'**
  String get faqDesc;

  /// No description provided for @logoutDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hesaptan çık'**
  String get logoutDesc;

  /// No description provided for @resetAppDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verileri sil ve baştan başla'**
  String get resetAppDesc;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @amount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get description;

  /// No description provided for @category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @wallet.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan'**
  String get wallet;

  /// No description provided for @date.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get date;

  /// No description provided for @memo.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get memo;

  /// No description provided for @allTransactions.
  ///
  /// In tr, this message translates to:
  /// **'Tüm İşlemler'**
  String get allTransactions;

  /// No description provided for @list.
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get list;

  /// No description provided for @calendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get calendar;

  /// No description provided for @add.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get add;

  /// No description provided for @update.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get update;

  /// No description provided for @confirmDelete.
  ///
  /// In tr, this message translates to:
  /// **'Silmek istediğinize emin misiniz?'**
  String get confirmDelete;

  /// No description provided for @yes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get no;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get filter;

  /// No description provided for @clear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get apply;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı'**
  String get noData;

  /// No description provided for @errorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu'**
  String get errorOccurred;

  /// No description provided for @successMessage.
  ///
  /// In tr, this message translates to:
  /// **'İşlem başarılı'**
  String get successMessage;

  /// No description provided for @selectBill.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Seçin'**
  String get selectBill;

  /// No description provided for @pleaseSelectBill.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir fatura seçin'**
  String get pleaseSelectBill;

  /// No description provided for @billPeriod.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Dönemi'**
  String get billPeriod;

  /// No description provided for @billAdded.
  ///
  /// In tr, this message translates to:
  /// **'Fatura ödeme bilgisi eklendi'**
  String get billAdded;

  /// No description provided for @billFormInfo.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlarda tanımladığınız faturalar için bu ayın tutarını ve son ödeme tarihini girin.'**
  String get billFormInfo;

  /// No description provided for @dueTally.
  ///
  /// In tr, this message translates to:
  /// **'Son Ödeme Tarihi'**
  String get dueTally;

  /// No description provided for @paymentMethod.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Aracı'**
  String get paymentMethod;

  /// No description provided for @paymentMethodDesc.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik ödeme günü geldiğinde bu araçtan tahsil edilir'**
  String get paymentMethodDesc;

  /// No description provided for @noBillsDefined.
  ///
  /// In tr, this message translates to:
  /// **'Henüz fatura tanımlamadınız'**
  String get noBillsDefined;

  /// No description provided for @noBillsDefinedDesc.
  ///
  /// In tr, this message translates to:
  /// **'Önce Ayarlar > Faturalarım bölümünden fatura tanımlamanız gerekiyor'**
  String get noBillsDefinedDesc;

  /// No description provided for @defineBill.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Tanımla'**
  String get defineBill;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri Dön'**
  String get back;

  /// No description provided for @noTransactions.
  ///
  /// In tr, this message translates to:
  /// **'İşlem yok'**
  String get noTransactions;

  /// No description provided for @installment.
  ///
  /// In tr, this message translates to:
  /// **'Taksit'**
  String get installment;

  /// No description provided for @netBalance.
  ///
  /// In tr, this message translates to:
  /// **'Net Kazanç'**
  String get netBalance;

  /// No description provided for @backupAndExport.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle ve Dışa Aktar'**
  String get backupAndExport;

  /// No description provided for @backupAndExportDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yerel yedekleme, geri yükleme ve veri aktarımı'**
  String get backupAndExportDesc;

  /// No description provided for @minutes.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get minutes;

  /// No description provided for @version.
  ///
  /// In tr, this message translates to:
  /// **'Versiyon'**
  String get version;

  /// No description provided for @changeProfilePicture.
  ///
  /// In tr, this message translates to:
  /// **'Profil Resmini Değiştir'**
  String get changeProfilePicture;

  /// No description provided for @profilePictureChanged.
  ///
  /// In tr, this message translates to:
  /// **'Profil resmi başarıyla güncellendi'**
  String get profilePictureChanged;

  /// No description provided for @selectAuthMethod.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik doğrulama yöntemi seçin'**
  String get selectAuthMethod;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get english;

  /// No description provided for @autoLockDuration.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik Kilit Süresi'**
  String get autoLockDuration;

  /// No description provided for @resetWarningTitle.
  ///
  /// In tr, this message translates to:
  /// **'⚠️ Uyarı'**
  String get resetWarningTitle;

  /// No description provided for @resetWarningDesc.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı sıfırlamak üzeresiniz. Bu işlem:\n\n• Tüm kullanıcıları\n• Tüm cüzdanları\n• Tüm işlemleri\n• Tüm kredi kartlarını\n• Tüm borçları\n• Tüm ayarları\n\nkalıcı olarak silecektir. Bu işlem geri alınamaz!\n\nDevam etmek istediğinizden emin misiniz?'**
  String get resetWarningDesc;

  /// No description provided for @resetFinalWarningTitle.
  ///
  /// In tr, this message translates to:
  /// **'🚨 Son Uyarı'**
  String get resetFinalWarningTitle;

  /// No description provided for @resetFinalWarningDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem GERİ ALINAMAZ!\n\nTüm verileriniz kalıcı olarak silinecek.\n\nYedek almadıysanız, verilerinizi geri getiremezsiniz.\n\nUygulamayı sıfırlamak istediğinizden kesinlikle emin misiniz?'**
  String get resetFinalWarningDesc;

  /// No description provided for @resetSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama başarıyla sıfırlandı'**
  String get resetSuccess;

  /// No description provided for @yesReset.
  ///
  /// In tr, this message translates to:
  /// **'Evet, Sıfırla'**
  String get yesReset;

  /// No description provided for @continueText.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueText;

  /// No description provided for @profileUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Profil güncellendi'**
  String get profileUpdated;

  /// No description provided for @emailUpdated.
  ///
  /// In tr, this message translates to:
  /// **'E-posta güncellendi'**
  String get emailUpdated;

  /// No description provided for @failedToPickImage.
  ///
  /// In tr, this message translates to:
  /// **'Resim seçilemedi'**
  String get failedToPickImage;

  /// No description provided for @active.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get inactive;

  /// No description provided for @noRecurringTransactions.
  ///
  /// In tr, this message translates to:
  /// **'Henüz tekrarlayan işlem yok'**
  String get noRecurringTransactions;

  /// No description provided for @categoryInUse.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Kullanımda'**
  String get categoryInUse;

  /// No description provided for @categoryInUseDesc.
  ///
  /// In tr, this message translates to:
  /// **'{count} işlemde kullanılıyor. İşlemler silinmeyecek ancak kategori bilgisi kaybolacak.'**
  String categoryInUseDesc(Object count);

  /// No description provided for @deleteAnyway.
  ///
  /// In tr, this message translates to:
  /// **'Yine de Sil'**
  String get deleteAnyway;

  /// No description provided for @searchCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori ara...'**
  String get searchCategory;

  /// No description provided for @noCategories.
  ///
  /// In tr, this message translates to:
  /// **'Kategori bulunamadı'**
  String get noCategories;

  /// No description provided for @usage.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım'**
  String get usage;

  /// No description provided for @total.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get total;

  /// No description provided for @average.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama'**
  String get average;

  /// No description provided for @transactionCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} işlem'**
  String transactionCount(Object count);

  /// No description provided for @debtsTracking.
  ///
  /// In tr, this message translates to:
  /// **'Borç/Alacak Takibi'**
  String get debtsTracking;

  /// No description provided for @searchPerson.
  ///
  /// In tr, this message translates to:
  /// **'Kişi ara...'**
  String get searchPerson;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get all;

  /// No description provided for @lent.
  ///
  /// In tr, this message translates to:
  /// **'Verdiklerim'**
  String get lent;

  /// No description provided for @borrowed.
  ///
  /// In tr, this message translates to:
  /// **'Aldıklarım'**
  String get borrowed;

  /// No description provided for @summary.
  ///
  /// In tr, this message translates to:
  /// **'Özet'**
  String get summary;

  /// No description provided for @asset.
  ///
  /// In tr, this message translates to:
  /// **'Alacak'**
  String get asset;

  /// No description provided for @net.
  ///
  /// In tr, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @noDebts.
  ///
  /// In tr, this message translates to:
  /// **'Henüz borç/alacak kaydı yok'**
  String get noDebts;

  /// No description provided for @clickToAddDebt.
  ///
  /// In tr, this message translates to:
  /// **'Yeni eklemek için + butonuna tıklayın'**
  String get clickToAddDebt;

  /// No description provided for @paidPercentage.
  ///
  /// In tr, this message translates to:
  /// **'%{percentage} ödendi'**
  String paidPercentage(Object percentage);

  /// No description provided for @filteredTotal.
  ///
  /// In tr, this message translates to:
  /// **'Filtrelenmiş Toplam'**
  String get filteredTotal;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @bill.
  ///
  /// In tr, this message translates to:
  /// **'Fatura'**
  String get bill;

  /// No description provided for @createWalletFirst.
  ///
  /// In tr, this message translates to:
  /// **'İşlem eklemek için önce bir cüzdan oluşturmalısınız'**
  String get createWalletFirst;

  /// No description provided for @categorySuggestionApplied.
  ///
  /// In tr, this message translates to:
  /// **'Kategori önerisi uygulandı: {category}'**
  String categorySuggestionApplied(Object category);

  /// No description provided for @descriptionHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Market alışverişi'**
  String get descriptionHint;

  /// No description provided for @applySuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Öneriyi uygula'**
  String get applySuggestion;

  /// No description provided for @suggested.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen: {category}'**
  String suggested(Object category);

  /// No description provided for @confidence.
  ///
  /// In tr, this message translates to:
  /// **'%{percentage} güven'**
  String confidence(Object percentage);

  /// No description provided for @debtCategoryFriend.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaş'**
  String get debtCategoryFriend;

  /// No description provided for @debtCategoryFamily.
  ///
  /// In tr, this message translates to:
  /// **'Aile'**
  String get debtCategoryFamily;

  /// No description provided for @debtCategoryBusiness.
  ///
  /// In tr, this message translates to:
  /// **'İş'**
  String get debtCategoryBusiness;

  /// No description provided for @debtCategoryOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get debtCategoryOther;

  /// No description provided for @noDueDate.
  ///
  /// In tr, this message translates to:
  /// **'Vade yok'**
  String get noDueDate;

  /// No description provided for @paid.
  ///
  /// In tr, this message translates to:
  /// **'Ödendi'**
  String get paid;

  /// No description provided for @daysOverdue.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün gecikmiş'**
  String daysOverdue(Object days);

  /// No description provided for @dueToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün vade'**
  String get dueToday;

  /// No description provided for @daysLeft.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün kaldı'**
  String daysLeft(Object days);

  /// No description provided for @dueDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vade: {date}'**
  String dueDateLabel(Object date);

  /// No description provided for @editBillTemplate.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Şablonunu Düzenle'**
  String get editBillTemplate;

  /// No description provided for @addBillTemplate.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Şablonu Ekle'**
  String get addBillTemplate;

  /// No description provided for @billCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get billCategory;

  /// No description provided for @city.
  ///
  /// In tr, this message translates to:
  /// **'İl'**
  String get city;

  /// No description provided for @billAccountNumber.
  ///
  /// In tr, this message translates to:
  /// **'Abone/Müşteri Numarası'**
  String get billAccountNumber;

  /// No description provided for @billPhoneNumber.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Numarası'**
  String get billPhoneNumber;

  /// No description provided for @billAmount.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Tutar'**
  String get billAmount;

  /// No description provided for @billPaymentDay.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Günü'**
  String get billPaymentDay;

  /// No description provided for @autoPaymentWallet.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik Ödeme Cüzdanı'**
  String get autoPaymentWallet;

  /// No description provided for @billTemplateDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Fatura şablonu silindi'**
  String get billTemplateDeleted;

  /// No description provided for @confirmDeleteBillTemplate.
  ///
  /// In tr, this message translates to:
  /// **'Bu fatura şablonunu silmek istediğinize emin misiniz?'**
  String get confirmDeleteBillTemplate;

  /// No description provided for @billElectricity.
  ///
  /// In tr, this message translates to:
  /// **'Elektrik'**
  String get billElectricity;

  /// No description provided for @billWater.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get billWater;

  /// No description provided for @billGas.
  ///
  /// In tr, this message translates to:
  /// **'Doğalgaz'**
  String get billGas;

  /// No description provided for @billInternet.
  ///
  /// In tr, this message translates to:
  /// **'İnternet'**
  String get billInternet;

  /// No description provided for @billPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get billPhone;

  /// No description provided for @billRent.
  ///
  /// In tr, this message translates to:
  /// **'Kira'**
  String get billRent;

  /// No description provided for @billInsurance.
  ///
  /// In tr, this message translates to:
  /// **'Sigorta'**
  String get billInsurance;

  /// No description provided for @billSubscription.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik'**
  String get billSubscription;

  /// No description provided for @billOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get billOther;

  /// No description provided for @selectCity.
  ///
  /// In tr, this message translates to:
  /// **'İl Seçin'**
  String get selectCity;

  /// No description provided for @selectProvider.
  ///
  /// In tr, this message translates to:
  /// **'Kurum Seçin'**
  String get selectProvider;

  /// No description provided for @billProvider.
  ///
  /// In tr, this message translates to:
  /// **'Kurum'**
  String get billProvider;

  /// No description provided for @billName.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Adı'**
  String get billName;

  /// No description provided for @billProviderName.
  ///
  /// In tr, this message translates to:
  /// **'Kurum Adı'**
  String get billProviderName;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen ödeme aracı seçin'**
  String get selectPaymentMethod;

  /// No description provided for @roomShopNo.
  ///
  /// In tr, this message translates to:
  /// **'Daire / Dükkan No (Opsiyonel)'**
  String get roomShopNo;

  /// No description provided for @accountNumberLabel.
  ///
  /// In tr, this message translates to:
  /// **'Abone/Müşteri Numarası (Opsiyonel)'**
  String get accountNumberLabel;

  /// No description provided for @enterDayRange.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen 1-31 arasında bir gün girin'**
  String get enterDayRange;

  /// No description provided for @optional.
  ///
  /// In tr, this message translates to:
  /// **'(Opsiyonel)'**
  String get optional;

  /// No description provided for @hintExampleNumber.
  ///
  /// In tr, this message translates to:
  /// **'Örn: 123456789'**
  String get hintExampleNumber;

  /// No description provided for @hintExampleDay.
  ///
  /// In tr, this message translates to:
  /// **'Örn: 15'**
  String get hintExampleDay;

  /// No description provided for @hintExampleDescription.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Ev adresi için'**
  String get hintExampleDescription;

  /// No description provided for @phoneHint.
  ///
  /// In tr, this message translates to:
  /// **'5XX XXX XX XX'**
  String get phoneHint;

  /// No description provided for @paymentDayDescription.
  ///
  /// In tr, this message translates to:
  /// **'Her ayın {day}. günü'**
  String paymentDayDescription(Object day);

  /// No description provided for @noPaymentRecords.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ödeme kaydı yok'**
  String get noPaymentRecords;

  /// No description provided for @paymentRecordsHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu fatura için ödeme yaptığınızda burada görünecektir'**
  String get paymentRecordsHint;

  /// No description provided for @billDetail.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Detayı'**
  String get billDetail;

  /// No description provided for @statusPaid.
  ///
  /// In tr, this message translates to:
  /// **'Ödendi'**
  String get statusPaid;

  /// No description provided for @statusPending.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get statusPending;

  /// No description provided for @statusOverdue.
  ///
  /// In tr, this message translates to:
  /// **'Gecikmiş'**
  String get statusOverdue;

  /// No description provided for @editBill.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Düzenle'**
  String get editBill;

  /// No description provided for @autoPayment.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik Ödeme'**
  String get autoPayment;

  /// No description provided for @billPaid.
  ///
  /// In tr, this message translates to:
  /// **'Fatura ödendi olarak işaretlendi'**
  String get billPaid;

  /// No description provided for @billPaymentDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Fatura ödemesi silindi'**
  String get billPaymentDeleted;

  /// No description provided for @confirmDeleteBillPayment.
  ///
  /// In tr, this message translates to:
  /// **'Bu fatura ödemesini silmek istediğinize emin misiniz?'**
  String get confirmDeleteBillPayment;

  /// No description provided for @paymentDate.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Tarihi'**
  String get paymentDate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
