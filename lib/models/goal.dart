class Goal {
  final String id;
  final String title;
  final String description;
  final int target;
  final int progress;
  final String type; // 'daily', 'weekly', 'monthly'
  final String category; // 'breathing', 'meditation', 'journal', 'anxiety_tracking'
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isActive;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.progress = 0,
    required this.type,
    required this.category,
    required this.createdAt,
    this.completedAt,
    this.isActive = true,
  });

  bool get isCompleted => progress >= target;

  double get progressPercentage => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target': target,
      'progress': progress,
      'type': type,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      target: map['target'] ?? 0,
      progress: map['progress'] ?? 0,
      type: map['type'] ?? 'daily',
      category: map['category'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    int? target,
    int? progress,
    String? type,
    String? category,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isActive,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Önceden tanımlı hedef örnekleri
  static List<Goal> getDefaultGoals() {
    return [
      Goal(
        id: 'goal_breathing_daily',
        title: 'Günlük Nefes Egzersizi',
        description: 'Her gün en az 1 nefes egzersizi yap',
        target: 1,
        type: 'daily',
        category: 'breathing',
        createdAt: DateTime.now(),
      ),
      Goal(
        id: 'goal_meditation_weekly',
        title: 'Haftalık Meditasyon',
        description: 'Bu hafta 3 meditasyon seansı tamamla',
        target: 3,
        type: 'weekly',
        category: 'meditation',
        createdAt: DateTime.now(),
      ),
      Goal(
        id: 'goal_journal_weekly',
        title: 'Haftalık Günlük Yazısı',
        description: 'Bu hafta 5 günlük yazısı yaz',
        target: 5,
        type: 'weekly',
        category: 'journal',
        createdAt: DateTime.now(),
      ),
      Goal(
        id: 'goal_anxiety_daily',
        title: 'Günlük Anksiyete Takibi',
        description: 'Her gün anksiyete seviyeni kaydet',
        target: 1,
        type: 'daily',
        category: 'anxiety_tracking',
        createdAt: DateTime.now(),
      ),
    ];
  }
}

