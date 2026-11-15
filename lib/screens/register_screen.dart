import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../models/security/security_models.dart';
import '../models/user.dart' as user_models;
import '../services/auth/interfaces/auth_orchestrator_interface.dart';
import '../services/auth/interfaces/data_sync_interface.dart';
import '../services/data_service.dart';
import '../services/user_service.dart';
import '../utils/auth_navigation.dart';
import '../utils/responsive_helper.dart';

/// Yeni hesap oluşturma ekranı.
///
/// E-posta/şifre kaydı, Google ile kayıt, Apple ile kayıt ve
/// kullanıcı sözleşmesi onayı bu ekrandan yönetilir.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late final IAuthOrchestrator _auth;
  late final DataSyncInterface _sync;

  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _acceptTerms = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _auth = getIt<IAuthOrchestrator>();
    _sync = getIt<DataSyncInterface>();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ---------- Validators ----------

  String? _validateName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Ad Soyad gerekli';
    if (s.length < 2) return 'En az 2 karakter';
    return null;
  }

  String? _validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'E-posta gerekli';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(s)) {
      return 'Geçerli bir e-posta girin';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Şifre gerekli';
    if (v.length < 6) return 'En az 6 karakter';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Şifre tekrar gerekli';
    if (v != _passwordCtrl.text) return 'Şifreler eşleşmiyor';
    return null;
  }

  // ---------- Actions ----------

  Future<void> _register() async {
    if (_busy) return;
    _formKey.currentState!.validate();
    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmError != null) {
      return;
    }
    if (!_acceptTerms) {
      _toast('Lütfen kullanım koşullarını kabul edin.', isError: true);
      return;
    }
    setState(() {
      _busy = true;
    });

    try {
      final result = await _auth.authenticate(
        AuthMethod.emailPassword,
        {
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'displayName': _nameCtrl.text.trim(),
          'isSignUp': true,
        },
      );
      if (!mounted) return;
      if (!result.isSuccess) {
        _toast(result.errorMessage ?? 'Kayıt başarısız.', isError: true);
        return;
      }
      await _persistUserFromResult(result.metadata);
      _toast('Hesabınız başarıyla oluşturuldu!', isError: false);
      if (mounted) context.toHome();
    } catch (e) {
      if (mounted) _toast('Beklenmeyen hata: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _auth.authenticate(
        AuthMethod.social,
        {'provider': 'google'},
      );
      if (!mounted) return;
      if (!result.isSuccess) {
        _toast(result.errorMessage ?? 'Google ile kayıt başarısız.',
            isError: true);
        return;
      }
      await _persistUserFromResult(result.metadata);
      _toast('Google ile kayıt başarılı!', isError: false);
      if (mounted) context.toHome();
    } catch (e) {
      if (mounted) _toast('Google kayıt hatası: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUpWithApple() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _auth.authenticate(
        AuthMethod.social,
        {'provider': 'apple'},
      );
      if (!mounted) return;
      if (!result.isSuccess) {
        _toast(result.errorMessage ?? 'Apple ile kayıt başarısız.',
            isError: true);
        return;
      }
      await _persistUserFromResult(result.metadata);
      _toast('Apple ile kayıt başarılı!', isError: false);
      if (mounted) context.toHome();
    } catch (e) {
      if (mounted) _toast('Apple kayıt hatası: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistUserFromResult(Map<String, dynamic>? metadata) async {
    if (metadata == null) return;
    final userId = metadata['userId']?.toString() ?? '';
    final email = metadata['email']?.toString() ?? '';
    final name = metadata['displayName']?.toString() ?? _nameCtrl.text.trim();
    final photoUrl = metadata['photoUrl']?.toString();

    final dataService = getIt<DataService>();
    await dataService.init();
    final newUser = user_models.User(
      id: userId.isNotEmpty
          ? userId
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.isNotEmpty ? name : 'Kullanıcı',
      email: email.isNotEmpty ? email : _emailCtrl.text.trim(),
      avatar: photoUrl,
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
        await _sync.syncAllUserData(userId);
      } catch (e) {
        debugPrint('RegisterScreen: senkron hatası (önemsiz): $e');
      }
    }
  }

  void _toast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: ResponsiveHelper.getResponsivePadding(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kullanım Koşulları'),
        content: const SingleChildScrollView(
          child: Text(
            'Bu uygulama kişisel finans yönetimi için tasarlanmıştır. '
            'Uygulamayı kullanarak aşağıdaki koşulları kabul etmiş olursunuz:\n\n'
            '1. Uygulamayı yalnızca yasal amaçlar için kullanacaksınız.\n'
            '2. Verilerinizin güvenliği için gerekli önlemleri alacaksınız.\n'
            '3. Uygulamanın doğru kullanımından sorumlusunuz.\n'
            '4. Hizmet kesintilerinden dolayı sorumluluk kabul etmeyiz.\n'
            '5. Bu koşullar önceden haber verilmeksizin değiştirilebilir.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gizlilik Politikası'),
        content: const SingleChildScrollView(
          child: Text(
            'Gizliliğiniz bizim için önemlidir.\n\n'
            '1. Kişisel verileriniz güvenli şekilde saklanır.\n'
            '2. Verileriniz üçüncü taraflarla paylaşılmaz.\n'
            '3. Şifreleme teknolojileri kullanılır.\n'
            '4. Verilerinizi istediğiniz zaman silebilirsiniz.\n'
            '5. Çerezler yalnızca uygulama işlevselliği için kullanılır.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1C1C1E)),
          onPressed: _busy ? null : () => context.goBack(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: () => setState(() {
              _nameError = _validateName(_nameCtrl.text);
              _emailError = _validateEmail(_emailCtrl.text);
              _passwordError = _validatePassword(_passwordCtrl.text);
              _confirmError = _validateConfirm(_confirmCtrl.text);
            }),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _logo(),
                const SizedBox(height: 16),
                const _Header(),
                const SizedBox(height: 24),
                _field(
                  controller: _nameCtrl,
                  label: 'Ad Soyad',
                  icon: Icons.person,
                  keyboardType: TextInputType.name,
                  errorText: _nameError,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _emailCtrl,
                  label: 'E-posta',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _passwordCtrl,
                  label: 'Şifre',
                  icon: Icons.lock,
                  obscure: !_showPassword,
                  enabled: !_busy,
                  errorText: _passwordError,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    icon: Icon(_showPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                if (_passwordCtrl.text.isNotEmpty)
                  _passwordStrength(),
                const SizedBox(height: 12),
                _field(
                  controller: _confirmCtrl,
                  label: 'Şifre Tekrar',
                  icon: Icons.lock_outline,
                  obscure: !_showConfirm,
                  enabled: !_busy,
                  errorText: _confirmError,
                  textInputAction: TextInputAction.done,
                  suffix: IconButton(
                    icon: Icon(_showConfirm
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                const SizedBox(height: 16),
                _termsBox(),
                const SizedBox(height: 24),
                _registerButton(),
                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 16),
                _socialButtons(),
                const SizedBox(height: 16),
                _loginLink(),
              ],
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
          color: const Color(0xFFFDB32A).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Image.asset(
            'assets/icon/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Color(0xFFFDB32A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    bool enabled = true,
    String? errorText,
    TextInputAction? textInputAction,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      enabled: enabled,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
        prefixIcon: Icon(icon, color: const Color(0xFF8E8E93)),
        suffixIcon: suffix,
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: errorText != null ? Colors.red : const Color(0xFFE5E5EA),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: errorText != null ? Colors.red : const Color(0xFFFDB32A),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _passwordStrength() {
    final password = _passwordCtrl.text;
    Color color;
    String label;
    IconData icon;

    if (password.length < 6) {
      color = Colors.red;
      label = 'En az 6 karakter';
      icon = Icons.warning;
    } else {
      int score = 1;
      if (password.length >= 8) score++;
      if (password.contains(RegExp(r'[A-Z]'))) score++;
      if (password.contains(RegExp(r'[a-z]'))) score++;
      if (password.contains(RegExp(r'[0-9]'))) score++;
      if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;

      if (score <= 3) {
        color = Colors.orange;
        label = 'Orta güçlükte';
        icon = Icons.info;
      } else if (score == 4) {
        color = Colors.green;
        label = 'Güçlü';
        icon = Icons.check_circle;
      } else {
        color = Colors.green.shade700;
        label = 'Çok güçlü';
        icon = Icons.verified;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _termsBox() {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _acceptTerms
              ? const Color(0xFFFDB32A).withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _acceptTerms,
              activeColor: const Color(0xFFFDB32A),
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _acceptTerms = v ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _busy
                  ? null
                  : () => setState(() => _acceptTerms = !_acceptTerms),
              child: Wrap(
                children: [
                  const Text(
                    'Hesap oluşturarak ',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: _showTerms,
                    child: const Text(
                      'Kullanım Koşulları',
                      style: TextStyle(
                        color: Color(0xFFFDB32A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(
                    ' ve ',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: _showPrivacy,
                    child: const Text(
                      'Gizlilik Politikası',
                      style: TextStyle(
                        color: Color(0xFFFDB32A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(
                    '\'nı kabul etmiş olursunuz.',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _busy ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDB32A),
          disabledBackgroundColor:
              const Color(0xFFFDB32A).withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _busy
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Hesap oluşturuluyor…',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              )
            : const Text(
                'Hesap Oluştur',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _divider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE5E5EA))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('veya', style: TextStyle(color: Color(0xFF8E8E93))),
        ),
        Expanded(child: Divider(color: Color(0xFFE5E5EA))),
      ],
    );
  }

  Widget _socialButtons() {
    return Row(
      children: [
        Expanded(
          child: _socialButton(
            label: 'Google',
            onPressed: _busy ? null : _signUpWithGoogle,
            icon: Image.asset(
              'assets/images/google-logo.png',
              width: 20,
              height: 20,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.g_mobiledata, color: Color(0xFF1C1C1E)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _socialButton(
            label: 'Apple',
            onPressed: _busy ? null : _signUpWithApple,
            icon: const Icon(Icons.apple, color: Color(0xFF1C1C1E)),
          ),
        ),
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required VoidCallback? onPressed,
    required Widget icon,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E5EA)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _loginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Zaten hesabınız var mı?',
            style: TextStyle(color: Color(0xFF8E8E93))),
        TextButton(
          onPressed: _busy ? null : () => context.goBack(),
          child: const Text(
            'Giriş Yap',
            style: TextStyle(
              color: Color(0xFFFDB32A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text(
          'Hesap Oluştur',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Finansal yolculuğunuza başlayın',
          style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93)),
        ),
      ],
    );
  }
}
