// home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ----------------------------------------------------
  // DEĞİŞKENLER
  // ----------------------------------------------------
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF6366f1);

  double _anxietyLevel = 5;
  final List<String> _emojis = ['😊', '🙂', '😐', '😕', '😔'];
  final TextEditingController _triggerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double _weeklyAverage = 0.0;
  bool _isLoading = true;
  bool _isChartLoading = true;

  // Yapay zeka analizi sonuçlarını saklamak için bir liste
  List<Map<String, dynamic>> _chatMessages = [];
  bool _isAnalyzing = false;
  final TextEditingController _chatController = TextEditingController();
  
  // Yeni eklenenler
  GenerativeModel? _model;
  ChatSession? _chatSession;
  List<FlSpot> _anxietyChartData = [];

  // ----------------------------------------------------
  // METOTLAR
  // ----------------------------------------------------

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _fetchWeeklyAverage();
    _fetchChatMessages();
    _fetchAnxietyDataForChart();
  }

  void _initializeGemini() {
    const apiKey = 'AIzaSyCfIXCKwiCzjHmdvNA6ylIbsl8fHPtheuE';
    if (apiKey.isEmpty) {
      print('HATA: API Anahtarı girilmedi.');
      return;
    }
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    _chatSession = _model?.startChat();
  }
  
  @override
  void dispose() {
    _triggerController.dispose();
    _notesController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeeklyAverage() async {
    setState(() {
      _isLoading = true;
    });
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Hata: Kullanıcı oturum açmamış.');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_entries')
          .where('tarih', isGreaterThanOrEqualTo: oneWeekAgo.toIso8601String())
          .get();
      if (snapshot.docs.isNotEmpty) {
        double total = 0;
        for (var doc in snapshot.docs) {
          total += doc['kaygiSeviyesi'];
        }
        setState(() {
          _weeklyAverage = total / snapshot.docs.length;
        });
      } else {
        setState(() {
          _weeklyAverage = 0.0;
        });
      }
    } catch (e) {
      print('Haftalık ortalama çekilirken hata oluştu: $e');
      setState(() {
        _weeklyAverage = 0.0;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAnxietyDataForChart() async {
    setState(() {
      _isChartLoading = true;
    });
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isChartLoading = false;
      });
      return;
    }

    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_entries')
          .where('tarih', isGreaterThanOrEqualTo: oneWeekAgo.toIso8601String())
          .orderBy('tarih', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _anxietyChartData = [];
        });
        return;
      }
      
      final Map<int, List<int>> dailyData = {};
      final nowUtc = now.toUtc();

      for (var doc in snapshot.docs) {
        final tarih = DateTime.parse(doc['tarih']).toUtc();
        final daysAgo = nowUtc.difference(tarih).inDays;
        final dayIndex = 7 - daysAgo;

        if (dayIndex > 0 && dayIndex <= 7) {
          if (!dailyData.containsKey(dayIndex)) {
            dailyData[dayIndex] = [];
          }
          dailyData[dayIndex]!.add(doc['kaygiSeviyesi']);
        }
      }

      final List<FlSpot> spots = [];
      for (int i = 1; i <= 7; i++) {
        if (dailyData.containsKey(i)) {
          final average = dailyData[i]!.reduce((a, b) => a + b) / dailyData[i]!.length;
          spots.add(FlSpot(i.toDouble(), average));
        } else {
          spots.add(FlSpot(i.toDouble(), 0));
        }
      }
      
      setState(() {
        _anxietyChartData = spots;
      });

    } catch (e) {
      print('Grafik verileri çekilirken hata oluştu: $e');
      setState(() {
        _anxietyChartData = [];
      });
    } finally {
      setState(() {
        _isChartLoading = false;
      });
    }
  }

  Future<void> _fetchChatMessages() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_analyses')
          .orderBy('tarih', descending: true)
          .get();
      setState(() {
        _chatMessages = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Sohbet mesajları çekilirken hata oluştu: $e');
    }
  }

  Future<void> _saveAnxietyEntry() async {
    print('Kaydetme işlemi başlatılıyor...');
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Hata: Kullanıcı oturum açmamış.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veri kaydetmek için lütfen önce oturum açın.'),
          ),
        );
      }
      return;
    }
    final entry = {
      'kaygiSeviyesi': _anxietyLevel.round(),
      'tetikleyici': _triggerController.text,
      'notlar': _notesController.text,
      'tarih': DateTime.now().toIso8601String(),
    };
    try {
      print('Firestore\'a veri yazılıyor: $entry');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('anxiety_entries')
          .add(entry);
      print('Veri başarıyla kaydedildi!');
      if (mounted) {
        setState(() {
          _anxietyLevel = 5;
          _triggerController.clear();
          _notesController.clear();
          _selectedIndex = 3; // Sohbet ekranına otomatik geçiş
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş başarıyla kaydedildi!'),
            duration: Duration(seconds: 2),
          ),
        );
        _fetchWeeklyAverage();
        _fetchAnxietyDataForChart();
        _analyzeWithAI(entry);
      }
    } catch (e) {
      print('HATA: Giriş kaydedilirken bir hata oluştu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş kaydedilirken bir hata oluştu: $e'),
          ),
        );
      }
    }
  }

  Future<void> _analyzeWithAI(Map<String, dynamic> data) async {
    if (_chatSession == null) {
      _initializeGemini();
    }
    setState(() {
      _isAnalyzing = true;
    });

    final prompt = 'Aşağıdaki verileri incele. Anksiyete seviyesi, tetikleyici ve notları dikkate alarak kullanıcıya yapıcı ve olumlu bir geri bildirimde bulun. Kullanıcıya bir aktivite veya öneri sunabilirsin.\n\n'
        'Veri: Kaygı Seviyesi: ${data['kaygiSeviyesi']}, Tetikleyici: ${data['tetikleyici']}, Notlar: ${data['notlar']}';
    
    try {
      final response = await _chatSession!.sendMessage(Content.text(prompt));
      if (response.text != null) {
        final String aiResponse = response.text!;
        print('Yapay zeka analizi: $aiResponse');
        _saveAIAnalysis(data, aiResponse);
      } else {
        print('Yapay zeka analizinden boş yanıt döndü.');
      }
    } catch (e) {
      print('Yapay zeka analizinde hata oluştu: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }
  
  Future<void> _sendChatMessage() async {
    if (_chatController.text.isEmpty) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sohbete devam etmek için lütfen oturum açın.'),
        ),
      );
      return;
    }
    
    final userMessage = _chatController.text;
    _chatController.clear();
    setState(() {
      _chatMessages.insert(0, {
        'user_data': {'notlar': userMessage},
        'ai_response': null,
        'tarih': DateTime.now().toIso8601String(),
      });
    });

    try {
      final response = await _chatSession!.sendMessage(Content.text(userMessage));
      if (response.text != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ai_analyses')
            .add({
          'user_data': {'notlar': userMessage},
          'ai_response': response.text!,
          'tarih': DateTime.now().toIso8601String(),
        });
        _fetchChatMessages();
      }
    } catch (e) {
      print('Sohbet mesajı gönderilirken hata oluştu: $e');
    }
  }

  Future<void> _saveAIAnalysis(Map<String, dynamic> userData, String aiResponse) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_analyses')
          .add({
        'user_data': userData,
        'ai_response': aiResponse,
        'tarih': DateTime.now().toIso8601String(),
      });
      print('Yapay zeka analizi Firestore\'a kaydedildi!');
      _fetchChatMessages();
    } catch (e) {
      print('Yapay zeka analizi kaydedilirken hata oluştu: $e');
    }
  }
  
  void _showEmergencyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Acil Destek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Destek Hatları', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: const Icon(FlutterRemix.phone_line, color: Colors.red),
                  ),
                  title: const Text('Acil Yardım Hattı'),
                  subtitle: const Text('112'),
                  trailing: const Icon(FlutterRemix.phone_fill, color: Colors.red),
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                const Text('Hızlı Rahatlama Teknikleri', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('4-7-8 Nefes Tekniği'),
                  subtitle: const Text('4 saniye al, 7 tut, 8 ver.'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // UI oluşturma metotları
  Widget _getBodyWidget() {
    switch (_selectedIndex) {
      case 0:
        return _buildTakipContent();
      case 1:
        return _buildNefesContent();
      case 2:
        return _buildOnerilerContent();
      case 3:
        return _buildChatContent();
      default:
        return _buildTakipContent();
    }
  }

  Widget _buildNefesContent() {
    return const Center(
      child: Text('Nefes Egzersizleri Ekranı'),
    );
  }

  Widget _buildOnerilerContent() {
    return const Center(
      child: Text('Öneriler Ekranı'),
    );
  }

  Widget _buildChatContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16.0),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[index];
              final userData = message['user_data'];
              final aiResponse = message['ai_response'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kullanıcı Mesajı
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (userData.containsKey('kaygiSeviyesi'))
                            Text('Kaygı Seviyesi: ${userData['kaygiSeviyesi']}'),
                          if (userData.containsKey('tetikleyici'))
                            Text('Tetikleyici: ${userData['tetikleyici']}'),
                          if (userData['notlar'] != null && userData['notlar'].isNotEmpty)
                            Text('Notlar: ${userData['notlar']}'),
                        ],
                      ),
                    ),
                  ),
                  // Yapay Zeka Mesajı
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(aiResponse),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _isAnalyzing
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 8),
                    Text('Analiz yapılıyor...'),
                  ],
                ),
              )
            : Container(),
        // Sohbet için metin giriş alanı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Mesaj yazın...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendChatMessage,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTakipContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(FlutterRemix.lightbulb_line, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Günün Tavsiyesi', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                          const SizedBox(height: 4),
                          const Text(
                            'Bugün 10 dakika doğada yürüyüş yapmayı deneyin. Doğa ile bağlantı kurmak anksiyeteyi azaltmaya yardımcı olur.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_right_alt, size: 16),
                    label: const Text('Daha fazla aktivite', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoWidget(
                  title: 'Haftalık Ortalama',
                  value: _isLoading ? '...' : _weeklyAverage.toStringAsFixed(1),
                  subtitle: 'Son 7 gün',
                  icon: FlutterRemix.line_chart_line,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoWidget(
                  title: 'Nefes Egzersizi',
                  value: '12',
                  subtitle: 'Bu hafta tamamlandı',
                  icon: FlutterRemix.lungs_line,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () {}, icon: const Icon(FlutterRemix.arrow_left_s_line)),
                const Text('2 Nisan 2025, Çarşamba', style: TextStyle(fontWeight: FontWeight.w500)),
                IconButton(onPressed: () {}, icon: const Icon(FlutterRemix.arrow_right_s_line)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAnxietyLevelCard(),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text('Haftalık', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Text('Aylık', style: TextStyle(color: Colors.black54)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            title: 'Haftalık Kaygı Seviyesi',
            chartWidget: _isChartLoading ? const Center(child: CircularProgressIndicator()) : _buildLineChart(_anxietyChartData),
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            title: 'Ruh Hali Dağılımı',
            chartWidget: Container(height: 200, color: Colors.grey[200]),
          ),
          const SizedBox(height: 16),
          _buildReportCard(),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots) {
    final List<Color> gradientColors = [
      primaryColor.withOpacity(0.5),
      primaryColor.withOpacity(0),
    ];
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 10,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xff37434d),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 1:
                      return const Text('Pzt', style: TextStyle(fontSize: 12));
                    case 2:
                      return const Text('Sal', style: TextStyle(fontSize: 12));
                    case 3:
                      return const Text('Çar', style: TextStyle(fontSize: 12));
                    case 4:
                      return const Text('Per', style: TextStyle(fontSize: 12));
                    case 5:
                      return const Text('Cum', style: TextStyle(fontSize: 12));
                    case 6:
                      return const Text('Cmt', style: TextStyle(fontSize: 12));
                    case 7:
                      return const Text('Pzr', style: TextStyle(fontSize: 12));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots, // Burası dinamik olarak güncelleniyor
              isCurved: true,
              gradient: LinearGradient(colors: gradientColors),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnxietyLevelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kaygı Seviyeni Belirle',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _emojis.asMap().entries.map((entry) {
              int index = entry.key;
              String emoji = entry.value;
              bool isSelected = (_anxietyLevel.round() >= index * 2 + 1 && _anxietyLevel.round() <= (index + 1) * 2);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _anxietyLevel = (index * 2 + 1).toDouble();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withAlpha(51) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _anxietyLevel,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: primaryColor,
            inactiveColor: primaryColor.withAlpha(26),
            onChanged: (double value) {
              setState(() {
                _anxietyLevel = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _anxietyLevel.round().toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bugün seni en çok ne tetikledi?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _triggerController,
            decoration: InputDecoration(
              hintText: 'Örn: Toplantı, kalabalık ortam',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Notlar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Eklemek istediğiniz notları yazın...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAnxietyEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Kaydet', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoWidget({required String title, required String value, required String subtitle, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Icon(icon, color: primaryColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chartWidget}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          chartWidget,
        ],
      ),
    );
  }

  Widget _buildReportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Raporlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(FlutterRemix.file_chart_line),
                label: const Text('Rapor Oluştur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // BUILD METODU
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nefes', style: TextStyle(fontFamily: 'Pacifico', fontSize: 24, color: Color(0xFF6366f1))),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(FlutterRemix.notification_3_line),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(FlutterRemix.settings_3_line),
          ),
        ],
      ),
      body: Stack(
        children: [
          _getBodyWidget(),
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton(
              onPressed: () {
                _showEmergencyModal(context);
              },
              backgroundColor: Colors.red[500],
              child: const Icon(FlutterRemix.first_aid_kit_line, color: Colors.white),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(FlutterRemix.pulse_line),
            label: 'Takip',
          ),
          BottomNavigationBarItem(
            icon: Icon(FlutterRemix.lungs_line),
            label: 'Nefes',
          ),
          BottomNavigationBarItem(
            icon: Icon(FlutterRemix.lightbulb_line),
            label: 'Öneriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(FlutterRemix.chat_2_line),
            label: 'Sohbet',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[400],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}