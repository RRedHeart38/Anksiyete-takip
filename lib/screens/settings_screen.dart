import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/user_data_provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../utils/theme_provider.dart'; // Import eklendi
import 'login_screen.dart';
import 'privacy_policy_screen.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    super.dispose();
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

      final success = await context.read<UserDataProvider>().updateUserData(newData);

      if(mounted) {
        setState(() { _isSaving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Bilgileriniz başarıyla kaydedildi!' 
              : 'Bilgiler kaydedilirken bir hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
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

  Future<void> _deleteAccount() async {
    final userDataProvider = context.read<UserDataProvider>();
    final authProvider = context.read<app_auth.AuthProvider>();
    
    // Yükleniyor göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // 1. Verileri Sil
    final dataDeleted = await userDataProvider.deleteAccount();
    
    if (!dataDeleted) {
      if (mounted) Navigator.of(context).pop(); // Loading kapat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler silinirken hata oluştu.')),
        );
      }
      return;
    }

    // 2. Hesabı Sil
    final accountDeleted = await authProvider.deleteUser();

    if (mounted) Navigator.of(context).pop(); // Loading kapat

    if (accountDeleted) {
      // Başarılı, Login ekranına at
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(authProvider.errorMessage ?? 'Hesap silinemedi.')),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hesabını Sil?"),
        content: const Text(
          "Bu işlem geri alınamaz. Tüm günlüklerin, analizlerin ve başarımların kalıcı olarak silinecek. Emin misin?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Dialogu kapat
              await _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Evet, Hesabımı Sil"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<UserDataProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildShimmerEffect()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesap Bilgileri',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  _buildForm(),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Uygulama Ayarları',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                         final isDark = themeProvider.themeMode == ThemeMode.dark;
                         return SwitchListTile(
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                           title: const Text('Karanlık Mod', style: TextStyle(fontWeight: FontWeight.bold)),
                           subtitle: Text(isDark ? 'Gözlerin rahat etsin' : 'Aydınlık ve ferah'),
                           secondary: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: isDark ? Colors.purple.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                               shape: BoxShape.circle,
                             ),
                             child: Icon(
                               isDark ? FlutterRemix.moon_clear_line : FlutterRemix.sun_line,
                               color: isDark ? Colors.purpleAccent : Colors.orange,
                             ),
                           ),
                           value: isDark,
                           onChanged: (val) {
                             HapticFeedback.lightImpact();
                             themeProvider.toggleTheme();
                           },
                         );
                      },
                    ),
                  ),
                  // Legal & Info
                  Text(
                    'Yasal & Hakkında',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                   Card(
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.policy_outlined),
                          title: const Text('Gizlilik Politikası ve KVKK'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())),
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Uygulama Hakkında'),
                          subtitle: const Text('v1.0.0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Delete Account Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _showDeleteConfirmation,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Hesabımı Sil'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
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

  Widget _buildForm() {
    return Form(
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
              ? const Center(child: CircularProgressIndicator())
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
    );
  }
}