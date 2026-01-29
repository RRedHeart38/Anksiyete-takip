// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'user_data_provider.dart';
import 'journal_provider.dart';
import 'achievement_provider.dart';
import '../services/encryption_service.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _chatMessages = [];
  bool _isAnalyzing = false;
  bool _isLoadingHistory = true;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  UserDataProvider? _userDataProvider;
  AchievementProvider? _achievementProvider;

  List<Map<String, dynamic>> get chatMessages => _chatMessages;
  bool get isAnalyzing => _isAnalyzing;
  bool get isLoadingHistory => _isLoadingHistory;
  String? _currentUserId;
  
  // Daily Plan Variables
  List<Map<String, dynamic>> _dailyPlan = [];
  bool _isGeneratingPlan = false;
  
  List<Map<String, dynamic>> get dailyPlan => _dailyPlan;
  bool get isGeneratingPlan => _isGeneratingPlan;

  ChatProvider() {
    // Kullanıcı değişikliklerini dinle
    _auth.authStateChanges().listen(_onAuthStateChanged);
    if (_auth.currentUser != null) {
      _currentUserId = _auth.currentUser!.uid;
      fetchChatMessages();
    }
  }

  void _onAuthStateChanged(User? user) {
    // Kullanıcı değiştiğinde verileri temizle
    if (user == null) {
      // Çıkış yapıldı
      _chatMessages = [];
      _chatSession = null;
      _model = null;
      _isAnalyzing = false;
      _isLoadingHistory = false;
      _currentUserId = null;
      notifyListeners();
    } else if (user.uid != _currentUserId) {
      // Yeni kullanıcı giriş yaptı
      _chatMessages = [];
      _chatSession = null;
      _model = null;
      _isAnalyzing = false;
      _isLoadingHistory = true;
      _currentUserId = user.uid;
      // UserDataProvider varsa Gemini'yi yeniden başlat
      if (_userDataProvider != null) {
        initializeGemini(); // Fire and forget - async call
      }
      notifyListeners();
      fetchChatMessages();
    }
  }

  void updateDependencies(UserDataProvider userDataProvider) {
    if (_userDataProvider != userDataProvider) {
      _userDataProvider?.removeListener(_onUserDataChanged);
      _userDataProvider = userDataProvider;
      if (_userDataProvider!.userData.isNotEmpty && _model == null) {
        initializeGemini(); // Fire and forget - async call
      } else if (_userDataProvider!.userData.isEmpty && !_userDataProvider!.isLoading) {
        // User data is empty but not loading - might be a new user, listen for changes
        _userDataProvider!.addListener(_onUserDataChanged);
      }
    }
  }

  void setAchievementProvider(AchievementProvider? achievementProvider) {
    _achievementProvider = achievementProvider;
  }

  @override
  void dispose() {
    _userDataProvider?.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    if (_userDataProvider != null && _userDataProvider!.userData.isNotEmpty) {
      initializeGemini(); // Fire and forget - async call
      _userDataProvider!.removeListener(_onUserDataChanged);
    }
  }

  Future<bool> initializeGemini() async {
    if (_userDataProvider == null) {
      print("Gemini başlatılamadı: UserDataProvider henüz ayarlanmamış.");
      return false;
    }
    
    // For new users, userData might be empty, but we can still initialize
    // with default values in the prompt
    final userData = _userDataProvider!.userData;
    
    // If user data is empty, we'll use default values in the prompt
    if (userData.isEmpty) {
      print("Kullanıcı verisi boş, varsayılan değerlerle Gemini başlatılıyor...");
    }

    // API key'i güvenli bir şekilde .env dosyasından oku
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('HATA: GEMINI_API_KEY .env dosyasında bulunamadı.');
      _addSystemMessage("Hata: API anahtarı bulunamadı. Lütfen geliştirici ile iletişime geçin.");
      return false;
    }
    
    try {
      final safetySettings = [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
      ];

      _model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: apiKey,
        safetySettings: safetySettings,
        generationConfig: GenerationConfig(temperature: 0.5),
      );
      
      // 1. KULLANICI PROFİLİ
      String userInfoSection = '';
      if (userData.isNotEmpty) {
        userInfoSection = 'KULLANICI PROFİLİ:\n'
            '- Adı: ${userData['ad_soyad'] ?? 'Belirtilmemiş'}\n'
            '- Yaş: ${userData['yas'] ?? 'Belirtilmemiş'}\n'
            '- Meslek: ${userData['meslek'] ?? 'Belirtilmemiş'}\n';
      } else {
        userInfoSection = 'KULLANICI PROFİLİ: Yeni kullanıcı (Profil henüz boş).\n';
      }
      
      // 2. GÜNCEL BAĞLAM (Zaman, vb.)
      final timeContext = _getTimeContext();

      // 3. ANKSİYETE TRENDLERİ VE SON DURUM
      final anxietyTrendContext = await _calculateAnxietyTrend();
      
      // 4. BAŞARIMLAR VE MOTİVASYON
      final achievementContext = _getAchievementContext();

      // 5. GEÇMİŞ GÜNLÜKLER
      final journalSection = await _getRecentJournalEntries();
      
      // 6. HAFIZA VE GERİ BİLDİRİM (Feedback Loop)
      final memoryContext = _getFeedbackAndMemoryContext();
      
      final initialPrompt = """
      SENIN ROLÜN:
      Sen, Bilişsel Davranışçı Terapi (BDT) prensiplerini benimsemiş, şefkatli, motive edici ve son derece zeki bir ruh sağlığı asistanısın. Amacın, kullanıcıya kaygı yönetiminde rehberlik etmek, farkındalık kazandırmak ve onu daha iyi hissetmesi için desteklemektir.
      
      ASLA YAPMAMAN GEREKENLER:
      - Tıbbi teşhis koyma.
      - Çok uzun ve didaktik (ders verir gibi) konuşma. Sohbet et.
      - Kullanıcıyı yargılama.
      - Robotik veya soğuk konuşma.

      BAĞLAM VERİLERİ (Bunları yanıtlarını kişiselleştirmek için kullan):
      
      $userInfoSection
      
      $timeContext
      
      $anxietyTrendContext
      
      $achievementContext
      
      $journalSection
      
      $memoryContext
      
      YANIT STRATEJİSİ:
      1. **Empati Kur:** Kullanıcının mevcut duygu durumunu anladığını hissettir.
      2. **Kişiselleştir:** Yukarıdaki bağlam verilerini (örn. "Gece geç oldu", "Tebrikler 3 gündür seriyi bozmuyorsun", "Geçen sefer nefes egzersizini sevmiştin") yanıtlarına yedir.
      3. **Harekete Geçir:** Duruma uygun, basit, uygulanabilir bir öneri sun (BDT tekniği, nefes egzersizi, veya sadece bir düşünce sorusu).
      4. **Nefes Egzersizi Önerisi:** Eğer nefes egzersizi öneriyorsan, cümlenin sonuna mutlaka [EGZERSİZ: Egzersiz_Adı] etiketini ekle. (Örn: [EGZERSİZ: 4-7-8 Tekniği]). 
      5. **Meditasyon Önerisi:** Eğer meditasyon veya mindfulness öneriyorsan, cümlenin sonuna mutlaka [MEDİTASYON: Meditasyon_Adı] etiketini ekle. (Örn: [MEDİTASYON: 5 Dakikalık Sakinleşme]).
      
      KULLANILABİLİR EGZERSİZ LİSTESİ (Sadece bunları öner):
      - 4-7-8 Tekniği (Stres ve uyku için)
      - Kutu Nefesi (Odaklanma için)
      - Diyafram Nefesi (Gevşeme için)
      - Derin Nefes Egzersizi (Genel sakinlik için)
      - Alternatif Burun Nefesi (Denge için)

      KULLANILABİLİR MEDİTASYON LİSTESİ (Sadece bunları öner):
      - 5 Dakikalık Sakinleşme (Hızlı sakinleşme)
      - 10 Dakikalık Derin Rahatlama (Derin gevşeme)
      - 15 Dakikalık Farkındalık (Uzun farkındalık)
      - Nefes Farkındalığı (Ana odaklanma)
      - Duyusal Farkındalık (Duyularla anda kalma)
      - Yürüyüş Meditasyonu (Hareketli meditasyon)
      - Kısa Beden Taraması (Beden farkındalığı)
      - Derin Beden Taraması (Tüm vücut gevşeme)
      - Güvenli Yer Görselleştirmesi (Güvende hissetme)
      - Doğa Görselleştirmesi (Huzur bulma)
      
      Eğer listede olmayan bir egzersiz veya meditasyon önereceksen, etiket KULLANMA, sadece tarif et.
      
      Kullanıcı: "Bugün çok kötüyüm, sınavdan kaldım."
      Kötü Cevap: "Üzülme, bir dahakine yaparsın. Çalışman lazım."
      İyi Cevap: "Bunu duyduğuma gerçekten üzüldüm, hayal kırıklığına uğramış olmalısın. Sınavlar bazen beklediğimiz gibi gitmeyebiliyor. Şu an kendine yüklenmek yerine, bu durumu biraz konuşmak ister misin? Seni en çok üzen şey notun düşüklüğü mü yoksa verdiğin emeğin karşılığını alamamak mı?"

      Kullanıcı: "Kalbim küt küt atıyor, nefes alamıyorum."
      İyi Cevap: "Şu an panik atak belirtileri yaşıyor olabilirsin, ben buradayım. Hemen şimdi durup, birlikte derin bir nefes alalım. [EGZERSİZ: Kutu Nefesi] Sadece nefesine odaklan."
      
      Şimdi, bu persona ve bilgiler ışığında kullanıcıyla sohbete başla veya yanıt ver.
      """;

      _chatSession = _model?.startChat(history: [Content.model([TextPart(initialPrompt)])]);
      print("Gemini başarıyla başlatıldı (Gelişmiş Mod).");
      return true;
    } catch (e) {
      print("Gemini başlatma hatası: $e");
      _addSystemMessage("Yapay zeka başlatılamadı: $e");
      return false;
    }
  }
  
  void _addSystemMessage(String message) {
     _chatMessages.insert(0, {
       'user_data': null, 
       'ai_response': message, // AI response olarak gösterelim ki sol tarafta görünsün
       'tarih': DateTime.now().toIso8601String(), 
       'source': 'system_error', 
       'id': 'error_${DateTime.now().millisecondsSinceEpoch}'
     });
     notifyListeners();
  }
  
  Future<String> _getRecentJournalEntries() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    
    try {
      // Son 10 günlük girişini al (son 7 gün için)
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journal_entries')
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('tarih', descending: true)
          .limit(10)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return '';
      }
      
      String journalText = '\nKullanıcının son günlük girişleri (bu bilgileri yanıtlarında göz önünde bulundur):\n';
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final baslik = data['baslik'] ?? '';
        final icerik = data['icerik'] ?? '';
        final tarih = (data['tarih'] as Timestamp).toDate();
        final dateStr = '${tarih.day}/${tarih.month}/${tarih.year}';
        
        journalText += '- $dateStr: $baslik - $icerik\n';
      }
      
      return journalText;
    } catch (e) {
      print('Günlük girişleri çekilirken hata oluştu: $e');
      return '';
    }
  }

  Future<void> fetchChatMessages() async {
    _isLoadingHistory = true;
    notifyListeners();
    final user = _auth.currentUser;
    if (user == null) {
      _isLoadingHistory = false;
      notifyListeners();
      return;
    }
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_analyses')
          .orderBy('tarih', descending: true)
          .get();
      
      final encryptionService = EncryptionService();
      _chatMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Decrypt AI Response
        if (data['ai_response'] != null && data['ai_response'] is String) {
          data['ai_response'] = encryptionService.decrypt(data['ai_response']);
        }
        
        // Decrypt User Data (specifically string fields like notes)
        if (data['user_data'] != null && data['user_data'] is Map) {
          final Map<String, dynamic> decryptedUserData = Map<String, dynamic>.from(data['user_data']);
          decryptedUserData.forEach((key, value) {
            if (value is String) {
              decryptedUserData[key] = encryptionService.decrypt(value);
            }
          });
          data['user_data'] = decryptedUserData;
        }
        
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      print('Sohbet mesajları çekilirken hata oluştu: $e');
      // Hata durumunda boş liste kullan, uygulama çökmesin
      _chatMessages = [];
      _addSystemMessage("Sohbet geçmişi yüklenemedi: İnternet bağlantınızı kontrol edin.");
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> sendChatMessage(String userMessage) async {
    if (_chatSession == null) {
      final success = await initializeGemini();
      if (!success) return; 
    }
    _chatMessages.insert(0, {'user_data': {'notlar': userMessage}, 'ai_response': null, 'tarih': DateTime.now().toIso8601String(), 'source': 'chat', 'id': 'temp_${DateTime.now().millisecondsSinceEpoch}'});
    notifyListeners();
    try {
      // Son günlük girişlerini mesaja ekle
      final journalContext = await _getRecentJournalEntries();
      String messageWithContext = userMessage;
      if (journalContext.isNotEmpty) {
        // Günlük girişlerini mesaja ekle (başlık kısmını kaldırarak sadece içeriği ekle)
        final journalContent = journalContext.replaceFirst('\nKullanıcının son günlük girişleri (bu bilgileri yanıtlarında göz önünde bulundur):\n', '');
        messageWithContext = '$userMessage\n\nGünlük Girişlerini Göz Önünde Bulundur:\n$journalContent';
      }
      
      final response = await _chatSession!.sendMessage(Content.text(messageWithContext));
      if (response.text != null) {
        await _saveAIAnalysis({'notlar': userMessage}, response.text!, 'chat');
        
        // Başarımları kontrol et
        if (_achievementProvider != null) {
          _achievementProvider!.checkAchievements();
        }
      }
    } catch (e) {
      print('Sohbet mesajı gönderilirken hata oluştu: $e');
      _addSystemMessage("Mesaj gönderilemedi: $e");
    }
  }

  Future<void> analyzeAnxietyEntry(Map<String, dynamic> data) async {
    // Ensure user data is available before initializing
    if (_userDataProvider == null) {
      print("AI analiz hatası: UserDataProvider henüz ayarlanmamış.");
      _addSystemMessage("Sistem hatası: Veri sağlayıcısı hazırlanmadı.");
      return;
    }

    // If user data is still loading, wait for it
    if (_userDataProvider!.isLoading) {
      // Wait for user data to load (with timeout)
      int attempts = 0;
      while (_userDataProvider!.isLoading && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
    }

    // Try to initialize Gemini if not already initialized
    if (_chatSession == null) {
      final success = await initializeGemini();
      if (!success) {
        print("AI analiz hatası: Gemini başlatılamadı.");
        return;
      }
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
      _addSystemMessage("Analiz yapılamadı: $e");
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
      final encryptionService = EncryptionService();
      
      // Encrypt AI Response
      final encryptedAiResponse = encryptionService.encrypt(aiResponse);
      
      // Encrypt User Data
      final Map<String, dynamic> encryptedUserData = {};
      userData.forEach((key, value) {
        if (value is String) {
          encryptedUserData[key] = encryptionService.encrypt(value);
        } else {
          encryptedUserData[key] = value;
        }
      });

      await _firestore.collection('users').doc(user.uid).collection('ai_analyses').add({
        'user_data': encryptedUserData, 
        'ai_response': encryptedAiResponse, 
        'tarih': DateTime.now().toIso8601String(), 
        'isHelpful': null, 
        'source': source
      });
      await fetchChatMessages();
    } catch (e) {
      print('Yapay zeka analizi kaydedilirken hata oluştu: $e');
    }
  }

  Future<String> _calculateAnxietyTrend() async {
    final user = _auth.currentUser;
    if (user == null) return '';

    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_entries')
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
          .orderBy('tarih', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return 'ANKSİYETE TRENDİ: Son 7 gün için veri yok.\n';

      List<int> levels = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['kaygiSeviyesi'] != null) {
          levels.add((data['kaygiSeviyesi'] as num).toInt());
        }
      }

      if (levels.isEmpty) return 'ANKSİYETE TRENDİ: Veri yetersiz.\n';

      final average = levels.reduce((a, b) => a + b) / levels.length;
      final lastLevel = levels.first;
      
      // Trend analizi
      String trend = 'sabit';
      if (levels.length >= 2) {
        // Basitçe son 3 kayda bakarak trend belirleyelim
        final recentLevels = levels.take(3).toList();
        if (recentLevels.first > recentLevels.last) {
          trend = 'artışta';
        } else if (recentLevels.first < recentLevels.last) {
          trend = 'düşüşte';
        }
      }

      return 'ANKSİYETE TRENDİ: Son 7 günlük ortalama: ${average.toStringAsFixed(1)}. Son ölçülen seviye: $lastLevel. Genel eğilim: $trend.\n';
    } catch (e) {
      print("Trend hesaplama hatası: $e");
      return '';
    }
  }

  String _getAchievementContext() {
    if (_achievementProvider == null) return '';
    
    final streak = _achievementProvider!.achievements.firstWhere((a) => a.type.toString().contains('streak'), orElse: () => _achievementProvider!.achievements.first).title; // Basit bir örnek
    final totalStats = _userDataProvider != null ? "Seri: ${_userDataProvider!.streakCount} gün." : "";
    
    // Son kazanılan başarım
    String lastUnlocked = '';
    if (_achievementProvider!.lastUnlockedAchievement != null) {
      lastUnlocked = "SON KAZANILAN BAŞARIM: ${_achievementProvider!.lastUnlockedAchievement!.title}. ";
    }
    
    return 'BAŞARIMLAR VE MOTİVASYON: $totalStats $lastUnlocked Kullanıcının motive edilmeye ihtiyacı varsa bu başarıları vurgula.\n';
  }

  String _getTimeContext() {
    final now = DateTime.now();
    final hour = now.hour;
    String timePhase = '';
    
    if (hour >= 5 && hour < 12) {
      timePhase = 'Sabah (Güne başlarken, niyet belirlemek için uygun)';
    } else if (hour >= 12 && hour < 18) {
      timePhase = 'Öğleden Sonra (Gün ortası stresi olabilir)';
    } else if (hour >= 18 && hour < 22) {
      timePhase = 'Akşam (Günü değerlendirme)';
    } else {
      timePhase = 'Gece (Uyku öncesi, sakinleşme ihtiyacı, endişeler artabilir)';
    }
    
    return 'ŞU ANKİ ZAMAN: Saat $hour:${now.minute.toString().padLeft(2, '0')}. Evre: $timePhase.\n';
  }

  String _getFeedbackAndMemoryContext() {
    // Sohbet geçmişinden kullanıcının neleri sevip sevmediğini çıkar
    int helpfulCount = 0;
    int unhelpfulCount = 0;
    
    for (var msg in _chatMessages) {
      if (msg['isHelpful'] == true) helpfulCount++;
      if (msg['isHelpful'] == false) unhelpfulCount++;
    }
    
    String feedbackSummary = '';
    if (helpfulCount > unhelpfulCount) {
      feedbackSummary = 'Kullanıcı genellikle senin önerilerini faydalı buluyor. Mevcut üslubunu koru.';
    } else if (unhelpfulCount > 0) {
      feedbackSummary = 'Kullanıcı bazı yanıtlarını faydalı bulmadı. Daha farklı, belki daha az tavsiye veren ve daha çok dinleyen bir yaklaşım dene.';
    }
    
    return 'GEÇMİŞ GERİ BİLDİRİMLER: $feedbackSummary (Faydalı: $helpfulCount, Faydasız: $unhelpfulCount yanıt).\n';
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

  DateTime? _lastPlanGenerationAttempt;
  bool _isRateLimited = false;

  Future<void> generateDailyPlan() async {
    // RATE LIMIT CHECK:
    // 1. If we are already generating, stop.
    // 2. If we have a plan effectively loaded, stop.
    if (_dailyPlan.isNotEmpty || _isGeneratingPlan) return;
    
    // 3. If we hit a hard rate limit (Quota Exceeded), stop for 1 hour.
    if (_isRateLimited && _lastPlanGenerationAttempt != null) {
       final difference = DateTime.now().difference(_lastPlanGenerationAttempt!);
       if (difference.inHours < 1) {
         print("AI Rate Limit: Background task skipped due to quota limit.");
         return;
       }
       // Reset after 1 hour
       _isRateLimited = false;
    }

    // 4. Standard Cooldown: Don't try more than once every 15 minutes for background tasks
    if (_lastPlanGenerationAttempt != null) {
       final difference = DateTime.now().difference(_lastPlanGenerationAttempt!);
       if (difference.inMinutes < 15) {
         print("AI Cooldown: Skipping daily plan generation (Last attempt: ${difference.inMinutes} mins ago).");
         return;
       }
    }
    
    if (_userDataProvider == null) return;
    if (_userDataProvider!.isLoading) {
       await Future.delayed(const Duration(seconds: 1));
       if (_userDataProvider!.isLoading) return;
    }

    _isGeneratingPlan = true;
    notifyListeners();

    try {
      if (_chatSession == null) {
        final success = await initializeGemini();
        if (!success) {
          _isGeneratingPlan = false;
          notifyListeners();
          return;
        }
      }
      
      _lastPlanGenerationAttempt = DateTime.now();

      final trendContext = await _calculateAnxietyTrend();
      final journalContext = await _getRecentJournalEntries();
      final timeContext = _getTimeContext();
      
      final prompt = """
      GÖREV: Kullanıcı için 3 maddelik kişiselleştirilmiş bir "Günlük İyi Hissetme Planı" hazırla.
      
      BAĞLAM:
      $timeContext
      $trendContext
      $journalContext
      
      KURALLAR:
      1. Sadece aşağıdaki JSON formatında yanıt ver. Başka hiçbir metin, markdown veya açıklama ekleme. Saf JSON array döndür.
      2. 3 adet aksiyon maddesi olsun.
      3. "actionType" şunlardan biri OLMALI: 'BREATHING', 'MEDITATION', 'JOURNAL', 'MUSIC', 'GOAL', 'NONE'.
      4. "target" alanı, eğer actionType bir egzersiz veya meditasyon ise tam adını içermeli.
      5. "description" kısa, samimi ve motive edici olsun.
      
      İSTENEN JSON FORMATI:
      [
        {
          "title": "Sabah Nefesi",
          "description": "Güne zinde başlamak için kısa bir egzersiz.",
          "actionType": "BREATHING",
          "target": "Kutu Nefesi"
        },
        {
          "title": "Duygularını Dök",
          "description": "Dünkü olay seni hala üzüyorsa, yazarak rahatla.",
          "actionType": "JOURNAL",
          "target": null
        }
      ]
      """;

      final response = await _chatSession!.sendMessage(Content.text(prompt));
      final responseText = response.text;

      if (responseText != null) {
        String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        try {
          final List<dynamic> decoded = jsonDecode(cleanJson);
          _dailyPlan = decoded.map((item) => item as Map<String, dynamic>).toList();
        } catch (e) {
          print("JSON parse hatası: $e");
          _dailyPlan = [
            {
              "title": "Nefes Egzersizi",
              "description": "Gününe sakin bir başlangıç yap.",
              "actionType": "BREATHING",
              "target": "Kutu Nefesi"
            },
            {
              "title": "Günlük Tut",
              "description": "Aklından geçenleri serbestçe yaz.",
              "actionType": "JOURNAL",
              "target": null
            }
          ];
        }
      }
    } catch (e) {
      print("Günlük plan oluşturma hatası: $e");
      // Check for Quota Exceeded error
      if (e.toString().contains("Quota exceeded") || e.toString().contains("429")) {
        print("CRITICAL: Gemini API Quota Exceeded. Pausing background tasks.");
        _isRateLimited = true;
      }
    } finally {
      _isGeneratingPlan = false;
      notifyListeners();
    }
  }

  void refreshDailyPlan() {
    // Allow manual refresh to bypass 15 min cooldown but still respect hard quota limit
    if (_isRateLimited) {
       print("Cannot refresh: Quota exceeded limit active.");
       return;
    }
    _dailyPlan = [];
    _lastPlanGenerationAttempt = null; // Reset time check for manual refresh
    generateDailyPlan();
  }
}