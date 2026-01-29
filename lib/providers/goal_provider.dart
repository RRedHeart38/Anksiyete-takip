import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal.dart';
import 'achievement_provider.dart';

class GoalProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Goal> _goals = [];
  bool _isLoading = true;
  String? _currentUserId;
  AchievementProvider? _achievementProvider;

  List<Goal> get goals => _goals.where((g) => g.isActive).toList();
  List<Goal> get completedGoals => _goals.where((g) => g.isCompleted && g.isActive).toList();
  List<Goal> get activeGoals => _goals.where((g) => !g.isCompleted && g.isActive).toList();
  bool get isLoading => _isLoading;

  void setAchievementProvider(AchievementProvider provider) {
    _achievementProvider = provider;
  }

  GoalProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    if (_auth.currentUser != null) {
      _currentUserId = _auth.currentUser!.uid;
      fetchGoals();
    }
  }

  void _onAuthStateChanged(User? user) {
    if (user == null) {
      _goals = [];
      _isLoading = false;
      _currentUserId = null;
      notifyListeners();
    } else if (user.uid != _currentUserId) {
      _goals = [];
      _isLoading = true;
      _currentUserId = user.uid;
      notifyListeners();
      fetchGoals();
    }
  }

  Future<void> fetchGoals() async {
    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .where('isActive', isEqualTo: true)
          .get();

      _goals = snapshot.docs
          .map((doc) => Goal.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Eğer hiç hedef yoksa, varsayılan hedefleri ekle
      if (_goals.isEmpty) {
        await _initializeDefaultGoals();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Hedefler yüklenirken hata: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeDefaultGoals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final defaultGoals = Goal.getDefaultGoals();
    for (var goal in defaultGoals) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .add(goal.toMap());
    }

    await fetchGoals();
  }

  Future<void> createGoal(Goal goal) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .add(goal.toMap());

      await fetchGoals();
    } catch (e) {
      print('Hedef oluşturulurken hata: $e');
      rethrow;
    }
  }

  Future<void> updateGoalProgress(String goalId, int increment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final goalDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(goalId)
          .get();

      if (!goalDoc.exists) return;

      final currentProgress = goalDoc.data()?['progress'] ?? 0;
      final target = goalDoc.data()?['target'] ?? 1;
      final newProgress = (currentProgress + increment).clamp(0, target);

      final updateData = {
        'progress': newProgress,
      };

      final wasCompleted = currentProgress >= target;
      final isNowCompleted = newProgress >= target;

      // Eğer hedef tamamlandıysa
      if (isNowCompleted && !wasCompleted) {
        updateData['completedAt'] = DateTime.now().toIso8601String();
        // Başarımları kontrol et
        _achievementProvider?.checkAchievements();
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(goalId)
          .update(updateData);

      await fetchGoals();
    } catch (e) {
      print('Hedef güncellenirken hata: $e');
      rethrow;
    }
  }

  Future<void> completeGoal(String goalId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(goalId)
          .update({
        'progress': FieldValue.increment(999), // Hedefi tamamla
        'completedAt': DateTime.now().toIso8601String(),
      });

      await fetchGoals();
    } catch (e) {
      print('Hedef tamamlanırken hata: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(goalId)
          .update({'isActive': false});

      await fetchGoals();
    } catch (e) {
      print('Hedef silinirken hata: $e');
      rethrow;
    }
  }

  // Kategoriye göre hedef ilerlemesini güncelle
  Future<void> updateProgressByCategory(String category, int increment) async {
    final activeGoalsInCategory = activeGoals
        .where((g) => g.category == category && !g.isCompleted)
        .toList();

    for (var goal in activeGoalsInCategory) {
      await updateGoalProgress(goal.id, increment);
    }
  }

  // Haftalık hedefleri sıfırla (yeni hafta başında)
  Future<void> resetWeeklyGoals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final weeklyGoals = _goals.where((g) => g.type == 'weekly').toList();
      
      for (var goal in weeklyGoals) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .doc(goal.id)
            .update({
          'progress': 0,
          'completedAt': null,
        });
      }

      await fetchGoals();
    } catch (e) {
      print('Haftalık hedefler sıfırlanırken hata: $e');
    }
  }
}

