// lib/screens/thought_record_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ThoughtRecordScreen extends StatefulWidget {
  const ThoughtRecordScreen({super.key});

  @override
  State<ThoughtRecordScreen> createState() => _ThoughtRecordScreenState();
}

class _ThoughtRecordScreenState extends State<ThoughtRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form alanları için Controller'lar
  final _situationController = TextEditingController();
  final _negativeThoughtController = TextEditingController();
  final _emotionsController = TextEditingController();
  final _evidenceForController = TextEditingController();
  final _evidenceAgainstController = TextEditingController();
  final _alternativeThoughtController = TextEditingController();

  @override
  void dispose() {
    _situationController.dispose();
    _negativeThoughtController.dispose();
    _emotionsController.dispose();
    _evidenceForController.dispose();
    _evidenceAgainstController.dispose();
    _alternativeThoughtController.dispose();
    super.dispose();
  }

  Future<void> _saveThoughtRecord() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu işlemi yapmak için giriş yapmalısınız.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('thought_records') // Yeni koleksiyon
            .add({
          'durum': _situationController.text,
          'olumsuz_dusunce': _negativeThoughtController.text,
          'duygular': _emotionsController.text,
          'kanitlar': _evidenceForController.text,
          'karsi_kanitlar': _evidenceAgainstController.text,
          'alternatif_dusunce': _alternativeThoughtController.text,
          'tarih': Timestamp.now(),
          'user_id': user.uid,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Düşünce kaydınız başarıyla kaydedildi!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        print("Düşünce kaydı kaydedilirken hata oluştu: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bir hata oluştu: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Düşünce Kaydı'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _situationController,
                label: '1. Durum',
                hint: 'Neredeydiniz, ne oluyordu?',
              ),
              _buildTextField(
                controller: _negativeThoughtController,
                label: '2. Olumsuz Düşünce',
                hint: 'Aklınızdan tam olarak ne geçti?',
              ),
              _buildTextField(
                controller: _emotionsController,
                label: '3. Duygular',
                hint: 'Bu düşünce size ne hissettirdi? (örn: kaygı, üzüntü)',
              ),
              _buildTextField(
                controller: _evidenceForController,
                label: '4. Düşüncemin Kanıtları',
                hint: 'Bu düşüncenin doğru olduğuna dair kanıtlar neler?',
              ),
              _buildTextField(
                controller: _evidenceAgainstController,
                label: '5. Düşüncemin Karşı Kanıtları',
                hint: 'Bu düşüncenin doğru OLMADIĞINA dair kanıtlar neler?',
              ),
              _buildTextField(
                controller: _alternativeThoughtController,
                label: '6. Alternatif ve Dengeli Düşünce',
                hint: 'Daha gerçekçi bir bakış açısı ne olabilir?',
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _saveThoughtRecord,
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          alignLabelWithHint: true,
        ),
        maxLines: null, // İçeriğe göre otomatik büyümesini sağlar
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Bu alan boş bırakılamaz.';
          }
          return null;
        },
      ),
    );
  }
}