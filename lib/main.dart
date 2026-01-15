import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/auto_backup_service.dart';
import 'services/auth/interfaces/auth_orchestrator_interface.dart';
import 'models/security/security_models.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'core/di/service_locator.dart';
import 'services/credit_card_box_service.dart';
import 'models/credit_card.dart';
import 'models/credit_card_transaction.dart';
import 'models/credit_card_statement.dart';
import 'models/credit_card_payment.dart';
import 'models/reward_points.dart';
import 'models/reward_transaction.dart';
import 'models/limit_alert.dart';
import 'services/kmh_box_service.dart';
import 'models/kmh_transaction.dart';
import 'models/kmh_transaction_type.dart';
import 'services/notification_scheduler_service.dart';
import 'services/bill_payment_service.dart';
import 'services/app_lock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Sistem navigasyon çubuğu rengini scaffold ile eşleştir
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFFF4F6F8), // Scaffold arka plan rengi
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('tr_TR', null);
  await Hive.initFlutter();

  try {
    Hive.registerAdapter(CreditCardAdapter());
    Hive.registerAdapter(CreditCardTransactionAdapter());
    Hive.registerAdapter(CreditCardStatementAdapter());
    Hive.registerAdapter(CreditCardPaymentAdapter());
    Hive.registerAdapter(RewardPointsAdapter());
    Hive.registerAdapter(RewardTransactionAdapter());
    Hive.registerAdapter(LimitAlertAdapter());
    Hive.registerAdapter(KmhTransactionAdapter());
    Hive.registerAdapter(KmhTransactionTypeAdapter());
    await CreditCardBoxService.init();
    await KmhBoxService.init();
    debugPrint('Hive boxes initialized for credit cards and KMH');
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  await ThemeService().init();

  // Bildirim servisini başlat ve izinleri iste
  try {
    final notificationService = NotificationSchedulerService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
    debugPrint('Notification service initialized');
  } catch (e) {
    debugPrint('Notification service init error: $e');
  }

  // Setup modern dependency injection
  try {
    await setupDependencyInjection();
    debugPrint('Modern dependency injection initialized');
  } catch (e) {
    debugPrint('Modern dependency injection init error: $e');
  }

  try {
    await AppLockService().init();
    debugPrint('App lock service initialized');
  } catch (e) {
    debugPrint('App lock service init error: $e');
  }

  // Otomatik yedekleme servisini başlat
  try {
    await AutoBackupService().initialize();
    debugPrint('Auto backup service initialized');
  } catch (e) {
    debugPrint('Auto backup service init error: $e');
  }

  runApp(const ParionApp());
}

class ParionApp extends StatefulWidget {
  const ParionApp({super.key});

  @override
  State<ParionApp> createState() => _ParionAppState();
}

class _ParionAppState extends State<ParionApp> with WidgetsBindingObserver {
  late final IAuthOrchestrator _authOrchestrator;
  final ThemeService _themeService = ThemeService();
  final LanguageService _languageService = LanguageService();
  final AutoBackupService _autoBackupService = AutoBackupService();
  final BillPaymentService _billPaymentService = BillPaymentService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  ThemeMode _themeMode = ThemeMode.system;
  AuthState _authState = AuthState.unauthenticated();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authOrchestrator = getIt<IAuthOrchestrator>(); // getIt is global
    _loadTheme();
    _authOrchestrator.authStateStream.listen((authState) {
      if (mounted) {
        final wasAuthenticated = _authState.isAuthenticated;
        setState(() {
          _authState = authState;
        });

        // Eğer uygulama kilitlenmişse (local auth gerekli hale gelmişse) giriş ekranına yönlendir
        if (!authState.isAuthenticated && wasAuthenticated) {
          debugPrint('App locked or logged out - redirecting');
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      }
    });
    _themeService.addListener(_onThemeChanged);
    _languageService.addListener(_onLanguageChanged);

    // Uygulama açılışında vadesi gelen faturaları kontrol et
    _billPaymentService.checkAndProcessDuePayments();
  }

  Future<void> _loadTheme() async {
    final themeMode = await _themeService.getThemeMode();
    if (mounted) {
      setState(() {
        _themeMode = themeMode;
      });
    }
  }

  void _onThemeChanged() {
    debugPrint('Theme changed notification received');
    _loadTheme();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  // _checkAuthenticationStatus kaldırıldı, UnifiedAuthService stream'i kullanılıyor

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('App lifecycle state changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _authOrchestrator.onAppForeground();
        // Uygulama ön plana geldiğinde otomatik yedekleme kontrolü yap
        _autoBackupService.checkAndPerformBackupIfNeeded();
        // Vadesi gelen faturaları kontrol et
        _billPaymentService.checkAndProcessDuePayments();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _authOrchestrator.onAppBackground();
        break;
      case AppLifecycleState.detached:
        // Uygulama tamamen kapatılıyor - oturumu sonlandır
        _authOrchestrator.logout();
        _autoBackupService.dispose();
        break;
      case AppLifecycleState.hidden:
        // Uygulama gizlendi - arka plan işlemi başlat
        _authOrchestrator.onAppBackground();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _recordUserActivity,
      onPanDown: (_) => _recordUserActivity(),
      onScaleStart: (_) => _recordUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: Listener(
        onPointerDown: (_) => _recordUserActivity(),
        onPointerMove: (_) => _recordUserActivity(),
        onPointerUp: (_) => _recordUserActivity(),
        child: MaterialApp(
          title: 'Parion',
          debugShowCheckedModeBanner: false,
          themeMode: _themeMode,
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          locale: _languageService.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: _navigatorKey,
          home: _getInitialScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      ),
    );
  }

  /// Kullanıcı aktivitesini kaydeder
  void _recordUserActivity() {
    if (_authState.isAuthenticated) {
      // Session manager'a aktivite bildir
      _authOrchestrator.recordActivity();
    }
  }

  Widget _getInitialScreen() {
    if (_authState.isAuthenticated) {
      return const HomeScreen();
    }
    return const WelcomeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeService.removeListener(_onThemeChanged);
    _languageService.removeListener(_onLanguageChanged);
    _autoBackupService.dispose();
    super.dispose();
  }
}
