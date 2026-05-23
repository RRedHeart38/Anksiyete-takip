import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_remix/flutter_remix.dart';

import '../providers/user_data_provider.dart';
import '../providers/auth_provider.dart';
import '../models/onboarding_model.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<String, dynamic> _answers = {};

  final List<Map<String, dynamic>> _pages = [
    {
      'type': 'welcome',
      'title': 'Hoş geldin',
      'subtitle': 'Birlikte başlayalım. Kısa sorularla seni daha iyi tanıyalım.',
    },
    {
      'type': 'welcomeNote',
      'title': 'Başlamadan önce',
      'subtitle': 'Birkaç adımda neye odaklanmak istediğini anlayacağız.',
    },
    {
      'q': 'Öncelikle neye odaklanalım?',
      'options': ['Olumsuz düşüncelerden kurtulmak', 'Ertelemeyi yenmek', 'Stres ve kaygımı azaltmak', 'Neden iyi hissetmediğimi anlamak'],
      'key': 'q1'
    },
    {
      'q': 'İlerleme isteğini harekete geçiren ne?',
      'options': ['Hedefime ulaşmak', 'Daha iyi hissetmek', 'Sağlığımı iyileştirmek', 'İstediğim insan olabilmek'],
      'key': 'q2'
    },
    {
      'q': 'Bu cümle sana tanıdık geliyor mu?\n"Odaklanmakta ve işleri bitirmekte zorlanıyorum"',
      'yesNo': true,
      'image': 'assets/images/onboarding/option_1.png',
      'key': 'q3'
    },
    {
      'q': 'Genellikle yorgunum ve üretken şeyler yapmak için motivasyonum yok',
      'yesNo': true,
      'image': 'assets/images/onboarding/option_2.png',
      'key': 'q4'
    },
    {
      'q': 'Çoğu gün yoğunum ve ayak uydurmak zor geliyor',
      'yesNo': true,
      'image': 'assets/images/onboarding/option_3.png',
      'key': 'q5'
    },
    {
      'q': 'Sağlıklı ve sürdürülebilir rutinler oluşturmak ister misin?',
      'yesNo': true,
      'image': 'assets/images/onboarding/option_4.png',
      'key': 'q6'
    },
    {
      'q': 'Alışkanlık kazanmak için çabalamak ister misin?',
      'yesNo': true,
      'image': 'assets/images/onboarding/option_5.png',
      'key': 'q7'
    },
    {
      'q': 'Kaç yaşındasın?',
      'options': ['18-29', '30-39', '40-49', '50+'],
      'key': 'q8'
    },
    {
      'q': 'Cinsiyetin nedir?',
      'options': ['Kadın', 'Erkek', 'Diğer', 'Belirtmek istemiyorum'],
      'key': 'q9'
    },
    {
      'q': 'Kaç saat uyuyorsun?',
      'options': ['5 saat veya daha az', 'Yaklaşık 6 saat', 'Yaklaşık 7 saat', '8 saat veya daha fazlası'],
      'key': 'q10'
    },
    {
      'q': 'Yatakdan kalkmakta zorlanıyor musun?',
      'options': ['Neredeyse her gün', 'Sık sık', 'Bazen', 'Hiç'],
      'key': 'q11'
    },
    {
      'q': 'Gün içinde ne kadar enerjiksin?',
      'options': ['Bitik', 'Yorgun', 'Normal', 'Enerjik'],
      'key': 'q12'
    },
    {
      'type': 'infoCard',
      'image': 'assets/images/onboarding/option_6.png',
      'title': 'Uyku rutini',
      'subtitle': 'Kullanıcıların %57 sinden fazlası yeterince kaliteli uyumuyor. Sakin bir uyku rutini oluşturman için yanındayız.',
      'button': 'Devam et',
    },
    {
      'q': 'Stres seviyen nasıl?',
      'options': ['Kriz halindeyim', 'Mücadele ediyorum', 'Hayatta kalmaya çalışıyorum', 'İyiye gidiyorum'],
      'key': 'q13'
    },
    {
      'q': 'Yeterince desteklendiğini hissediyor musun?',
      'options': ['Neredeyse hiç (yalnız hissediyorum)', 'Biraz (insanların yanımda olmayacağından korkuyorum)', 'Fazlasıyla (hayatımdaki insanlara güvenirim)'],
      'key': 'q14'
    },
    {
      'type': 'infoCard',
      'image': 'assets/images/onboarding/option_5.png',
      'title': 'Senin için buradayız',
      'subtitle': 'Her şeyi tek başına çözmek zorunda değilsin. Bunu adım adım birlikte yapacağız.',
      'button': 'Devam et',
    },
    {
      'q': 'Vaktini verimli kullanabiliyor musun?',
      'options': ['Asla (büyük bir değişim olsun istiyorum)', 'Biraz (kendimi geliştirmek istiyorum)', 'Fazlasıyla (çok aktif ve üretkenim)'],
      'key': 'q15'
    },
    {
      'type': 'quoteCard',
      'title': 'Her gün %1 gelişim',
      'subtitle': 'James Clear, Atomik Alışkanlıklar kitabında küçük adımların sürekli büyüme sağladığını söylüyor. Her gün %1 gelişerek, yıl sonunda 37 kat daha iyi olabilirsin.',
    },
    {
      'type': 'infoCard',
      'image': 'assets/images/onboarding/option_4.png',
      'title': 'Alışkanlıklar döngüsü',
      'subtitle': 'Alışkanlıklar bir döngüyü izler: ipucu, arzu, tepki, ödül. İpuçlarını fark et, arzularınla harekete geç ve davranışlarını ödüllendirerek günlük yaşamında kalıcı değişiklikler yap.',
      'button': 'Devam et',
    },
    {
      'q': 'Odaklanmakta zorlanıyor musun?',
      'options': ['Sık sık', 'Bazen', 'Hiçbir zaman'],
      'key': 'q16'
    },
    {
      'q': 'Sık sık erteleme yapar mısın?',
      'options': ['Çok sık (bunu değiştirmek istiyorum)', 'Bazen (zaman zaman ertelerim)', 'Çok sık değil (genelde programıma uyarım)'],
      'key': 'q17'
    },
    {
      'type': 'summaryCard',
      'title': 'İşte sana özel ilk alışkanlığın',
      'subtitle': 'Derin bir nefes al (bugün şimdi).',
      'button': 'Hadi başlayalım',
    },
    {
      'type': 'infoCard',
      'image': 'assets/images/onboarding/option_3.png',
      'title': 'Daha iyi hissediyor musun?',
      'subtitle': 'Alışkanlığın listene eklendi. Alışkanlıklarını istediğin zaman kişiselleştirebilirsin.',
      'button': 'Devam et',
    },
    {
      'type': 'infoCard',
      'image': 'assets/images/onboarding/option_2.png',
      'title': 'Harika!',
      'subtitle': 'Yeni bir alışkanlık edinmek sadece 21 gün sürer ve bugünün mükemmel bir başlangıç olduğuna eminiz. Arayı soğutmayalım, sana ilham verecek yeni geliştirmeler yakında.',
      'button': 'Devam et',
    },
    {
      'type': 'infoCard',
      'image': 'assets/images/onboarding/option_1.png',
      'title': 'Yolculuk başladı',
      'subtitle': 'Daha iyi bir sen olma yolculuğun çoktan başladı. Şimdi kalan yolda sana her seferinde küçük bir adımla eşlik edelim.',
      'button': 'Devam et',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Ensure anonymous sign-in so we have a uid to write onboarding data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.signInAnonymously();
    });
  }

  void _onAnswer(String key, dynamic value) async {
    setState(() {
      _answers[key] = value;
    });

    // incremental save every 3 answers
    if ((_answers.length % 3) == 0) {
      await context.read<UserDataProvider>().saveOnboardingResponses(_answers);
    }
  }

  Future<void> _finishOnboarding() async {
    await context.read<UserDataProvider>().saveOnboardingResponses(_answers, completed: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Mascot and progress
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Center(
                      child: Image.asset('assets/images/onboarding/onboarding_mascot.png', width: 160, height: 120, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _pages.length,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  if (page['type'] == 'welcome') {
                    return _buildWelcome(page);
                  }
                  if (page['type'] == 'welcomeNote') return _buildWelcomeNote(page);
                  if (page['type'] == 'infoCard') return _buildInfoCard(page);
                  if (page['type'] == 'quoteCard') return _buildQuoteCard(page);
                  if (page['type'] == 'summaryCard') return _buildSummaryCard(page);
                  if (page.containsKey('info')) return _buildInfo(page['info']);
                  if (page.containsKey('yesNo') && page['yesNo'] == true) return _buildYesNo(page);
                  if (page.containsKey('options')) return _buildOptions(page);
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _currentIndex > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                    child: const Text('Geri'),
                  ),
                  FilledButton(
                    onPressed: _currentIndex == _pages.length - 1 ? _finishOnboarding : () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: Text(_currentIndex == _pages.length - 1 ? 'Başla!' : (_isInfoPage(_pages[_currentIndex]) ? 'Devam et' : 'İleri')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isInfoPage(Map<String, dynamic> page) {
    return page['type'] == 'welcome' || page['type'] == 'welcomeNote' || page['type'] == 'infoCard' || page['type'] == 'quoteCard' || page['type'] == 'summaryCard';
  }

  Widget _buildWelcome(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Image.asset(
              'assets/images/onboarding/onboarding_mascot.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            page['title'] ?? 'Hoş geldin',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            page['subtitle'] ?? 'Birlikte başlayalım.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeNote(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FlutterRemix.mental_health_line, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(page['title'] ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(page['subtitle'] ?? '', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (page['image'] != null) Image.asset(page['image'], height: 140),
          const SizedBox(height: 18),
          Text(page['title'] ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(page['subtitle'] ?? '', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton(onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut), child: Text(page['button'] ?? 'Devam et')),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(page['title'] ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(page['subtitle'] ?? '', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(page['title'] ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(page['subtitle'] ?? '', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: _finishOnboarding, child: Text(page['button'] ?? 'Hadi başlayalım')),
        ],
      ),
    );
  }

  Widget _buildInfo(String text) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(child: Text(text, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center)),
    );
  }

  Widget _buildYesNo(Map<String, dynamic> page) {
    final key = page['key'] as String? ?? 'q';
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (page['image'] != null) Image.asset(page['image'], height: 120),
          const SizedBox(height: 12),
          Text(page['q'], style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ToggleButtons(
            isSelected: [(_answers[key] == false), (_answers[key] == true)],
            onPressed: (i) => _onAnswer(key, i == 1),
            children: const [Padding(padding: EdgeInsets.all(12), child: Text('Hayır')), Padding(padding: EdgeInsets.all(12), child: Text('Evet'))],
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(Map<String, dynamic> page) {
    final key = page['key'] as String? ?? 'q';
    final List<String> options = List<String>.from(page['options']);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(page['q'], style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final selected = _answers[key] == i;
                return GestureDetector(
                  onTap: () => _onAnswer(key, i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(options[i], style: TextStyle(fontSize: 16, color: selected ? Colors.white : null))),
                        if (selected) const Icon(Icons.check_circle, color: Colors.white)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}