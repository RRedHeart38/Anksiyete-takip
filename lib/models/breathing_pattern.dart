import 'package:flutter/material.dart';

class BreathingPattern {
  final String id;
  final String title;
  final String description;
  final String detailedDescription;
  final List<String> benefits;
  final Color color;
  final List<BreathingGenericPhase> phases;

  BreathingPattern({
    required this.id,
    required this.title,
    required this.description,
    required this.detailedDescription,
    required this.benefits,
    this.color = Colors.blue, // Default color
    required this.phases,
  });

  static List<BreathingPattern> getPatterns() {
    return [
      BreathingPattern(
        id: '4-7-8',
        title: '4-7-8 Tekniği',
        description: 'Anksiyete ve stresi hızla azaltmak için doğal bir sakinleştirici.',
        detailedDescription: 'Dr. Andrew Weil tarafından geliştirilen bu teknik, sinir sistemini "kaç veya savaş" modundan çıkarıp "dinlen ve sindir" moduna geçirir. Uykuya dalmakta zorlananlar için de harikadır.',
        benefits: ['Nabzı yavaşlatır', 'Panik atağı kontrol altına almaya yardımcı olur', 'Uyku kalitesini artırır'],
        color: Colors.blue, // Uniform color
        phases: [
          BreathingGenericPhase(label: 'Burnundan Al', duration: 4, instruction: 'Sessizce burnundan nefes al.'),
          BreathingGenericPhase(label: 'Tut', duration: 7, instruction: 'Nefesini tut.'),
          BreathingGenericPhase(label: 'Ağzından Ver', duration: 8, instruction: 'Dudaklarını büzerek ve "vuuu" sesi çıkararak nefes ver.'),
        ],
      ),
      BreathingPattern(
        id: 'box',
        title: 'Kutu Nefesi',
        description: 'Odaklanmayı artırır ve zihni berraklaştırır.',
        detailedDescription: 'Navy SEAL komandoları tarafından stresli durumlarda sakin kalmak için kullanılan güçlü bir tekniktir. 4 eşit parçadan oluşur, bu yüzden "kutu" veya "kare" nefesi denir.',
        benefits: ['Zihinsel berraklığı artırır', 'Otonom sinir sistemini dengeler', 'Kan basıncını düzenler'],
        color: Colors.blue, // Uniform color
        phases: [
          BreathingGenericPhase(label: 'Al', duration: 4, instruction: 'Burnundan derin nefes al.'),
          BreathingGenericPhase(label: 'Tut', duration: 4, instruction: 'Ciğerlerin doluyken tut.'),
          BreathingGenericPhase(label: 'Ver', duration: 4, instruction: 'Yavaşça nefes ver.'),
          BreathingGenericPhase(label: 'Tut', duration: 4, instruction: 'Ciğerlerin boşken tut.'),
        ],
      ),
      BreathingPattern(
        id: 'diaphragm',
        title: 'Diyafram Nefesi',
        description: 'Karından derin nefes alarak gevşemeyi aktive eder.',
        detailedDescription: 'Bebekler doğal olarak böyle nefes alır. Yetişkinlikte unuttuğumuz bu doğal nefes alma biçimi, vücudun en verimli oksijen alma yoludur.',
        benefits: ['Stres hormonunu azaltır', 'Core (merkez) kaslarını güçlendirir', 'Sindirim sistemini rahatlatır'],
        color: Colors.blue, // Uniform color
        phases: [
          BreathingGenericPhase(label: 'Karnını Şişir', duration: 4, instruction: 'Burnundan al, elini karnına koy ve şiştiğini hisset.'),
          BreathingGenericPhase(label: 'Yavaşça Ver', duration: 6, instruction: 'Karnının içeri çekildiğini hissederek yavaşça ver.'),
        ],
      ),
    ];
  }
}

class BreathingGenericPhase {
  final String label;
  final int duration;
  final String instruction;

  BreathingGenericPhase({required this.label, required this.duration, required this.instruction});
}
