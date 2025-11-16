// lib/screens/profile_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_remix/flutter_remix.dart';
import '../providers/user_data_provider.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _professionController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    setState(() { _isSaving = true; });

    final newData = {
      'ad_soyad': _nameController.text.trim(),
      'yas': int.tryParse(_ageController.text.trim()) ?? 0,
      'meslek': _professionController.text.trim(),
    };

    // Kaydetme işini UserDataProvider'a devrediyoruz.
    // Bu fonksiyonu daha önce Ayarlar ekranı için yazmıştık!
    await context.read<UserDataProvider>().updateUserData(newData);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Son Bir Adım Kaldı!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))
                      .animate().fade(duration: 400.ms).slideY(begin: -0.5),
                  const SizedBox(height: 8),
                  Text('Bu bilgiler, deneyimini kişiselleştirmemize yardımcı olacak.', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey))
                      .animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: -0.5),

                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Adın ve Soyadın', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(FlutterRemix.user_line)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bu alan boş bırakılamaz' : null,
                  ).animate().fade(delay: 400.ms).slideX(begin: -0.5),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Yaşın', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(FlutterRemix.cake_line)),
                    validator: (v) => (v == null || v.trim().isEmpty || int.tryParse(v.trim()) == null) ? 'Geçerli bir yaş girin' : null,
                  ).animate().fade(delay: 500.ms).slideX(begin: 0.5),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _professionController,
                    decoration: InputDecoration(labelText: 'Mesleğin', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(FlutterRemix.briefcase_line)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bu alan boş bırakılamaz' : null,
                  ).animate().fade(delay: 600.ms).slideX(begin: -0.5),

                  const SizedBox(height: 32),

                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Kaydet ve Başla', style: TextStyle(fontSize: 16)),
                  ).animate().fade(delay: 700.ms).slideY(begin: 0.5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}