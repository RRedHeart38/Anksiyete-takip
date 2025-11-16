import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Birleşik liste için basit bir model sınıfı
class JournalEntry {
  final String id;
  final String type; // 'anxiety' veya 'thought'
  final DateTime date;
  final Map<String, dynamic> data;

  JournalEntry({required this.id, required this.type, required this.date, required this.data});
}

class JournalProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<JournalEntry> _entries = [];
  bool _isLoading = true;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  JournalProvider() {
    if (_auth.currentUser != null) {
      fetchJournalEntries();
    }
  }

  Future<void> fetchJournalEntries() async {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // 1. Anksiyete kayıtlarını çek
      final anxietySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_entries')
          .get();

      final List<JournalEntry> fetchedEntries = anxietySnapshot.docs.map((doc) {
        final data = doc.data();
        return JournalEntry(
          id: doc.id,
          type: 'anxiety',
          date: DateTime.parse(data['tarih'] as String),
          data: data,
        );
      }).toList();

      // 2. Düşünce kayıtlarını çek
      final thoughtSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('thought_records')
          .get();

      fetchedEntries.addAll(thoughtSnapshot.docs.map((doc) {
        final data = doc.data();
        return JournalEntry(
          id: doc.id,
          type: 'thought',
          date: (data['tarih'] as Timestamp).toDate(),
          data: data,
        );
      }));

      // 3. Birleşik listeyi tarihe göre en yeniden en eskiye doğru sırala
      fetchedEntries.sort((a, b) => b.date.compareTo(a.date));

      _entries = fetchedEntries;

    } catch (e) {
      print("Günlük verileri çekilirken hata oluştu: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}