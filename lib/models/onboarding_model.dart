class OnboardingModel {
  Map<String, dynamic> answers = {};
  DateTime? startedAt;
  DateTime? completedAt;

  OnboardingModel({Map<String, dynamic>? answers, this.startedAt, this.completedAt}) {
    if (answers != null) this.answers = answers;
  }

  Map<String, dynamic> toMap() {
    return {
      'answers': answers,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  static OnboardingModel fromMap(Map<String, dynamic> map) {
    return OnboardingModel(
      answers: Map<String, dynamic>.from(map['answers'] ?? {}),
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }
}
