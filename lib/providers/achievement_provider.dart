import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/achievement.dart';

class AchievementProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Achievement> _achievements = [];
  bool _isLoading = true;
  String? _currentUserId;
  Achievement? _lastUnlockedAchievement;
  Function(Achievement)? onAchievementUnlocked;

  List<Achievement> get achievements => _achievements;
  bool get isLoading => _isLoading;
  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;
  int get totalCount => _achievements.length;
  double get progressPercentage => totalCount > 0 ? (unlockedCount / totalCount) * 100 : 0;

  AchievementProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    if (_auth.currentUser != null) {
      _currentUserId = _auth.currentUser!.uid;
      fetchAchievements();
    }
  }

  void _onAuthStateChanged(User? user) {
    if (user == null) {
      _achievements = [];
      _isLoading = false;
      _currentUserId = null;
      notifyListeners();
    } else if (user.uid != _currentUserId) {
      _achievements = [];
      _isLoading = true;
      _currentUserId = user.uid;
      notifyListeners();
      fetchAchievements();
    }
  }

  Future<void> fetchAchievements() async {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Önce tüm başarım tanımlarını al
      final allAchievements = AchievementDefinitions.getAllAchievements();

      // Kullanıcının kazandığı başarımları Firestore'dan al
      final unlockedSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .get();

      final unlockedMap = <String, Achievement>{};
      for (var doc in unlockedSnapshot.docs) {
        final data = doc.data();
        final achievement = Achievement.fromMap(data);
        unlockedMap[achievement.id] = achievement;
      }

      // Başarımları birleştir (unlocked olanları güncelle)
      _achievements = allAchievements.map((achievement) {
        if (unlockedMap.containsKey(achievement.id)) {
          return unlockedMap[achievement.id]!;
        }
        return achievement;
      }).toList();

      // Progress hesaplamaları yap ve güncelle
      await _checkAndUnlockAchievements();
    } catch (e) {
      print('Başarımlar çekilirken hata oluştu: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAndUnlockAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userStats = await _getUserStats();
    bool hasNewAchievements = false;

    for (int i = 0; i < _achievements.length; i++) {
      final achievement = _achievements[i];
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;
      int currentValue = 0;

      switch (achievement.type) {
        case AchievementType.firstEntry:
          currentValue = userStats['anxietyEntries'] ?? 0;
          shouldUnlock = currentValue >= 1;
          break;
        case AchievementType.streak7:
          currentValue = userStats['streakCount'] ?? 0;
          shouldUnlock = currentValue >= 7;
          break;
        case AchievementType.streak30:
          currentValue = userStats['streakCount'] ?? 0;
          shouldUnlock = currentValue >= 30;
          break;
        case AchievementType.streak100:
          currentValue = userStats['streakCount'] ?? 0;
          shouldUnlock = currentValue >= 100;
          break;
        case AchievementType.firstThought:
          currentValue = userStats['thoughtRecords'] ?? 0;
          shouldUnlock = currentValue >= 1;
          break;
        case AchievementType.firstJournal:
          currentValue = userStats['journalEntries'] ?? 0;
          shouldUnlock = currentValue >= 1;
          break;
        case AchievementType.firstBreathing:
          currentValue = userStats['breathingExercises'] ?? 0;
          shouldUnlock = currentValue >= 1;
          break;
        case AchievementType.thoughtMaster:
          currentValue = userStats['thoughtRecords'] ?? 0;
          shouldUnlock = currentValue >= 10;
          break;
        case AchievementType.thoughtExpert:
          currentValue = userStats['thoughtRecords'] ?? 0;
          shouldUnlock = currentValue >= 50;
          break;
        case AchievementType.journalWriter:
          currentValue = userStats['journalEntries'] ?? 0;
          shouldUnlock = currentValue >= 10;
          break;
        case AchievementType.journalAuthor:
          currentValue = userStats['journalEntries'] ?? 0;
          shouldUnlock = currentValue >= 50;
          break;
        case AchievementType.breathingPractitioner:
          currentValue = userStats['breathingExercises'] ?? 0;
          shouldUnlock = currentValue >= 10;
          break;
        case AchievementType.chatActive:
          currentValue = userStats['chatMessages'] ?? 0;
          shouldUnlock = currentValue >= 10;
          break;
        case AchievementType.weeklyTracker:
          currentValue = userStats['weeksTracked'] ?? 0;
          shouldUnlock = currentValue >= 7;
          break;
        case AchievementType.firstMeditation:
          currentValue = userStats['meditations'] ?? 0;
          shouldUnlock = currentValue >= 1;
          break;
        case AchievementType.meditationBeginner:
          currentValue = userStats['meditations'] ?? 0;
          shouldUnlock = currentValue >= 5;
          break;
        case AchievementType.meditationMaster:
          currentValue = userStats['meditations'] ?? 0;
          shouldUnlock = currentValue >= 25;
          break;
        case AchievementType.goalAchiever:
          currentValue = userStats['completedGoals'] ?? 0;
          shouldUnlock = currentValue >= 1;
          break;
        case AchievementType.goalChampion:
          currentValue = userStats['completedGoals'] ?? 0;
          shouldUnlock = currentValue >= 10;
          break;
        case AchievementType.goalLegend:
          currentValue = userStats['completedGoals'] ?? 0;
          shouldUnlock = currentValue >= 50;
          break;
      }

      if (shouldUnlock && currentValue >= achievement.targetValue) {
        await unlockAchievement(achievement.id);
        hasNewAchievements = true;
      }
    }

    if (hasNewAchievements) {
      await fetchAchievements();
    }
  }

  Future<Map<String, int>> _getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      // Streak count'u user doc'tan al
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final streakCount = userDoc.data()?['streakCount'] as int? ?? 0;

      // Anksiyete kayıtları
      final anxietySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_entries')
          .get();

      // Düşünce kayıtları
      final thoughtSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('thought_records')
          .get();

      // Günlük yazıları
      final journalSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journal_entries')
          .get();

      // AI sohbetleri
      final chatSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_analyses')
          .where('source', isEqualTo: 'chat')
          .get();

      // Haftalık takip hesapla (benzersiz haftalar)
      final weeksTracked = _calculateWeeksTracked(anxietySnapshot.docs);

      // Nefes egzersizleri
      final breathingSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('breathing_exercises')
          .get();

      final breathingExercises = breathingSnapshot.docs.length;

      // Meditasyonlar (meditation_completions collection'ından)
      final meditationSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meditation_completions')
          .get();

      // Tamamlanan hedefler
      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .where('isActive', isEqualTo: true)
          .get();
      
      final completedGoals = goalsSnapshot.docs
          .where((doc) {
            final data = doc.data();
            final progress = data['progress'] as int? ?? 0;
            final target = data['target'] as int? ?? 1;
            return progress >= target;
          })
          .length;

      return {
        'streakCount': streakCount,
        'anxietyEntries': anxietySnapshot.docs.length,
        'thoughtRecords': thoughtSnapshot.docs.length,
        'journalEntries': journalSnapshot.docs.length,
        'chatMessages': chatSnapshot.docs.length,
        'breathingExercises': breathingExercises,
        'weeksTracked': weeksTracked,
        'meditations': meditationSnapshot.docs.length,
        'completedGoals': completedGoals,
      };
    } catch (e) {
      print('Kullanıcı istatistikleri alınırken hata: $e');
      return {};
    }
  }

  int _calculateWeeksTracked(List<QueryDocumentSnapshot> entries) {
    if (entries.isEmpty) return 0;

    final weeks = <String>{};
    for (var doc in entries) {
      final data = doc.data() as Map<String, dynamic>;
      final tarihStr = data['tarih'] as String?;
      if (tarihStr != null) {
        try {
          final date = DateTime.parse(tarihStr);
          final year = date.year;
          final week = _getWeekOfYear(date);
          weeks.add('$year-W$week');
        } catch (e) {
          // Tarih parse edilemezse atla
        }
      }
    }
    return weeks.length;
  }

  int _getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(startOfYear).inDays;
    return (daysSinceStart / 7).floor() + 1;
  }

  Future<void> unlockAchievement(String achievementId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final achievement = _achievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => AchievementDefinitions.getAllAchievements()
            .firstWhere((a) => a.id == achievementId),
      );

      // Eğer zaten açıksa tekrar açma
      if (achievement.isUnlocked) return;

      final unlockedAchievement = achievement.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .doc(achievementId)
          .set(unlockedAchievement.toMap());

      // Local state'i güncelle
      final index = _achievements.indexWhere((a) => a.id == achievementId);
      if (index != -1) {
        _achievements[index] = unlockedAchievement;
      }
      
      // Son açılan başarımı kaydet ve callback çağır
      _lastUnlockedAchievement = unlockedAchievement;
      notifyListeners();
      
      // Callback varsa çağır
      if (onAchievementUnlocked != null) {
        onAchievementUnlocked!(unlockedAchievement);
      }
    } catch (e) {
      print('Başarım kilit açılırken hata: $e');
    }
  }
  
  Achievement? get lastUnlockedAchievement => _lastUnlockedAchievement;
  
  void clearLastUnlocked() {
    _lastUnlockedAchievement = null;
    notifyListeners();
  }

  // Manuel olarak başarımları kontrol et (diğer provider'lardan çağrılabilir)
  Future<void> checkAchievements() async {
    await _checkAndUnlockAchievements();
    await fetchAchievements();
  }
}

