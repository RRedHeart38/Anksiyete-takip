import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _googleLogin() async {
    HapticFeedback.lightImpact();
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.signInWithGoogle();

    if (result['success'] == true && mounted) {
      if (result['isNewUser'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
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
                  Text('Tekrar Hoş Geldin!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))
                      .animate().fade(duration: 400.ms).slideY(begin: -0.5),
                  const SizedBox(height: 8),
                  Text('Hesabına giriş yaparak devam et.', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey))
                      .animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: -0.5),

                  const SizedBox(height: 32),

                  if (authProvider.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
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

                  const SizedBox(height: 24),

                  authProvider.status == AuthStatus.Authenticating
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Giriş Yap', style: TextStyle(fontSize: 16)),
                  ).animate().fade(delay: 600.ms).slideY(begin: 0.5),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _googleLogin,
                    icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                    label: const Text('Google ile Giriş Yap'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ).animate().fade(delay: 700.ms).slideY(begin: 0.5),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())), child: const Text('Şifremi Unuttum?')),
                      TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Hesap Oluştur')),
                    ],
                  ).animate().fade(delay: 800.ms),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}