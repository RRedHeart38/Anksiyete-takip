import 'package:flutter/material.dart';

class Meditation {
  final String id;
  final String title;
  final String description;
  final String detailedDescription;
  final List<String> benefits;
  final List<String> steps; // Custom steps for each meditation

  final int duration;
  final String type;
  final String icon;
  final String? audioUrl;

  Meditation({
    required this.id,
    required this.title,
    required this.description,
    required this.detailedDescription,
    required this.benefits,
    required this.steps, 
    required this.duration,
    required this.type,
    required this.icon,
    this.audioUrl,
  });

  Color get color {
    switch (type) {
      case 'meditation':
        return const Color(0xFF9C27B0); // Purple
      case 'mindfulness':
        return const Color(0xFF009688); // Teal
      case 'body_scan':
        return const Color(0xFFFF9800); // Orange
      case 'visualization':
        return const Color(0xFF3F51B5); // Indigo
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  static List<Meditation> getMeditations() {
    return [
      // Kısa Meditasyonlar
      Meditation(
        id: 'med_1',
        title: '5 Dakikalık Sakinleşme',
        description: 'Hızlı bir şekilde sakinleşmek için kısa bir meditasyon.',
        detailedDescription: 'Gün içinde ani stres veya bunalma hissettiğinde kullanabileceğin hızlı bir sıfırlama aracı. Sadece 5 dakika içinde nabzını düşür ve zihnini berraklaştır.',
        benefits: ['Stresi hızlıca azaltır', 'Odaklanmayı artırır', 'Nabzı dengeler'],
        steps: [
          'Rahat bir pozisyon al ve gözlerini kapat.',
          'Derin bir nefes al, burnundan çek ve ağzından ver.',
          'Omuzlarını serbest bırak, çeneni gevşet.',
          'Sadece nefesinin giriş ve çıkışına odaklan.',
          'Düşünceler gelirse, onları bulutlar gibi izle ve geçip gitmelerine izin ver.',
          'Vücudunun sandalyeye veya yere temasını hisset.',
          'Son bir derin nefes al ve hazır hissettiğinde gözlerini aç.',
        ],
        duration: 5,
        type: 'meditation',
        icon: 'meditation',
      ),
      Meditation(
        id: 'med_2',
        title: '10 Dakikalık Derin Rahatlama',
        description: 'Stres ve gerginliği azaltmak için derin bir rahatlama meditasyonu.',
        detailedDescription: 'Yoğun bir günün ardından veya önemli bir olaydan önce gevşemek için ideal. Kaslarındaki gerginliği fark et ve onları tek tek serbest bırak.',
        benefits: ['Kas gerginliğini azaltır', 'Kaygıyı hafifletir', 'Zihinsel yorgunluğu alır'],
        steps: [
          'Sessiz bir yer bul ve rahatça otur veya uzan.',
          'Gözlerini kapat ve dış dünyayı bir süreliğine dışarıda bırak.',
          'Ayaklarından başlayarak tüm vücudundaki kasları sık ve gevşet.',
          'Derin nefesler alarak gevşemeyi tüm vücuduna yay.',
          'Zihnindeki karmaşayı bir nehir gibi akıp giderken hayal et.',
          'Kendi içindeki sessizliği ve huzuru dinle.',
          'Vücudunun ağırlığını tamamen yere bırak.',
          'Yavaşça parmaklarını oynat ve kendine gel.',
        ],
        duration: 10,
        type: 'meditation',
        icon: 'meditation',
      ),
      Meditation(
        id: 'med_3',
        title: '15 Dakikalık Farkındalık',
        description: 'Zihni sakinleştirmek ve farkındalığı artırmak için uzun meditasyon.',
        detailedDescription: 'Bu pratik, yargılamadan "olanı olduğu gibi" gözlemleme becerini geliştirir. Düzenli yapıldığında duygusal dayanıklılığı artırır.',
        benefits: ['Duygusal zekayı geliştirir', 'Tepkisel olmayı azaltır', 'İç huzuru artırır'],
        steps: [
          'Omurgan dik, rahat bir oturuşa geç.',
          'Dikkatini nazikçe şimdiki ana getir.',
          'Etrafındaki sesleri fark et, ama onlara takılıp kalma.',
          'Dikkatini nefesine, burun deliklerinden giren havaya getir.',
          'Zihnin başka yerlere gittiğinde, bunu fark et ve tekrar nefesine dön.',
          'Bu dönüş anı, farkındalığın güçlendiği andır.',
          'Duygularını bir misafir gibi karşıla, yargılama.',
          'Kendine şefkatle yaklaşarak pratiği tamamla.',
        ],
        duration: 15,
        type: 'meditation',
        icon: 'meditation',
      ),
      
      // Mindfulness Egzersizleri
      Meditation(
        id: 'mind_1',
        title: 'Nefes Farkındalığı',
        description: 'Nefesine odaklanarak şu anı yaşamayı öğren.',
        detailedDescription: 'Nefes, her zaman yanımızda olan bir çapadır. Bu egzersiz, zihnin geçmişe veya geleceğe savrulduğunda seni "şimdi"ye döndürür.',
        benefits: ['Anksiyeteyi anında yatıştırır', 'Konsantrasyonu güçlendirir', 'Uykuya geçişi kolaylaştırır'],
        steps: [
          'Rahatça otur ve gözlerini kapat.',
          'Nefesinin doğal ritmini izlemeye başla. Değiştirmeye çalışma.',
          'Nefes alırken "alıyorum", verirken "veriyorum" diye içinden geçirebilirsin.',
          'Nefesin vücudunda nerede en belirgin? Göğsünde mi, karnında mı?',
          'Her nefes verişte vücudunun biraz daha gevşediğini hisset.',
          'Bu sakinliği günün geri kalanına taşı.',
        ],
        duration: 5,
        type: 'mindfulness',
        icon: 'mindfulness',
      ),
      Meditation(
        id: 'mind_2',
        title: 'Duyusal Farkındalık',
        description: 'Beş duyunu kullanarak şu anı tam olarak deneyimle.',
        detailedDescription: 'Zihnimiz sürekli düşüncelerle doludur. Duyularımıza odaklanmak, düşünce akışını durdurup gerçekliği hissetmenin en etkili yoludur.',
        benefits: ['Zihinsel gevezeliği durdurur', 'Yaşamdan alınan tadı artırır', 'Gerçeklik algısını tazeler'],
        steps: [
          'Etrafına bak ve 5 tane renk veya nesne fark et.',
          'Kulağını aç ve en uzak veya en yakın 4 sesi duy.',
          'Teninde hissettiğin 3 farklı dokuyu veya sıcaklığı fark et.',
          'Burnuna gelen 2 kokuyu ayırt etmeye çalış.',
          'Ağzında kalan tada veya dilinin konumuna odaklan (1 his).',
          'Tüm duyularınla şu anın içinde kal.',
        ],
        duration: 10,
        type: 'mindfulness',
        icon: 'mindfulness',
      ),
      Meditation(
        id: 'mind_3',
        title: 'Yürüyüş Meditasyonu',
        description: 'Yürürken farkındalığını artır ve zihnini sakinleştir.',
        detailedDescription: 'Meditasyon sacece oturarak yapılmaz. Hareket halindeyken de zihnini eğitebilirsin. Özellikle huzursuz hissettiğinde çok etkilidir.',
        benefits: ['Enerjiyi dengeler', 'Beden farkındalığını artırır', 'Doğayla bağ kurmayı sağlar'],
        steps: [
          'Yavaş bir tempoda yürümeye başla.',
          'Ayak tabanlarının yere temasını hisset. Topuk, taban, parmak uçları...',
          'Bacaklarındaki kasların hareketini gözlemle.',
          'Rüzgarın veya havanın yüzündeki hissini fark et.',
          'Etrafındaki manzarayı yargılamadan izle.',
          'Hareketin ve nefesin uyumunu yakala.',
        ],
        duration: 10,
        type: 'mindfulness',
        icon: 'walking',
      ),
      
      // Beden Taraması
      Meditation(
        id: 'body_1',
        title: 'Kısa Beden Taraması',
        description: 'Vücudunun her bölgesine dikkatini vererek rahatla.',
        detailedDescription: 'Vücudumuz stresi depolar. Beden taraması, farkında olmadan sıktığımız kasları keşfetmemizi ve gevşetmemizi sağlar.',
        benefits: ['Kronik ağrı algısını yönetmeye yardımcı olur', 'Uyku kalitesini artırır', 'Beden-zihin bağını güçlendirir'],
        steps: [
          'Sırtüstü uzan veya rahatça arkana yaslan.',
          'Dikkatini ayak parmaklarına getir. Orada ne hissediyorsun?',
          'Yavaşça yukarı doğru çık: ayak bilekleri, baldırlar, dizler...',
          'Kalça, karın ve bel bölgeni fark et.',
          'Omuzlarını kulaklarından uzaklaştır, rahatlat.',
          'Tüm vücudunu bir bütün olarak hisset.',
        ],
        duration: 10,
        type: 'body_scan',
        icon: 'body_scan',
      ),
      Meditation(
        id: 'body_2',
        title: 'Derin Beden Taraması',
        description: 'Detaylı bir beden taraması ile gerginliği serbest bırak.',
        detailedDescription: 'Tüm vücudu kucaklayan şefkatli bir tarama. Kendine ayırdığın bu zaman, bedenine olan minnettarlığını gösterir.',
        benefits: ['Derin dinlenme sağlar', 'Psikosomatik ağrıları hafifletir', 'Öz-şefkati artırır'],
        steps: [
          'Güvenli ve sıcak bir yerde uzan.',
          'Sol ayak baş parmağından başlayarak milim milim yukarı çık.',
          'Sıcaklık, karıncalanma, ağırlık veya hafiflik... Ne varsa onu hisset.',
          'Her nefes verişte taradığın bölgenin "eridiğini" ve gevşediğini hayal et.',
          'Karnına, göğsüne ve boğazına özel ilgi göster.',
          'Yüz kaslarını, göz çevreni ve alnını tamamen serbest bırak.',
          'Vücudunu yerçekimine teslim et.',
        ],
        duration: 20,
        type: 'body_scan',
        icon: 'body_scan',
      ),
      
      // Görselleştirme
      Meditation(
        id: 'vis_1',
        title: 'Güvenli Yer Görselleştirmesi',
        description: 'Kendini güvende hissettiğin bir yeri hayal et ve orada rahatla.',
        detailedDescription: 'Zihnimiz hayal ile gerçeği duygusal düzeyde ayırt edemez. Güvenli bir yer hayal etmek, vücuduna "güvendesin" sinyali gönderir.',
        benefits: ['Güven duygusunu tazeler', 'Panik anlarında sığınak olur', 'Pozitif duyguları artırır'],
        steps: [
          'Gözlerini kapat ve senin için "huzur" anlamına gelen bir yer hayal et.',
          'Bu bir sahil, orman, çocukluk odan veya hayali bir yer olabilir.',
          'Oradaki renkleri gör. Işık nasıl?',
          'Sesleri duy. Dalgalar, kuşlar veya sessizlik...',
          'Kokuları ve ısıyı hisset.',
          'Orada olmanın verdiği güven ve huzuru kalbine doldur.',
          'İstediğin zaman buraya dönebileceğini bilerek pratiği bitir.',
        ],
        duration: 10,
        type: 'visualization',
        icon: 'visualization',
      ),
      Meditation(
        id: 'vis_2',
        title: 'Doğa Görselleştirmesi',
        description: 'Sakin bir doğa manzarasını hayal ederek huzur bul.',
        detailedDescription: 'Doğanın iyileştirici gücünü zihninde canlandır. Şehrin kaosundan uzaklaşıp yeşilin ve mavinin dinginliğine dal.',
        benefits: ['Zihni tazeler', 'Yaratıcılığı besler', 'Umut ve ferahlık hissi verir'],
        steps: [
            'Kendini yemyeşil bir çayırda veya bir dağ tepesinde hayal et.',
            'Başının üzerindeki sonsuz gökyüzünü ve bulutları izle.',
            'Hafif bir rüzgarın tenine değdiğini hisset.',
            'Güneşin sıcaklığının içine işlediğini hayal et.',
            'Doğanın döngüsünü ve sakinliğini düşün.',
            'Bu genişlik ve ferahlık hissiyle gözlerini aç.',
        ],
        duration: 15,
        type: 'visualization',
        icon: 'visualization',
      ),
    ];
  }
}

