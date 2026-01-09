import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/di/service_locator.dart';
import '../services/auth/interfaces/auth_orchestrator_interface.dart';
import '../models/security/security_models.dart';
import '../services/auth/interfaces/data_sync_interface.dart';
import '../utils/auth_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  late final IAuthOrchestrator _authOrchestrator;
  late final DataSyncInterface _dataSyncService;

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _isTermsAccepted = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _authOrchestrator = getIt<IAuthOrchestrator>();
    _dataSyncService = getIt<DataSyncInterface>();
    
    // Add real-time validation listeners
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
    _nameController.addListener(_validateName);
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailError = null; // Don't show error for empty field until form submission
      } else if (!_isValidEmail(email)) {
        _emailError = 'Geçerli bir e-posta adresi girin';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      if (password.isEmpty) {
        _passwordError = null; // Don't show error for empty field until form submission
      } else if (!_isPasswordStrong(password)) {
        _passwordError = 'Şifre en az 8 karakter olmalı, büyük/küçük harf ve rakam içermelidir';
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateConfirmPassword() {
    final confirmPassword = _confirmPasswordController.text;
    final password = _passwordController.text;
    setState(() {
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = null; // Don't show error for empty field until form submission
      } else if (confirmPassword != password) {
        _confirmPasswordError = 'Şifreler eşleşmiyor';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  void _validateName() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _nameError = null; // Don't show error for empty field until form submission
      } else if (name.length < 2) {
        _nameError = 'Ad en az 2 karakter olmalıdır';
      } else {
        _nameError = null;
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    // En az 1 büyük harf
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    // En az 1 küçük harf
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    // En az 1 rakam
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  Color _getPasswordStrengthColor() {
    final password = _passwordController.text;
    if (password.isEmpty) return Colors.grey;
    
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    if (score <= 2) return Colors.red;
    if (score == 3) return Colors.orange;
    if (score == 4) return Colors.green;
    return Colors.green.shade700;
  }

  IconData _getPasswordStrengthIcon() {
    final password = _passwordController.text;
    if (password.isEmpty) return Icons.help_outline;
    
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    if (score <= 2) return Icons.warning;
    if (score == 3) return Icons.info;
    return Icons.check_circle;
  }

  String _getPasswordStrengthText() {
    final password = _passwordController.text;
    if (password.isEmpty) return 'Şifre girin';
    
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    if (score <= 2) return 'Zayıf şifre';
    if (score == 3) return 'Orta güçlükte şifre';
    if (score == 4) return 'Güçlü şifre';
    return 'Çok güçlü şifre';
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateName);
    _emailController.removeListener(_validateEmail);
    _passwordController.removeListener(_validatePassword);
    _confirmPasswordController.removeListener(_validateConfirmPassword);
    
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validate all fields before proceeding
    _validateName();
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();
    
    if (!_formKey.currentState!.validate()) return;
    
    // Check for real-time validation errors
    if (_nameError != null || _emailError != null || _passwordError != null || _confirmPasswordError != null) {
      return;
    }
    
    if (!_isTermsAccepted) {
      _showErrorSnackBar('Lütfen Kullanım Koşullarını kabul edin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use AuthOrchestrator for registration
      final result = await _authOrchestrator.authenticate(
        AuthMethod.emailPassword,
        {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'displayName': _nameController.text.trim(),
          'isSignUp': true,
        },
      );

      if (result.isSuccess) {
        // Sync user data
        await _dataSyncService.syncAllUserData(result.metadata?['userId'] ?? '');
        
        if (mounted) {
          _showSuccessSnackBar('Hesabınız başarıyla oluşturuldu!');
          
          // Navigate to home screen
          context.toHome();
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(result.errorMessage ?? 'Kayıt başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authOrchestrator.authenticate(
        AuthMethod.social,
        {'provider': 'google'},
      );

      if (result.isSuccess) {
        // Sync user data
        await _dataSyncService.syncAllUserData(result.metadata?['userId'] ?? '');
        
        if (mounted) {
          _showSuccessSnackBar('Google ile kayıt başarılı!');
          
          context.toHome();
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(result.errorMessage ?? 'Google ile kayıt başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Google ile kayıt sırasında bir hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authOrchestrator.authenticate(
        AuthMethod.social,
        {'provider': 'apple'},
      );

      if (result.isSuccess) {
        // Sync user data
        await _dataSyncService.syncAllUserData(result.metadata?['userId'] ?? '');
        
        if (mounted) {
          _showSuccessSnackBar('Apple ile kayıt başarılı!');
          
          context.toHome();
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(result.errorMessage ?? 'Apple ile kayıt başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Apple ile kayıt sırasında bir hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanım Koşulları'),
        content: const SingleChildScrollView(
          child: Text(
            'Bu uygulama kişisel finans yönetimi için tasarlanmıştır. '
            'Uygulamayı kullanarak aşağıdaki koşulları kabul etmiş olursunuz:\n\n'
            '1. Uygulamayı yalnızca yasal amaçlar için kullanacaksınız.\n'
            '2. Verilerinizin güvenliği için gerekli önlemleri alacaksınız.\n'
            '3. Uygulamanın doğru kullanımından sorumlusunuz.\n'
            '4. Hizmet kesintilerinden dolayı sorumluluk kabul etmeyiz.\n'
            '5. Bu koşullar önceden haber verilmeksizin değiştirilebilir.\n\n'
            'Detaylı bilgi için lütfen tam kullanım koşullarını okuyun.',
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

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gizlilik Politikası'),
        content: const SingleChildScrollView(
          child: Text(
            'Gizliliğiniz bizim için önemlidir. Bu politika, '
            'verilerinizin nasıl toplandığını ve kullanıldığını açıklar:\n\n'
            '1. Kişisel verileriniz güvenli şekilde saklanır.\n'
            '2. Verileriniz üçüncü taraflarla paylaşılmaz.\n'
            '3. Şifreleme teknolojileri kullanılır.\n'
            '4. Verilerinizi istediğiniz zaman silebilirsiniz.\n'
            '5. Çerezler yalnızca uygulama işlevselliği için kullanılır.\n\n'
            'Detaylı bilgi için lütfen tam gizlilik politikasını okuyun.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1C1C1E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDB32A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/icon/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.account_balance_wallet,
                              size: 110,
                              color: Color(0xFFFDB32A),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hesap Oluştur',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Finansal yolculuğunuza başlayın',
                  style: TextStyle(fontSize: 16, color: Color(0xFF8E8E93)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _nameError != null ? Colors.red : const Color(0xFFE5E5EA),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _nameError != null ? Colors.red : const Color(0xFFFDB32A),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFF8E8E93),
                    ),
                    errorText: _nameError,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen adınızı girin';
                    }
                    if (value.trim().length < 2) {
                      return 'Ad en az 2 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _emailError != null ? Colors.red : const Color(0xFFE5E5EA),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _emailError != null ? Colors.red : const Color(0xFFFDB32A),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Color(0xFF8E8E93),
                    ),
                    errorText: _emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen e-posta adresinizi girin';
                    }
                    if (!_isValidEmail(value.trim())) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _passwordError != null ? Colors.red : const Color(0xFFE5E5EA),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _passwordError != null ? Colors.red : const Color(0xFFFDB32A),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Color(0xFF8E8E93),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF8E8E93),
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    errorText: _passwordError,
                  ),
                  obscureText: !_showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifre girin';
                    }
                    if (!_isPasswordStrong(value)) {
                      return 'Şifre en az 8 karakter olmalı, büyük/küçük harf ve rakam içermelidir';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Password strength indicator
                if (_passwordController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getPasswordStrengthColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getPasswordStrengthColor().withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPasswordStrengthIcon(),
                          size: 16,
                          color: _getPasswordStrengthColor(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getPasswordStrengthText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPasswordStrengthColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre Tekrar',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _confirmPasswordError != null ? Colors.red : const Color(0xFFE5E5EA),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _confirmPasswordError != null ? Colors.red : const Color(0xFFFDB32A),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF8E8E93),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF8E8E93),
                      ),
                      onPressed: () {
                        setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                    ),
                    errorText: _confirmPasswordError,
                  ),
                  obscureText: !_showConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifrenizi tekrar girin';
                    }
                    if (value != _passwordController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Terms and conditions section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isTermsAccepted ? const Color(0xFFFDB32A).withValues(alpha: 0.3) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _isTermsAccepted,
                          activeColor: const Color(0xFFFDB32A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (value) {
                            setState(() => _isTermsAccepted = value ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isTermsAccepted = !_isTermsAccepted);
                          },
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Hesap oluşturarak ',
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 13,
                                  ),
                                ),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => _showTermsDialog(),
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
                                ),
                                const TextSpan(
                                  text: '\'nı ve ',
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 13,
                                  ),
                                ),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => _showPrivacyDialog(),
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
                                ),
                                const TextSpan(
                                  text: '\'nı kabul etmiş olursunuz.',
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Register button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading 
                          ? const Color(0xFFFDB32A).withValues(alpha: 0.6)
                          : const Color(0xFFFDB32A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isLoading ? 0 : 2,
                      shadowColor: const Color(0xFFFDB32A).withValues(alpha: 0.3),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Hesap Oluşturuluyor...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Hesap Oluştur',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0xFFE5E5EA))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'veya',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFE5E5EA))),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E8E93)),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/google-logo.png',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.g_mobiledata,
                                      size: 20,
                                      color: Color(0xFF1C1C1E),
                                    );
                                  },
                                ),
                          label: Text(
                            _isLoading ? 'Bağlanıyor...' : 'Google',
                            style: TextStyle(
                              color: _isLoading ? const Color(0xFF8E8E93) : const Color(0xFF1C1C1E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: _isLoading ? const Color(0xFFE5E5EA).withValues(alpha: 0.5) : const Color(0xFFE5E5EA),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: _isLoading ? const Color(0xFFF2F2F7) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleAppleSignIn,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E8E93)),
                                  ),
                                )
                              : const Icon(
                                  Icons.apple,
                                  size: 20,
                                  color: Color(0xFF1C1C1E),
                                ),
                          label: Text(
                            _isLoading ? 'Bağlanıyor...' : 'Apple',
                            style: TextStyle(
                              color: _isLoading ? const Color(0xFF8E8E93) : const Color(0xFF1C1C1E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: _isLoading ? const Color(0xFFE5E5EA).withValues(alpha: 0.5) : const Color(0xFFE5E5EA),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: _isLoading ? const Color(0xFFF2F2F7) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Zaten hesabınız var mı?',
                      style: TextStyle(color: Color(0xFF8E8E93)),
                    ),
                    TextButton(
                      onPressed: () => context.goBack(),
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          color: Color(0xFFFDB32A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


