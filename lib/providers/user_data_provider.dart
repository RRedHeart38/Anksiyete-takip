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

  UserDataProvider() {
    if (_auth.currentUser != null) {
      fetchUserData();
    }
  }

  Future<void> fetchUserData() async {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      _userData = userDoc.data() ?? {};
    }
    _isLoading = false;
    notifyListeners();
  }
  Future<void> updateUserData(Map<String, dynamic> newData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set(
        newData,
        SetOptions(merge: true),
      );
      // Kayıttan sonra en güncel veriyi çekip tüm uygulamaya haber verelim.
      // Bu sayede Ayarlar'da ismi değiştirince, HomeScreen'deki AppBar anında güncellenir.
      await fetchUserData();
    } catch (e) {
      print("Kullanıcı verisi güncellenirken hata oluştu: $e");
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

    if (goalProgressed && data['activeGoal'] != null) {
      Map<String, dynamic> activeGoal = Map<String, dynamic>.from(data['activeGoal']);
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

    await userDocRef.update(updates);
    // Firestore güncellendikten sonra state'i de güncelleyip dinleyenlere haber ver
    _userData.addAll(updates);
    notifyListeners();
  }
}