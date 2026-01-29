class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // FlutterRemix icon name
  final int targetValue;
  final AchievementType type;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetValue,
    required this.type,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      targetValue: map['targetValue'] as int,
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == 'AchievementType.${map['type']}',
        orElse: () => AchievementType.firstEntry,
      ),
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'targetValue': targetValue,
      'type': type.toString().split('.').last,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? targetValue,
    AchievementType? type,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      targetValue: targetValue ?? this.targetValue,
      type: type ?? this.type,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

enum AchievementType {
  firstEntry, // İlk anksiyete kaydı
  streak7, // 7 gün seri
  streak30, // 30 gün seri
  streak100, // 100 gün seri
  firstThought, // İlk düşünce kaydı
  firstJournal, // İlk günlük yazısı
  firstBreathing, // İlk nefes egzersizi
  thoughtMaster, // 10 düşünce kaydı
  thoughtExpert, // 50 düşünce kaydı
  journalWriter, // 10 günlük yazısı
  journalAuthor, // 50 günlük yazısı
  breathingPractitioner, // 10 nefes egzersizi
  chatActive, // 10 AI sohbeti
  weeklyTracker, // 7 hafta boyunca takip
  firstMeditation, // İlk meditasyon
  meditationBeginner, // 5 meditasyon
  meditationMaster, // 25 meditasyon
  goalAchiever, // İlk hedefi tamamla
  goalChampion, // 10 hedef tamamla
  goalLegend, // 50 hedef tamamla
}

class AchievementDefinitions {
  static List<Achievement> getAllAchievements() {
    return [
      Achievement(
        id: 'first_entry',
        title: 'İlk Adım',
        description: 'İlk anksiyete kaydını yap',
        icon: 'star_line',
        targetValue: 1,
        type: AchievementType.firstEntry,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Haftalık İstikrar',
        description: '7 gün üst üste kayıt yap',
        icon: 'calendar_line',
        targetValue: 7,
        type: AchievementType.streak7,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Aylık Disiplin',
        description: '30 gün üst üste kayıt yap',
        icon: 'calendar_fill',
        targetValue: 30,
        type: AchievementType.streak30,
      ),
      Achievement(
        id: 'streak_100',
        title: 'Ustası',
        description: '100 gün üst üste kayıt yap',
        icon: 'trophy_line',
        targetValue: 100,
        type: AchievementType.streak100,
      ),
      Achievement(
        id: 'first_thought',
        title: 'İlk Düşünce',
        description: 'İlk düşünce kaydını oluştur',
        icon: 'lightbulb_line',
        targetValue: 1,
        type: AchievementType.firstThought,
      ),
      Achievement(
        id: 'first_journal',
        title: 'İlk Günlük',
        description: 'İlk günlük yazısını yaz',
        icon: 'book_open_line',
        targetValue: 1,
        type: AchievementType.firstJournal,
      ),
      Achievement(
        id: 'first_breathing',
        title: 'İlk Nefes',
        description: 'İlk nefes egzersizi yap',
        icon: 'lungs_line',
        targetValue: 1,
        type: AchievementType.firstBreathing,
      ),
      Achievement(
        id: 'thought_master',
        title: 'Düşünce Ustası',
        description: '10 düşünce kaydı oluştur',
        icon: 'mental_health_line',
        targetValue: 10,
        type: AchievementType.thoughtMaster,
      ),
      Achievement(
        id: 'thought_expert',
        title: 'Düşünce Uzmanı',
        description: '50 düşünce kaydı oluştur',
        icon: 'focus_3_line',
        targetValue: 50,
        type: AchievementType.thoughtExpert,
      ),
      Achievement(
        id: 'journal_writer',
        title: 'Günlük Yazarı',
        description: '10 günlük yazısı yaz',
        icon: 'quill_pen_line',
        targetValue: 10,
        type: AchievementType.journalWriter,
      ),
      Achievement(
        id: 'journal_author',
        title: 'Günlük Yazarı Ustası',
        description: '50 günlük yazısı yaz',
        icon: 'book_2_line',
        targetValue: 50,
        type: AchievementType.journalAuthor,
      ),
      Achievement(
        id: 'breathing_practitioner',
        title: 'Nefes Uygulayıcısı',
        description: '10 nefes egzersizi tamamla',
        icon: 'leaf_line',
        targetValue: 10,
        type: AchievementType.breathingPractitioner,
      ),
      Achievement(
        id: 'chat_active',
        title: 'Sohbetsever',
        description: 'AI ile 10 sohbet yap',
        icon: 'chat_3_line',
        targetValue: 10,
        type: AchievementType.chatActive,
      ),
      Achievement(
        id: 'weekly_tracker',
        title: 'Haftalık Takipçi',
        description: '7 hafta boyunca kayıt tut',
        icon: 'line_chart_line',
        targetValue: 7,
        type: AchievementType.weeklyTracker,
      ),
      // Meditasyon Başarımları
      Achievement(
        id: 'first_meditation',
        title: 'İlk Meditasyon',
        description: 'İlk meditasyon seansını tamamla',
        icon: 'mental_health_line',
        targetValue: 1,
        type: AchievementType.firstMeditation,
      ),
      Achievement(
        id: 'meditation_beginner',
        title: 'Meditasyon Başlangıcı',
        description: '5 meditasyon seansı tamamla',
        icon: 'mental_health_line',
        targetValue: 5,
        type: AchievementType.meditationBeginner,
      ),
      Achievement(
        id: 'meditation_master',
        title: 'Meditasyon Ustası',
        description: '25 meditasyon seansı tamamla',
        icon: 'mental_health_line',
        targetValue: 25,
        type: AchievementType.meditationMaster,
      ),
      // Hedef Başarımları
      Achievement(
        id: 'goal_achiever',
        title: 'Hedef Avcısı',
        description: 'İlk hedefini tamamla',
        icon: 'trophy_line',
        targetValue: 1,
        type: AchievementType.goalAchiever,
      ),
      Achievement(
        id: 'goal_champion',
        title: 'Hedef Şampiyonu',
        description: '10 hedef tamamla',
        icon: 'trophy_line',
        targetValue: 10,
        type: AchievementType.goalChampion,
      ),
      Achievement(
        id: 'goal_legend',
        title: 'Hedef Efsanesi',
        description: '50 hedef tamamla',
        icon: 'trophy_line',
        targetValue: 50,
        type: AchievementType.goalLegend,
      ),
    ];
  }
}

