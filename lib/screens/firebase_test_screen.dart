import 'package:flutter/material.dart';
import '../services/auth/interfaces/auth_orchestrator_interface.dart';
import '../services/backup_service.dart';
import '../core/di/service_locator.dart';
import '../models/security/auth_state.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final IAuthOrchestrator _authService = getIt<IAuthOrchestrator>();
  final BackupService _backupService = BackupService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _authService.initialize();
      _checkAuthStatus();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Initialization error: $e';
      });
    }
  }

  void _checkAuthStatus() {
    final state = _authService.currentAuthState;
    setState(() {
      if (state.isAuthenticated) {
        _statusMessage = '✅ Authenticated: ${state.sessionId ?? 'User'}';
      } else {
        _statusMessage = '❌ Not signed in';
      }
    });
  }

  Future<void> _signInWithTestAccount() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Test hesabı ile giriş yapılıyor...';
    });

    try {
      // Test hesabı bilgileri
      const testEmail = 'test@firebasebackup.com';
      const testPassword = 'TestPassword123!';

      // Önce giriş yapmayı dene
      var result = await _authService.authenticate(AuthMethod.emailPassword, {
        'email': testEmail,
        'password': testPassword,
        'isSignUp': false,
      });

      if (!result.isSuccess) {
        // Hesap yoksa oluştur
        debugPrint('Test hesabı bulunamadı, oluşturuluyor...');
        result = await _authService.authenticate(AuthMethod.emailPassword, {
          'email': testEmail,
          'password': testPassword,
          'isSignUp': true,
          'displayName': 'Test User',
        });
      }

      setState(() {
        if (result.isSuccess) {
          _statusMessage = '✅ Test hesabı ile giriş başarılı';
          _checkAuthStatus();
        } else {
          _statusMessage = '❌ Test hesabı giriş hatası: ${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Test hesabı giriş hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithCustomAccount() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = '❌ E-posta ve şifre gerekli';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Giriş yapılıyor...';
    });

    try {
      final result = await _authService.authenticate(AuthMethod.emailPassword, {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'isSignUp': false,
      });

      setState(() {
        if (result.isSuccess) {
          _statusMessage = '✅ Giriş başarılı';
          _checkAuthStatus();
        } else {
          _statusMessage = '❌ Giriş hatası: ${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Giriş hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Çıkış yapılıyor...';
    });

    try {
      await _authService.logout();
      setState(() {
        _statusMessage = '✅ Çıkış yapıldı';
        _checkAuthStatus();
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Çıkış hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testBackup() async {
    if (!_authService.currentAuthState.isAuthenticated) {
      setState(() {
        _statusMessage = '❌ Yedekleme için Firebase giriş gerekli';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Test yedekleme yapılıyor...';
    });

    try {
      final success = await _backupService.uploadToCloud();
      setState(() {
        _statusMessage = success
            ? '✅ Test yedekleme başarılı'
            : '❌ Test yedekleme başarısız';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Test yedekleme hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Durum kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test hesabı ile giriş
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithTestAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.science),
              label: const Text('Test Hesabı ile Giriş Yap'),
            ),
            const SizedBox(height: 16),

            // Manuel giriş
            const Text(
              'Manuel Giriş:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithCustomAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Giriş Yap'),
            ),
            const SizedBox(height: 24),

            // Test butonları
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.backup),
              label: const Text('Test Yedekleme Yap'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
            ),
            const SizedBox(height: 24),

            // Firebase durumu
            StreamBuilder<AuthState>(
              stream: _authService.authStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data ?? _authService.currentAuthState;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state.isAuthenticated
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    border: Border.all(
                      color: state.isAuthenticated ? Colors.green : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auth Durumu:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: state.isAuthenticated
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.isAuthenticated
                            ? 'Oturum Açık\nSession ID: ${state.sessionId ?? "No session"}\nDurum: ${state.status.name}'
                            : 'Oturum Kapalı',
                        style: TextStyle(
                          fontSize: 12,
                          color: state.isAuthenticated
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
