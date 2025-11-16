// lib/providers/anxiety_data_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class AnxietyDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double _weeklyAverage = 0.0;
  List<FlSpot> _anxietyChartData = [];
  bool _isLoading = true;
  bool _isChartLoading = true;

  double get weeklyAverage => _weeklyAverage;
  List<FlSpot> get anxietyChartData => _anxietyChartData;
  bool get isLoading => _isLoading;
  bool get isChartLoading => _isChartLoading;

  AnxietyDataProvider() {
    if (_auth.currentUser != null) {
      fetchWeeklyAverage();
      fetchAnxietyDataForChart();
    }
  }

  Future<void> saveAnxietyEntry(Map<String, dynamic> entryData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('anxiety_entries').add({
        ...entryData,
        // --- HATA BURADAYDI, DÜZELTİLDİ ---
        'tarih': DateTime.now().toIso8601String(),
      });

      await fetchWeeklyAverage();
      await fetchAnxietyDataForChart();

    } catch (e) {
      print("Anksiyete kaydı kaydedilirken hata oluştu: $e");
    }
  }

  Future<void> fetchWeeklyAverage() async {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) {
      _weeklyAverage = 0.0;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_entries')
          .where('tarih', isGreaterThanOrEqualTo: oneWeekAgo.toIso8601String())
          .get();

      if (snapshot.docs.isNotEmpty) {
        double total = 0;
        for (var doc in snapshot.docs) {
          total += (doc['kaygiSeviyesi'] as num);
        }
        _weeklyAverage = total / snapshot.docs.length;
      } else {
        _weeklyAverage = 0.0;
      }
    } catch (e) {
      print('Haftalık ortalama hatası: $e');
      _weeklyAverage = 0.0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnxietyDataForChart() async {
    _isChartLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) {
      _isChartLoading = false;
      notifyListeners();
      return;
    }

    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_entries')
          .where('tarih', isGreaterThanOrEqualTo: oneWeekAgo.toIso8601String())
          .orderBy('tarih', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        _anxietyChartData = [];
      } else {
        List<FlSpot> spots = [];
        // Grafik için gün bazlı ortalama almak daha doğru sonuç verir
        Map<int, List<double>> dailyLevels = {};

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final date = DateTime.parse(data['tarih']);
          final dayOfWeek = date.weekday; // 1 (Pzt) - 7 (Paz)
          final anxietyLevel = (data['kaygiSeviyesi'] as num).toDouble();

          if (dailyLevels.containsKey(dayOfWeek)) {
            dailyLevels[dayOfWeek]!.add(anxietyLevel);
          } else {
            dailyLevels[dayOfWeek] = [anxietyLevel];
          }
        }

        dailyLevels.forEach((day, levels) {
          double average = levels.reduce((a, b) => a + b) / levels.length;
          spots.add(FlSpot(day.toDouble(), average));
        });

        spots.sort((a, b) => a.x.compareTo(b.x));
        _anxietyChartData = spots;
      }
    } catch (e) {
      print('Grafik verisi çekilirken hata oluştu: $e');
      _anxietyChartData = [];
    } finally {
      _isChartLoading = false;
      notifyListeners();
    }
  }
}