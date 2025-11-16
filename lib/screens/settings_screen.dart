import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/user_data_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _professionController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _professionController = TextEditingController();

    // Verileri Provider'dan alıp form alanlarını doldur
    final userData = context.read<UserDataProvider>().userData;
    _nameController.text = userData['ad_soyad'] ?? '';
    _ageController.text = userData['yas']?.toString() ?? '';
    _professionController.text = userData['meslek'] ?? '';
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      setState(() { _isSaving = true; });

      final newData = {
        'ad_soyad': _nameController.text,
        'yas': int.tryParse(_ageController.text) ?? 0,
        'meslek': _professionController.text,
      };

      // Kaydetme işini Provider'a devrediyoruz
      await context.read<UserDataProvider>().updateUserData(newData);

      if(mounted) {
        setState(() { _isSaving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilgileriniz başarıyla kaydedildi!')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
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
    // Veri yükleme durumunu Provider'dan dinliyoruz
    final isLoading = context.watch<UserDataProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: isLoading
          ? _buildShimmerEffect() // Veri yükleniyorsa Shimmer göster
          : _buildSettingsForm(theme),   // Yüklendiyse formu göster
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildShimmerBox(height: 56), const SizedBox(height: 16),
            _buildShimmerBox(height: 56), const SizedBox(height: 16),
            _buildShimmerBox(height: 56), const SizedBox(height: 24),
            _buildShimmerBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildSettingsForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hesap Bilgileri',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Adınız ve Soyadınız', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(FlutterRemix.user_line)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Bu alan boş bırakılamaz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Yaşınız', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(FlutterRemix.cake_line)),
                  validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? 'Geçerli bir yaş girin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _professionController,
                  decoration: InputDecoration(labelText: 'Mesleğiniz', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(FlutterRemix.briefcase_line)),
                ),
                const SizedBox(height: 24),
                _isSaving
                    ? const CircularProgressIndicator()
                    : SizedBox(width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveUserData,
                    icon: const Icon(Icons.save),
                    label: const Text('Bilgileri Kaydet'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}