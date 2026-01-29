import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  Map<String, dynamic> get userData => _userData;
  bool get isLoading => _isLoading;
  String get userName => _userData['ad_soyad'] as String? ?? 'Kullanıcı';
  int get streakCount => _userData['streakCount'] as int? ?? 0;
  Map<String, dynamic> get activeGoal => _userData['activeGoal'] as Map<String, dynamic>? ?? {};
  
  // Profil bilgilerinin tamamlanıp tamamlanmadığını kontrol eder
  bool get isProfileComplete {
    final adSoyad = _userData['ad_soyad'] as String?;
    final yas = _userData['yas'];
    final meslek = _userData['meslek'] as String?;
    
    return adSoyad != null && 
           adSoyad.trim().isNotEmpty && 
           yas != null && 
           yas is int && 
           yas > 0 &&
           meslek != null && 
           meslek.trim().isNotEmpty;
  }

  String? _currentUserId;

  UserDataProvider() {
    // Kullanıcı değişikliklerini dinle
    _auth.authStateChanges().listen(_onAuthStateChanged);
    if (_auth.currentUser != null) {
      _currentUserId = _auth.currentUser!.uid;
      fetchUserData();
    }
  }

  void _onAuthStateChanged(User? user) {
    // Kullanıcı değiştiğinde verileri temizle
    if (user == null) {
      // Çıkış yapıldı
      _userData = {};
      _isLoading = false;
      _currentUserId = null;
      notifyListeners();
    } else if (user.uid != _currentUserId) {
      // Yeni kullanıcı giriş yaptı
      _userData = {};
      _isLoading = true;
      _currentUserId = user.uid;
      notifyListeners();
      fetchUserData();
    }
  }

  Future<void> fetchUserData() async {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        _userData = userDoc.data() ?? {};
      } catch (e) {
        print('Kullanıcı verisi çekilirken hata oluştu: $e');
        // Hata durumunda boş map kullan, uygulama çökmesin
        _userData = {};
      }
    }
    _isLoading = false;
    notifyListeners();
  }
  Future<bool> updateUserData(Map<String, dynamic> newData) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).set(
        newData,
        SetOptions(merge: true),
      );
      // Kayıttan sonra en güncel veriyi çekip tüm uygulamaya haber verelim.
      // Bu sayede Ayarlar'da ismi değiştirince, HomeScreen'deki AppBar anında güncellenir.
      await fetchUserData();
      return true;
    } catch (e) {
      print("Kullanıcı verisi güncellenirken hata oluştu: $e");
      return false;
    }
  }

  Future<void> updateStreakAndGoals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDocRef = _firestore.collection('users').doc(user.uid);
    // En güncel veriyi kullanmak için mevcut state'i alıyoruz
    final data = _userData;

    int currentStreak = data['streakCount'] as int? ?? 0;
    DateTime? lastLogDateTime;
    if (data['lastLogDate'] != null) {
      lastLogDateTime = (data['lastLogDate'] as Timestamp).toDate();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogDate = lastLogDateTime != null
        ? DateTime(lastLogDateTime.year, lastLogDateTime.month, lastLogDateTime.day)
        : null;

    bool goalProgressed = false;

    if (lastLogDate == null) {
      currentStreak = 1;
      goalProgressed = true;
    } else if (!lastLogDate.isAtSameMomentAs(today)) {
      if (lastLogDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
        currentStreak++;
        goalProgressed = true;
      } else {
        currentStreak = 1;
        goalProgressed = true;
      }
    }

    final Map<String, dynamic> updates = {
      'streakCount': currentStreak,
      'lastLogDate': Timestamp.now(),
    };

    // Eğer goal progress yapıldıysa goal'ı güncelle veya oluştur
    if (goalProgressed) {
      Map<String, dynamic> activeGoal;
      
      // Eğer activeGoal yoksa yeni bir tane oluştur
      if (data['activeGoal'] == null) {
        activeGoal = {
          'type': 'daily_log',
          'target': 7,
          'progress': 1,
        };
        updates['activeGoal'] = activeGoal;
      } else {
        // Mevcut goal'ı güncelle
        activeGoal = Map<String, dynamic>.from(data['activeGoal']);
        if (activeGoal['type'] == 'daily_log') {
          int currentProgress = activeGoal['progress'] as int? ?? 0;
          int target = activeGoal['target'] as int? ?? 7;

          if (currentProgress < target) {
            currentProgress++;
            activeGoal['progress'] = currentProgress;
            updates['activeGoal'] = activeGoal;
          }
        }
      }
    }

    await userDocRef.update(updates);
    // Firestore güncellendikten sonra güncel veriyi çek
    await fetchUserData();
  }
  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Alt koleksiyonları sil (Firestore'da recursive silme yoktur, elle silmeliyiz)
      final subcollections = ['journal_entries', 'anxiety_entries', 'ai_analyses', 'goals', 'meditation_sessions'];
      
      for (var collectionName in subcollections) {
        final snapshot = await _firestore.collection('users').doc(user.uid).collection(collectionName).get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }

      // 2. Ana kullanıcı dokümanını sil
      await _firestore.collection('users').doc(user.uid).delete();
      
      return true;
    } catch (e) {
      print("Hesap verileri silinirken hata oluştu: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}