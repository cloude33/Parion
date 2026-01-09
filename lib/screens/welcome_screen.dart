import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../services/auth/interfaces/auth_orchestrator_interface.dart';
import '../services/auth/interfaces/biometric_auth_interface.dart';

import '../widgets/auth_loading_widget.dart';
import '../widgets/auth_error_widget.dart';
import '../utils/auth_navigation.dart';
import '../services/user_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  
  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _initializeAuthServices();
  }



  Future<void> _initializeAuthServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authOrchestrator = getIt<IAuthOrchestrator>();
      
      // Check if user is already authenticated
      final isAuthenticated = await authOrchestrator.isAuthenticated();
      if (isAuthenticated && mounted) {
        context.toHome();
        return;
      }

      final biometricService = getIt<IBiometricAuthService>();
      await biometricService.initialize();

      // Get user profile for welcome message
      final userService = UserService();
      await userService.init();
      final userProfile = await userService.getUserProfile();

      setState(() {
        _isLoading = false;
        _userProfile = userProfile;
      });
    } catch (e) {
      debugPrint('❌ Failed to initialize auth services: $e');
      // Set biometric as unavailable on error
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kimlik doğrulama servisleri başlatılamadı';
      });
    }
  }



  Widget _buildContent() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final horizontalPadding = isTablet ? 48.0 : 24.0;
    
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: _buildHeader(),
            ),
            Expanded(
              flex: 2,
              child: _buildActionButtons(context),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f2027),
              Color(0xFF203a43),
              Color(0xFF2c5364),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: _isLoading
            ? AuthLoadingOverlay(
                isLoading: true,
                loadingMessage: 'Kimlik doğrulama servisleri başlatılıyor...',
                child: _buildContent(),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(),
        const SizedBox(height: 32),
        _buildTitle(),
        const SizedBox(height: 16),
        _buildSubtitle(),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFDB32A).withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.account_balance_wallet,
                size: 90,
                color: Color(0xFFFDB32A),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Parion',
      style: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
      textAlign: TextAlign.center,
      semanticsLabel: 'Parion uygulaması',
    );
  }

  Widget _buildSubtitle() {
    if (_userProfile != null && _userProfile!.name.isNotEmpty) {
      return Column(
        children: [
          Text(
            'Hoş Geldin,',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.2,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile!.name,
            style: TextStyle(
              fontSize: 24,
              color: const Color(0xFFFDB32A),
              height: 1.2,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Text(
      'Finansal özgürlüğünüze giden yolda\nyardımcınız',
      style: TextStyle(
        fontSize: 18,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.6,
        fontWeight: FontWeight.w300,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error display
        if (_errorMessage != null) ...[
          AuthErrorWidget(
            message: _errorMessage!,
            onRetry: _initializeAuthServices,
            onDismiss: () => setState(() => _errorMessage = null),
            showRetryButton: true,
          ),
          const SizedBox(height: 16),
        ],
        


        _buildPrimaryButton(
          context,
          text: 'Giriş Yap',
          onPressed: _isLoading ? null : () => context.toLogin(),
          icon: Icons.login,
        ),
        const SizedBox(height: 16),
        _buildSecondaryButton(
          context,
          text: 'Kayıt Ol',
          onPressed: _isLoading ? null : () => context.toRegister(),
          icon: Icons.person_add,
        ),
      ],
    );
  }



  Widget _buildPrimaryButton(
    BuildContext context, {
    required String text,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFDB32A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFDB32A).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading && text == 'Giriş Yap')
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A3A)),
                    ),
                  )
                else
                  Icon(
                    icon,
                    color: const Color(0xFF1E3A3A),
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A3A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context, {
    required String text,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Text(
            'Giriş yaparak Kullanım Koşulları ve\nGizlilik Politikası\'nı kabul etmiş olursunuz',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDB32A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Güvenli ve Hızlı',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}


