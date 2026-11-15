import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../models/security/security_models.dart';
import '../models/user.dart' as user_models;
import '../services/auth/interfaces/auth_orchestrator_interface.dart';
import '../services/auth/interfaces/biometric_auth_interface.dart';
import '../services/auth/interfaces/data_sync_interface.dart';
import '../services/data_service.dart';
import '../services/guest_mode_service.dart';
import '../services/user_service.dart';
import '../utils/auth_navigation.dart';
import '../utils/responsive_helper.dart';

/// Uygulamanın giriş ekranı.
///
/// Davranış prensipleri:
/// - Auth akışı için `IAuthOrchestrator` tek giriş noktasıdır (orchestrator detayını saklar).
/// - Google Sign-In `GoogleSignInHelper` üzerinden tek noktada başlatılır
///   (yarış durumu yok).
/// - Hata durumunda sade ve anlaşılır mesajlar gösterilir.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final IAuthOrchestrator _auth;
  late final IBiometricAuthService _biometric;

  bool _busy = false;
  bool _showPassword = false;
  bool _rememberMe = false;
  bool _biometricAvailable = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _auth = getIt<IAuthOrchestrator>();
    _biometric = getIt<IBiometricAuthService>();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _auth.initialize();
      await _biometric.initialize();
    } catch (e) {
      debugPrint('LoginScreen: auth init hatası: $e');
    }
    await _loadRemembered();
    await _checkBiometric();
  }

  Future<void> _loadRemembered() async {
    try {
      final userService = UserService();
      await userService.init();
      final email = await userService.getRememberedEmail();
      final should = await userService.shouldRememberEmail();
      if (email != null && should && mounted) {
        setState(() {
          _emailCtrl.text = email;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkBiometric() async {
    try {
      final isAuthed = await _auth.isAuthenticated();
      if (isAuthed) return;
      final has = await _biometric.isAvailable();
      final enabled = await _biometric.isBiometricEnabled();
      if (mounted) setState(() => _biometricAvailable = has && enabled);
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---------- Actions ----------

  Future<void> _signInWithEmail() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final result = await _auth.authenticate(
        AuthMethod.emailPassword,
        {
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'isSignUp': false,
        },
      );
      if (!mounted) return;
      if (!result.isSuccess) {
        _showError(result.errorMessage ?? 'Giriş başarısız.');
        return;
      }
      await _persistUserFromResult(result.metadata);
      await _saveRememberMe();
      if (mounted) context.toHome();
    } catch (e) {
      if (mounted) _showError('Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final result = await _auth.authenticate(
        AuthMethod.social,
        {'provider': 'google'},
      );
      if (!mounted) return;
      if (!result.isSuccess) {
        _showError(result.errorMessage ?? 'Google ile giriş başarısız.');
        return;
      }
      await _persistUserFromResult(result.metadata);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hoş geldin, ${result.metadata?['displayName'] ?? result.metadata?['email'] ?? 'kullanıcı'}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.toHome();
      }
    } catch (e) {
      if (mounted) _showError('Google girişi sırasında hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithBiometric() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final result = await _auth.authenticate(AuthMethod.biometric, {
        'reason': 'Uygulamaya erişmek için kimliğinizi doğrulayın',
        'fallbackTitle': 'PIN Kullan',
        'cancelText': 'İptal',
      });
      if (!mounted) return;
      if (!result.isSuccess) {
        _showError(result.errorMessage ?? 'Biyometrik doğrulama başarısız.');
        return;
      }
      context.toHome();
    } catch (e) {
      if (mounted) _showError('Biyometrik doğrulama sırasında hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enterGuest() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await GuestModeService().enableGuestMode();
      if (mounted) context.toHome();
    } catch (e) {
      if (mounted) _showError('Misafir modu başlatılamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => const _ForgotPasswordDialog(),
    );
    if (email == null || email.isEmpty || !mounted) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final result = await _auth.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess
                ? 'Şifre sıfırlama bağlantısı $email adresine gönderildi.'
                : (result.errorMessage ?? 'Şifre sıfırlama başarısız.'),
          ),
          backgroundColor: result.isSuccess ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (mounted) _showError('Şifre sıfırlama hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- Persistence helpers ----------

  Future<void> _persistUserFromResult(Map<String, dynamic>? metadata) async {
    if (metadata == null) return;
    final userId = metadata['userId']?.toString() ?? '';
    final email = metadata['email']?.toString() ?? '';
    final name = metadata['displayName']?.toString() ?? '';
    final photoUrl = metadata['photoUrl']?.toString();

    final dataService = getIt<DataService>();
    await dataService.init();
    final existing = await dataService.getCurrentUser();
    final newUser = user_models.User(
      id: userId.isNotEmpty
          ? userId
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.isNotEmpty ? name : (existing?.name ?? 'Kullanıcı'),
      email: email.isNotEmpty ? email : (existing?.email ?? ''),
      avatar: photoUrl ?? existing?.avatar,
      currencyCode: existing?.currencyCode ?? 'TRY',
      currencySymbol: existing?.currencySymbol ?? '₺',
      authMethod: email.isEmpty
          ? user_models.AuthMethod.email
          : user_models.AuthMethod.google,
    );
    await dataService.saveUser(newUser);

    final userService = getIt<UserService>();
    await userService.init();
    await userService.saveUserProfile(UserProfile(
      id: newUser.id,
      name: newUser.name,
      email: newUser.email ?? '',
      photoUrl: newUser.avatar,
      createdAt: DateTime.now(),
      authMethod: newUser.authMethod.toString(),
    ));

    if (userId.isNotEmpty) {
      try {
        await getIt<DataSyncInterface>().syncAllUserData(userId);
      } catch (e) {
        debugPrint('LoginScreen: senkron hatası (önemsiz): $e');
      }
    }
  }

  Future<void> _saveRememberMe() async {
    try {
      final userService = UserService();
      await userService.init();
      if (_rememberMe) {
        await userService.saveRememberedEmail(_emailCtrl.text.trim());
        await userService.setRememberEmail(true);
      } else {
        await userService.clearRememberedEmail();
        await userService.setRememberEmail(false);
      }
    } catch (_) {}
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _logo(),
                    const SizedBox(height: 24),
                    const _Header(),
                    const SizedBox(height: 32),
                    _form(),
                    const SizedBox(height: 24),
                    _bottomLinks(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFDB32A).withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.account_balance_wallet,
            size: 56,
            color: Color(0xFFFDB32A),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) _errorBanner(_errorMessage!),
          _emailField(),
          const SizedBox(height: 12),
          _passwordField(),
          const SizedBox(height: 8),
          _rememberForgotRow(),
          const SizedBox(height: 20),
          _primaryButton(
            label: 'Giriş Yap',
            icon: Icons.login,
            onPressed: _busy ? null : _signInWithEmail,
          ),
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 16),
          _googleButton(),
          if (_biometricAvailable) ...[
            const SizedBox(height: 24),
            _biometricButton(),
          ],
        ],
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _emailCtrl,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      enabled: !_busy,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'E-posta',
        icon: Icons.email,
      ),
      validator: _validateEmail,
      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordCtrl,
      focusNode: _passwordFocus,
      obscureText: !_showPassword,
      textInputAction: TextInputAction.done,
      enabled: !_busy,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Şifre',
        icon: Icons.lock,
        suffix: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
      onFieldSubmitted: (_) => _signInWithEmail(),
    );
  }

  Widget _rememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _rememberMe = v ?? false),
                activeColor: const Color(0xFFFDB32A),
                checkColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _busy
                  ? null
                  : () => setState(() => _rememberMe = !_rememberMe),
              child: const Text(
                'Beni hatırla',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _busy ? null : _forgotPassword,
          child: const Text(
            'Şifremi unuttum',
            style: TextStyle(
              color: Color(0xFFFDB32A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(icon, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDB32A),
          disabledBackgroundColor: const Color(0xFFFDB32A).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.white24)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('veya', style: TextStyle(color: Colors.white60)),
        ),
        Expanded(child: Container(height: 1, color: Colors.white24)),
      ],
    );
  }

  Widget _googleButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _signInWithGoogle,
        icon: Image.asset(
          'assets/images/google-logo.png',
          width: 20,
          height: 20,
          errorBuilder: (_, _, _) => const Icon(
            Icons.g_mobiledata,
            size: 28,
            color: Colors.white,
          ),
        ),
        label: const Text(
          'Google ile giriş yap',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _biometricButton() {
    return Center(
      child: Column(
        children: [
          InkResponse(
            onTap: _busy ? null : _signInWithBiometric,
            radius: 36,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFDB32A).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFFFDB32A), width: 1.5),
              ),
              child: const Icon(Icons.fingerprint,
                  size: 36, color: Color(0xFFFDB32A)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Biyometrik giriş',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _bottomLinks() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hesabınız yok mu?',
                style: TextStyle(color: Colors.white70)),
            TextButton(
              onPressed: _busy ? null : () => context.toRegister(),
              child: const Text(
                'Kayıt olun',
                style: TextStyle(
                  color: Color(0xFFFDB32A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _busy ? null : _enterGuest,
          icon: Icon(Icons.play_circle_outline,
              color: Colors.white.withValues(alpha: 0.6), size: 18),
          label: Text(
            'Misafir olarak devam et',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade400),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFDB32A), width: 2),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'E-posta gerekli';
    final ok = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
    return ok ? null : 'Geçerli bir e-posta girin';
  }
}

// ---------- Sub-widgets ----------

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Hoş Geldiniz',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hesabınıza giriş yapın',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E3A3A),
      title: const Text('Şifre Sıfırlama',
          style: TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'E-posta adresinizi girin, size sıfırlama bağlantısı gönderelim.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ctrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'E-posta',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'E-posta gerekli';
                final ok = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                    .hasMatch(s);
                return ok ? null : 'Geçerli bir e-posta girin';
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _busy
              ? null
              : () {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _busy = true);
                  Navigator.pop(context, _ctrl.text.trim());
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDB32A),
          ),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Gönder'),
        ),
      ],
    );
  }
}
