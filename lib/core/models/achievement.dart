class Achievement {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String icon;
  final DateTime? unlockedAt;
  final int currentProgress;
  final int targetProgress;

  Achievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    this.unlockedAt,
    required this.currentProgress,
    required this.targetProgress,
  });

  bool get isUnlocked => unlockedAt != null;
  double get progressPercentage => targetProgress == 0
      ? 0
      : (currentProgress / targetProgress * 100).clamp(0, 100);

  Achievement copyWith({
    String? id,
    String? titleKey,
    String? descriptionKey,
    String? icon,
    DateTime? unlockedAt,
    int? currentProgress,
    int? targetProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      titleKey: titleKey ?? this.titleKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      icon: icon ?? this.icon,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'icon': icon,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      titleKey: json['titleKey'],
      descriptionKey: json['descriptionKey'],
      icon: json['icon'],
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      currentProgress: json['currentProgress'] ?? 0,
      targetProgress: json['targetProgress'] ?? 0,
    );
  }
}

// Predefined achievement IDs
class AchievementIds {
  static const String streak7Days = 'streak_7_days';
  static const String tasks100 = 'tasks_100';
  static const String focusSessions10 = 'focus_sessions_10';
  static const String streak30Days = 'streak_30_days';
  static const String tasks500 = 'tasks_500';
  static const String focusHours50 = 'focus_hours_50';
}
