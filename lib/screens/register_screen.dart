import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import 'profile_setup_screen.dart';
import 'privacy_policy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPolicyAccepted = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // --- KULLANICI AKIŞI DÜZELTİLDİ ---
    if (success && mounted) {
      // Verify user is actually signed in before navigating
      // Wait a brief moment for auth state to propagate
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Double-check that user is authenticated
      if (authProvider.status == AuthStatus.Authenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else if (mounted) {
        // If still not authenticated, show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesap oluşturuldu ancak otomatik giriş yapılamadı. Lütfen giriş yapın.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _googleLogin() async {
    HapticFeedback.lightImpact();
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.signInWithGoogle();

    if (result['success'] == true && mounted) {
      // Google ile girişte yeni kullanıcıysa her zaman profil kurulumuna gider
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Oluştur'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Aramıza Hoş Geldin!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))
                      .animate().fade(duration: 400.ms).slideY(begin: -0.5),
                  const SizedBox(height: 8),
                  Text('Yeni bir hesap oluşturarak başla.', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey))
                      .animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: -0.5),

                  const SizedBox(height: 32),

                  if (authProvider.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(authProvider.errorMessage!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    ).animate().shakeX(),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: 'E-posta', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.email_outlined)),
                    validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Geçerli bir e-posta girin' : null,
                  ).animate().fade(delay: 400.ms).slideX(begin: -0.5),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Şifre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock_outline)),
                    validator: (v) => (v == null || v.length < 6) ? 'Şifre en az 6 karakter olmalı' : null,
                  ).animate().fade(delay: 500.ms).slideX(begin: -0.5),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Şifre (Tekrar)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock_reset_outlined)),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ).animate().fade(delay: 600.ms).slideX(begin: -0.5),

                  // Import eklendi (dosyanın en üstüne eklenmeli ama burada sadece arayüzü değiştiriyoruz)
                  
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Checkbox(
                          value: _isPolicyAccepted,
                          onChanged: (val) {
                            setState(() {
                              _isPolicyAccepted = val ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
                          },
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodySmall,
                              children: [
                                const TextSpan(text: 'Kayıt olarak '),
                                TextSpan(
                                  text: 'Kullanıcı Sözleşmesi',
                                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: ' ve '),
                                TextSpan(
                                  text: 'KVKK Metnini',
                                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: ' kabul ediyorum.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 650.ms).slideX(begin: -0.5),

                  const SizedBox(height: 24),

                  authProvider.status == AuthStatus.Authenticating
                      ? const Center(child: CircularProgressIndicator())
                      : Opacity(
                          opacity: _isPolicyAccepted ? 1.0 : 0.5,
                          child: ElevatedButton(
                            onPressed: _isPolicyAccepted ? _register : null,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Kayıt Ol', style: TextStyle(fontSize: 16)),
                          ),
                        ).animate().fade(delay: 700.ms).slideY(begin: 0.5),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _googleLogin,
                    icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                    label: const Text('Google ile Devam Et'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ).animate().fade(delay: 800.ms).slideY(begin: 0.5),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zaten bir hesabım var'),
                  ).animate().fade(delay: 900.ms),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}