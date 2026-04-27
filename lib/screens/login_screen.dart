import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../core/di/service_locator.dart';
import '../services/auth/interfaces/auth_orchestrator_interface.dart';
import '../services/auth/interfaces/biometric_auth_interface.dart';
import '../models/security/security_models.dart';
import '../services/user_service.dart';
import '../services/data_service.dart';
import '../utils/auth_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final IAuthOrchestrator _authOrchestrator;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isBiometricAvailable = false;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _rememberMe = false;
  String? _userName;
  String? _currentError;
  bool _isProcessingLogin = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form validation states
  bool _emailValid = true;
  bool _passwordValid = true;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _authOrchestrator = getIt<IAuthOrchestrator>();
    _checkBiometricAvailability();
    _loadRememberedCredentials();
    _setupAnimations();
    _listenToAuthState();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  void _listenToAuthState() {
    _authOrchestrator.authStateStream.listen((authState) {
      // Don't navigate if we're processing login manually
      // This ensures "remember me" preference is saved before navigation
      if (mounted && authState.isAuthenticated && !_isProcessingLogin) {
        context.toHome();
      }
    });
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final userService = UserService();
      await userService.init();
      final rememberedEmail = await userService.getRememberedEmail();
      final shouldRemember = await userService.shouldRememberEmail();

      if (rememberedEmail != null && shouldRemember) {
        setState(() {
          _emailController.text = rememberedEmail;
          _rememberMe = true;
        });
        await _loadUserNameFromEmail(rememberedEmail);
      }
    } catch (e) {
      debugPrint('Error loading remembered credentials: $e');
    }
  }

  Future<void> _loadUserNameFromEmail(String email) async {
    try {
      if (email.isNotEmpty) {
        // Try getting from DataService first (main app storage)
        final dataService = DataService();
        await dataService.init();
        
        final currentUser = await dataService.getCurrentUser();
        if (currentUser != null && currentUser.email?.toLowerCase() == email.toLowerCase()) {
          if (mounted) {
            setState(() {
              _userName = currentUser.name.toUpperCase();
            });
          }
          return;
        }

        final allUsers = await dataService.getAllUsers();
        final matchingUser = allUsers.where((u) => u.email?.toLowerCase() == email.toLowerCase()).firstOrNull;
        if (matchingUser != null) {
          if (mounted) {
            setState(() {
              _userName = matchingUser.name.toUpperCase();
            });
          }
          return;
        }

        // Legacy/Fallback to UserService
        final userService = UserService();
        await userService.init();
        final profile = await userService.getUserProfile();

        if (mounted) {
          setState(() {
            if (profile != null && profile.email.toLowerCase() == email.toLowerCase()) {
              _userName = profile.name.toUpperCase();
            } else {
              // Fallback to email prefix
              if (email.contains('@')) {
                _userName = email.split('@')[0].toUpperCase();
              } else {
                _userName = email.toUpperCase();
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAuthenticated = await _authOrchestrator.isAuthenticated();
      if (!isAuthenticated) {
        // Check biometric availability through the biometric service
        final biometricService = getIt<IBiometricAuthService>();
        final isAvailable = await biometricService.isAvailable();
        final isEnabled = await biometricService.isBiometricEnabled();

        if (mounted) {
          setState(() {
            _isBiometricAvailable = isAvailable && isEnabled;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
        });
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentError = null;
    });

    try {
      final result = await _authOrchestrator
          .authenticate(AuthMethod.biometric, {
            'reason': 'Uygulamaya erişmek için kimliğinizi doğrulayın',
            'fallbackTitle': 'PIN Kullan',
            'cancelText': 'İptal',
          });

      if (mounted) {
        if (result.isSuccess) {
          // Navigation will be handled by auth state listener
        } else {
          _showError(result.errorMessage ?? 'Biyometrik doğrulama başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Biyometrik doğrulama sırasında bir hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailLogin() async {
    if (_isLoading) return;

    // Real-time validation
    _validateForm();
    if (!_emailValid || !_passwordValid) {
      return;
    }

    setState(() {
      _isLoading = true;
      _currentError = null;
      _isProcessingLogin = true; // Prevent auth listener from navigating
    });

    try {
      final result = await _authOrchestrator
          .authenticate(AuthMethod.emailPassword, {
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'isSignUp': false,
          });

      if (mounted) {
        if (result.isSuccess) {
          // Save remember me preference BEFORE navigation
          await _saveRememberMePreference();
          // Navigate manually after saving preferences
          if (mounted) {
            context.toHome();
          }
        } else {
          _showError(result.errorMessage ?? 'Giriş başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Giriş sırasında bir hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessingLogin = false;
        });
      }
    }
  }

  Future<void> _saveRememberMePreference() async {
    try {
      final userService = UserService();
      await userService.init();
      if (_rememberMe) {
        await userService.saveRememberedEmail(_emailController.text.trim());
        await userService.setRememberEmail(true);
      } else {
        await userService.clearRememberedEmail();
        await userService.setRememberEmail(false);
      }
    } catch (e) {
      debugPrint('Error saving remember me preference: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentError = null;
    });

    try {
      final result = await _authOrchestrator.authenticate(AuthMethod.social, {
        'provider': 'google',
      });

      if (mounted) {
        if (result.isSuccess) {
          // Navigation will be handled by auth state listener
        } else {
          _showError(result.errorMessage ?? 'Google ile giriş başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Google ile giriş sırasında bir hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentError = null;
    });

    try {
      final result = await _authOrchestrator.authenticate(AuthMethod.social, {
        'provider': 'apple',
      });

      if (mounted) {
        if (result.isSuccess) {
          // Navigation will be handled by auth state listener
        } else {
          _showError(result.errorMessage ?? 'Apple ile giriş başarısız');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Apple ile giriş sırasında bir hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController();
    if (_emailController.text.isNotEmpty) {
      emailController.text = _emailController.text;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E3A3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Şifre Sıfırlama',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      labelStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFDB32A),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty || !_isValidEmail(email)) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Geçerli bir e-posta adresi girin',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogContext);

                          try {
                            final result = await _authOrchestrator
                                .sendPasswordResetEmail(email);

                            if (navigator.mounted) {
                              navigator.pop();
                            }

                            if (mounted) {
                              if (result.isSuccess) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Şifre sıfırlama bağlantısı \$email adresine gönderildi',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                _showError(
                                  result.errorMessage ??
                                      'Şifre sıfırlama başarısız',
                                );
                              }
                            }
                          } catch (e) {
                            if (navigator.mounted) {
                              navigator.pop();
                            }
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Şifre sıfırlama sırasında bir hata oluştu',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDB32A),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  void _validateForm() {
    _validateEmail();
    _validatePassword();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailValid = false;
        _emailError = 'E-posta adresi gerekli';
      } else if (!_isValidEmail(email)) {
        _emailValid = false;
        _emailError = 'Geçerli bir e-posta adresi girin';
      } else {
        _emailValid = true;
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      if (password.isEmpty) {
        _passwordValid = false;
        _passwordError = 'Şifre gerekli';
      } else if (password.length < 6) {
        _passwordValid = false;
        _passwordError = 'Şifre en az 6 karakter olmalı';
      } else {
        _passwordValid = true;
        _passwordError = null;
      }
    });
  }

  void _clearError() {
    if (_currentError != null) {
      setState(() {
        _currentError = null;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _currentError = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Error display
          if (_currentError != null) _buildErrorDisplay(),

          // Email field
          _buildEmailField(),
          const SizedBox(height: 16),

          // Password field
          _buildPasswordField(),
          const SizedBox(height: 8),

          // Remember me and forgot password
          _buildRememberMeAndForgotPassword(),
          const SizedBox(height: 24),

          // Login button
          _buildLoginButton(),
          const SizedBox(height: 20),

          // Divider
          _buildDivider(),
          const SizedBox(height: 20),

          // Social login buttons
          _buildSocialLoginButtons(),
          const SizedBox(height: 20),

          // Biometric button
          if (_isBiometricAvailable) _buildBiometricButton(),

          const SizedBox(height: 20),

          // Register link
          _buildRegisterLink(),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentError!,
              style: TextStyle(color: Colors.red.shade300, fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade300, size: 18),
            onPressed: _clearError,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'E-posta',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _emailValid
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _emailValid ? const Color(0xFFFDB32A) : Colors.red,
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
        prefixIcon: Icon(
          Icons.email,
          color: _emailValid
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.red.withValues(alpha: 0.7),
        ),
        suffixIcon: _emailController.text.isNotEmpty
            ? Icon(
                _emailValid ? Icons.check_circle : Icons.error,
                color: _emailValid ? Colors.green : Colors.red,
                size: 20,
              )
            : null,
        errorText: _emailError,
        errorStyle: const TextStyle(color: Colors.red),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        _validateEmail();
        if (value.contains('@')) {
          _loadUserNameFromEmail(value);
        }
      },
      onFieldSubmitted: (_) {
        FocusScope.of(context).nextFocus();
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Şifre',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _passwordValid
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _passwordValid ? const Color(0xFFFDB32A) : Colors.red,
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
        prefixIcon: Icon(
          Icons.lock,
          color: _passwordValid
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.red.withValues(alpha: 0.7),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_passwordController.text.isNotEmpty)
              Icon(
                _passwordValid ? Icons.check_circle : Icons.error,
                color: _passwordValid ? Colors.green : Colors.red,
                size: 20,
              ),
            IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
          ],
        ),
        errorText: _passwordError,
        errorStyle: const TextStyle(color: Colors.red),
      ),
      obscureText: !_showPassword,
      textInputAction: TextInputAction.done,
      onChanged: (value) {
        _validatePassword();
      },
      onFieldSubmitted: (_) {
        _handleEmailLogin();
      },
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: const Color(0xFFFDB32A),
                checkColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: Text(
                'Beni Hatırla',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _isLoading ? null : _handleForgotPassword,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: const Text(
            'Şifremi Unuttum',
            style: TextStyle(
              color: Color(0xFFFDB32A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleEmailLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDB32A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Giriş Yap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: Image.asset(
              'assets/images/google-logo.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.g_mobiledata,
                  size: 20,
                  color: Colors.white,
                );
              },
            ),
            label: 'Google',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            onPressed: _isLoading ? null : _handleAppleSignIn,
            icon: const Icon(Icons.apple, size: 20, color: Colors.white),
            label: 'Apple',
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            color: Colors.white.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFDB32A).withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _isLoading ? null : _handleBiometricAuth,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Icon(
                  Icons.fingerprint,
                  size: 32,
                  color: _isLoading
                      ? Colors.white.withValues(alpha: 0.5)
                      : const Color(0xFFFDB32A),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Biyometrik Giriş',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return TextButton(
      onPressed: () => context.toRegister(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
          children: const [
            TextSpan(text: 'Hesabınız yok mu? '),
            TextSpan(
              text: 'Kayıt olun',
              style: TextStyle(
                color: Color(0xFFFDB32A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    _buildLogo(),
                    const SizedBox(height: 32),

                    // Welcome text
                    _buildWelcomeText(),
                    const SizedBox(height: 40),

                    // Login form
                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: const Color(0xFFFDB32A).withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Image.asset(
          'assets/icon/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.account_balance_wallet,
              size: 60,
              color: Color(0xFFFDB32A),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          _userName != null ? 'Hoş Geldin' : 'Hoş Geldiniz',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        if (_userName != null) ...[
          const SizedBox(height: 8),
          Text(
            _userName!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFDB32A),
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Hesabınıza giriş yapın',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}


