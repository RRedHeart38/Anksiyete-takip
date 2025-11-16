// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'user_data_provider.dart';
import 'journal_provider.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _chatMessages = [];
  bool _isAnalyzing = false;
  bool _isLoadingHistory = true;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  UserDataProvider? _userDataProvider;

  List<Map<String, dynamic>> get chatMessages => _chatMessages;
  bool get isAnalyzing => _isAnalyzing;
  bool get isLoadingHistory => _isLoadingHistory;
  ChatProvider() {
    if (_auth.currentUser != null) {
      fetchChatMessages();
    }
  }

  void updateDependencies(UserDataProvider userDataProvider) {
    if (_userDataProvider != userDataProvider) {
      _userDataProvider = userDataProvider;
      if (_userDataProvider!.userData.isNotEmpty && _model == null) {
        initializeGemini();
      }
    }
  }

  @override
  void dispose() {
    _userDataProvider?.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    if (_userDataProvider != null && _userDataProvider!.userData.isNotEmpty) {
      initializeGemini();
      _userDataProvider!.removeListener(_onUserDataChanged);
    }
  }

  void initializeGemini() {
    if (_userDataProvider == null || _userDataProvider!.userData.isEmpty) {
      print("Gemini başlatılamadı: Kullanıcı verisi henüz yok.");
      return;
    }
    final userData = _userDataProvider!.userData;

    final apiKey = 'AIzaSyAIErftvt19BUFgLTPTqdFQxOCalPaY0W4'; // API Anahtarını kontrol et
    if (apiKey.startsWith('SENİN_')) {
      print('HATA: Lütfen ChatProvider içine Gemini API anahtarınızı ekleyin.');
      return;
    }

    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    final initialPrompt = 'Sen, bir ruh sağlığı uzmanı gibi davranan, destekleyici ve şefkatli bir yapay zeka koçusun. Amacın, kullanıcıya anksiyete verilerine dayanarak kişiselleştirilmiş, yapıcı ve olumlu bir geri bildirimde bulunmak. '
        'Cevapların kısa, net ve anlaşılır olsun. '
        'Herkese hastalıklıymış gibi davranma; anksiyete herkeste vardır, kaygı anlamına gelir. Sadece yüksek anksiyeteye sahip kişiler anksiyete hastasıdır. '
        'Sana yazdığı eski mesajları da göz önünde bulundur. Anlamsız mesajları ve bu mesajlardaki kaygı seviyesini önemseme. '
        'Kullanıcının bilgileri:\n'
    // --- DÜZELTME: '_userData' yerine 'userData' kullanıldı ---
        'Adı Soyadı: ${userData['ad_soyad']}\n'
        'Yaşı: ${userData['yas']}\n'
        'Mesleği: ${userData['meslek']}\n'
        'Eğer bir nefes egzersizi öneriyorsan, önerinin hemen sonuna [EGZERSİZ: Egzersiz_Adı] formatında bir etiket ekle. Örneğin: [EGZERSİZ: 4-7-8 Nefesi]. '
        'Bu bilgileri isim hariç sadece konuyla ilgili ve anlamlı olduğunda kullan, samimi ve empatik bir dil kullan. '
        'Yanıtlarını iki ana bölümden oluştur:\n'
        '1. Destekleyici Mesaj: Öncelikle kullanıcının duygularını anladığını gösteren kısa ve empatik bir mesaj ver.\n'
        '2. Somut Öneri: Anksiyete seviyesini ve tetikleyiciyi dikkate alarak, uygulanabilir, basit ve faydalı bir aktivite, düşünce tekniği veya nefes egzersizi önerisi sun. '
        'Cevaplarında daima umut verici bir dil kullan ve tıbbi tavsiye vermekten kaçın.';

    _chatSession = _model?.startChat(history: [Content.model([TextPart(initialPrompt)])]);
    print("Gemini başarıyla başlatıldı.");
  }

  Future<void> fetchChatMessages() async {
    _isLoadingHistory = true;
    notifyListeners();
    final user = _auth.currentUser;
    if (user == null){
      _isLoadingHistory = false;
    notifyListeners(); return;}
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).collection('ai_analyses').orderBy('tarih', descending: true).get();
      _chatMessages = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      notifyListeners();
    } catch (e) {
      print('Sohbet mesajları çekilirken hata oluştu: $e');
    }
    finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> sendChatMessage(String userMessage) async {
    if (_chatSession == null) {
      initializeGemini();
      if (_chatSession == null) return;
    }
    _chatMessages.insert(0, {'user_data': {'notlar': userMessage}, 'ai_response': null, 'tarih': DateTime.now().toIso8601String(), 'source': 'chat', 'id': 'temp_${DateTime.now().millisecondsSinceEpoch}'});
    notifyListeners();
    try {
      final response = await _chatSession!.sendMessage(Content.text(userMessage));
      if (response.text != null) {
        await _saveAIAnalysis({'notlar': userMessage}, response.text!, 'chat');
      }
    } catch (e) {
      print('Sohbet mesajı gönderilirken hata oluştu: $e');
    }
  }

  Future<void> analyzeAnxietyEntry(Map<String, dynamic> data) async {
    if (_chatSession == null) {
      initializeGemini();
      if (_chatSession == null) return;
    }
    _isAnalyzing = true;
    notifyListeners();
    final prompt = 'Kullanıcı anksiyete seviyesini kaydetti: ${data.toString()}';
    try {
      final response = await _chatSession!.sendMessage(Content.text(prompt));
      if (response.text != null) {
        await _saveAIAnalysis(data, response.text!, 'anxiety_tracker');
      }
    } catch (e) {
      print("AI analiz hatası: $e");
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> analyzeJournalEntry(JournalEntry entry) async {
    if (entry.type != 'thought') return;
    final data = entry.data;
    final prompt = 'Kullanıcı, geçmişte girdiği bir düşünce kaydını analiz etmeni istiyor. Lütfen bu kayda Bilişsel Davranışçı Terapi (BDT) prensiplerine göre şefkatli ve yapıcı bir geri bildirimde bulun. Kullanıcının düşünce çarpıtmalarını (örn: felaketleştirme, ya hep ya hiç düşüncesi) nazikçe belirt ve alternatif düşüncesini nasıl daha da güçlendirebileceğine dair bir öneri sun.\n\n'
        '--- Düşünce Kaydı ---\n'
        'Durum: ${data['durum']}\n'
        'Olumsuz Düşünce: ${data['olumsuz_dusunce']}\n'
        'Duygular: ${data['duygular']}\n'
        'Düşüncenin Kanıtları: ${data['kanitlar']}\n'
        'Düşüncenin Karşı Kanıtları: ${data['karsi_kanitlar']}\n'
        'Alternatif Düşünce: ${data['alternatif_dusunce']}\n'
        '--- Analiz Bekleniyor ---';
    await sendChatMessage(prompt);
  }

  Future<void> _saveAIAnalysis(Map<String, dynamic> userData, String aiResponse, String source) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).collection('ai_analyses').add({'user_data': userData, 'ai_response': aiResponse, 'tarih': DateTime.now().toIso8601String(), 'isHelpful': null, 'source': source});
      await fetchChatMessages();
    } catch (e) {
      print('Yapay zeka analizi kaydedilirken hata oluştu: $e');
    }
  }

  Future<void> saveFeedback(String docId, bool isHelpful) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).collection('ai_analyses').doc(docId).update({'isHelpful': isHelpful});
      final index = _chatMessages.indexWhere((msg) => msg['id'] == docId);
      if (index != -1) {
        _chatMessages[index]['isHelpful'] = isHelpful;
        notifyListeners();
      }
    } catch (e) {
      print('Geri bildirim kaydedilirken hata oluştu: $e');
    }
  }
}