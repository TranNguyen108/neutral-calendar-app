import 'package:get/get.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/diary.dart';
import 'storage_service.dart';
import 'content_service.dart';

/// Service phân tích thói quen và pattern của người dùng
class HabitAnalyticsService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  late final ContentService _content;

  // Analytics cache
  final _analysisCache = <String, dynamic>{}.obs;
  DateTime? _lastAnalysis;

  @override
  void onInit() {
    super.onInit();
    _content = Get.find<ContentService>();
  }

  /// Phân tích toàn diện thói quen người dùng
  Future<UserHabitProfile> analyzeUserHabits() async {
    // Cache cho 1 giờ
    if (_lastAnalysis != null &&
        DateTime.now().difference(_lastAnalysis!) < const Duration(hours: 1)) {
      return UserHabitProfile.fromJson(_analysisCache);
    }

    final tasks = _storage.getTasks();
    final events = _content.events;
    final diaries = _content.diaries;

    final profile = UserHabitProfile(
      totalTasks: tasks.length,
      completedTasks: tasks.where((t) => t.status == TaskStatus.done).length,
      productivityScore: _calculateProductivityScore(tasks),
      peakProductivityHours: _findPeakProductivityHours(tasks),
      averageTasksPerDay: _calculateAverageTasksPerDay(tasks),
      mostProductiveDayOfWeek: _findMostProductiveDayOfWeek(tasks),
      taskCompletionRate: _calculateCompletionRate(tasks),
      averageTaskDuration: _estimateAverageTaskDuration(tasks),
      commonTaskCategories: _findCommonCategories(tasks),
      taskPriorityDistribution: _analyzePriorityDistribution(tasks),
      streakDays: _calculateStreak(tasks),
      moodPatterns: _analyzeMoodPatterns(diaries),
      procrastinationScore: _calculateProcrastinationScore(tasks),
      focusTimeRecommendation: _recommendFocusTime(tasks),
      burnoutRisk: _assessBurnoutRisk(tasks, diaries),
      suggestions: _generateSmartSuggestions(tasks, events, diaries),
    );

    _analysisCache.value = profile.toJson();
    _lastAnalysis = DateTime.now();

    return profile;
  }

  /// Tính điểm productivity (0-100)
  double _calculateProductivityScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;

    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    final recentTasks = tasks.where((t) => t.createdAt.isAfter(last30Days));

    if (recentTasks.isEmpty) return 0.0;

    final completed =
        recentTasks.where((t) => t.status == TaskStatus.done).length;
    final completionRate = completed / recentTasks.length;

    // Factors: completion rate (50%), high priority completion (30%), streak (20%)
    final highPriorityCompleted = recentTasks
        .where(
            (t) => t.priority == Priority.high && t.status == TaskStatus.done)
        .length;
    final highPriorityRate =
        recentTasks.where((t) => t.priority == Priority.high).isEmpty
            ? 0.0
            : highPriorityCompleted /
                recentTasks.where((t) => t.priority == Priority.high).length;

    final streakBonus = (_calculateStreak(tasks.toList()) / 30).clamp(0.0, 1.0);

    return ((completionRate * 50) +
            (highPriorityRate * 30) +
            (streakBonus * 20))
        .clamp(0.0, 100.0);
  }

  /// Tìm giờ làm việc hiệu quả nhất
  List<int> _findPeakProductivityHours(List<Task> tasks) {
    final hourCounts = <int, int>{};

    for (var task in tasks) {
      if (task.status == TaskStatus.done && task.startTime != null) {
        final hour = task.startTime!.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }

    if (hourCounts.isEmpty) return [9, 10, 14]; // Default

    final sorted = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Tính số task trung bình mỗi ngày
  double _calculateAverageTasksPerDay(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;

    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    final recentTasks = tasks.where((t) => t.createdAt.isAfter(last30Days));

    return recentTasks.length / 30;
  }

  /// Tìm ngày trong tuần hiệu quả nhất
  int _findMostProductiveDayOfWeek(List<Task> tasks) {
    final dayCounts = <int, int>{};

    for (var task in tasks) {
      if (task.status == TaskStatus.done) {
        final day = task.date.weekday;
        dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      }
    }

    if (dayCounts.isEmpty) return DateTime.monday;

    return dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Tính tỷ lệ hoàn thành task
  double _calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.status == TaskStatus.done).length;
    return (completed / tasks.length * 100).roundToDouble();
  }

  /// Ước tính thời gian trung bình hoàn thành task
  Duration _estimateAverageTaskDuration(List<Task> tasks) {
    final completed = tasks.where((t) => t.status == TaskStatus.done);

    if (completed.isEmpty) return const Duration(hours: 1);

    int totalMinutes = 0;
    int count = 0;

    for (var task in completed) {
      final duration = task.updatedAt.difference(task.createdAt);
      if (duration.inDays < 7) {
        // Only count tasks completed within a week
        totalMinutes += duration.inMinutes;
        count++;
      }
    }

    if (count == 0) return const Duration(hours: 1);
    return Duration(minutes: (totalMinutes / count).round());
  }

  /// Tìm categories phổ biến
  Map<String, int> _findCommonCategories(List<Task> tasks) {
    final categories = <String, int>{};

    for (var task in tasks) {
      if (task.category != null) {
        categories[task.category!] = (categories[task.category!] ?? 0) + 1;
      }
    }

    return Map.fromEntries(
      categories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5),
    );
  }

  /// Phân tích phân bố priority
  Map<String, double> _analyzePriorityDistribution(List<Task> tasks) {
    if (tasks.isEmpty) {
      return {'high': 0, 'medium': 0, 'low': 0};
    }

    final high = tasks.where((t) => t.priority == Priority.high).length;
    final medium = tasks.where((t) => t.priority == Priority.medium).length;
    final low = tasks.where((t) => t.priority == Priority.low).length;

    return {
      'high': (high / tasks.length * 100).roundToDouble(),
      'medium': (medium / tasks.length * 100).roundToDouble(),
      'low': (low / tasks.length * 100).roundToDouble(),
    };
  }

  /// Tính streak (số ngày liên tiếp hoàn thành task)
  int _calculateStreak(List<Task> tasks) {
    if (tasks.isEmpty) return 0;

    final completedByDate = <DateTime, bool>{};

    for (var task in tasks) {
      if (task.status == TaskStatus.done) {
        final date = DateTime(task.date.year, task.date.month, task.date.day);
        completedByDate[date] = true;
      }
    }

    int streak = 0;
    var currentDate = DateTime.now();
    final today =
        DateTime(currentDate.year, currentDate.month, currentDate.day);

    while (completedByDate[today.subtract(Duration(days: streak))] == true) {
      streak++;
      if (streak > 365) break; // Max 1 year
    }

    return streak;
  }

  /// Phân tích mood patterns từ diary
  Map<String, dynamic> _analyzeMoodPatterns(List<Diary> diaries) {
    if (diaries.isEmpty) {
      return {'average': 'neutral', 'trend': 'stable'};
    }

    final recentDiaries = diaries
        .where((d) =>
            d.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .toList();

    if (recentDiaries.isEmpty) {
      return {'average': 'neutral', 'trend': 'stable'};
    }

    // Simplified mood analysis
    final moods =
        recentDiaries.where((d) => d.mood != null).map((d) => d.mood!).toList();

    if (moods.isEmpty) {
      return {'average': 'neutral', 'trend': 'stable'};
    }

    final moodCounts = <String, int>{};
    for (var mood in moods) {
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    final mostCommonMood =
        moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return {
      'average': mostCommonMood,
      'trend': 'stable',
      'entries': moods.length,
    };
  }

  /// Tính điểm trì hoãn (0-100, càng cao càng hay trì hoãn)
  double _calculateProcrastinationScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;

    final completedTasks = tasks.where((t) => t.status == TaskStatus.done);
    if (completedTasks.isEmpty) return 50.0;

    int lateCount = 0;
    for (var task in completedTasks) {
      // If task completed after its due date
      if (task.updatedAt.isAfter(task.date.add(const Duration(days: 1)))) {
        lateCount++;
      }
    }

    return (lateCount / completedTasks.length * 100).clamp(0.0, 100.0);
  }

  /// Recommend focus time based on patterns
  Map<String, dynamic> _recommendFocusTime(List<Task> tasks) {
    final peakHours = _findPeakProductivityHours(tasks);

    return {
      'recommendedHours': peakHours,
      'duration': 90, // minutes
      'breakDuration': 15, // minutes
    };
  }

  /// Assess burnout risk (0-100)
  double _assessBurnoutRisk(List<Task> tasks, List<Diary> diaries) {
    double risk = 0.0;

    // Factor 1: Too many tasks
    final avgTasksPerDay = _calculateAverageTasksPerDay(tasks);
    if (avgTasksPerDay > 10) {
      risk += 30;
    } else if (avgTasksPerDay > 7) {
      risk += 15;
    }

    // Factor 2: Low completion rate
    final completionRate = _calculateCompletionRate(tasks);
    if (completionRate < 50) {
      risk += 20;
    }

    // Factor 3: Negative mood trend
    final moodAnalysis = _analyzeMoodPatterns(diaries);
    if (moodAnalysis['average'] == 'sad' ||
        moodAnalysis['average'] == 'tired') {
      risk += 30;
    }

    // Factor 4: No breaks (no diary entries)
    if (diaries.isEmpty) {
      risk += 20;
    }

    return risk.clamp(0.0, 100.0);
  }

  /// Generate smart suggestions
  List<String> _generateSmartSuggestions(
      List<Task> tasks, List<Event> events, List<Diary> diaries) {
    final suggestions = <String>[];

    final completionRate = _calculateCompletionRate(tasks);
    if (completionRate < 50) {
      suggestions.add(
          'Tỷ lệ hoàn thành thấp. Hãy thử chia nhỏ tasks thành các bước nhỏ hơn.');
    }

    final procrastination = _calculateProcrastinationScore(tasks);
    if (procrastination > 60) {
      suggestions.add(
          'Bạn hay trì hoãn. Thử áp dụng kỹ thuật Pomodoro để tập trung hơn.');
    }

    final burnout = _assessBurnoutRisk(tasks, diaries);
    if (burnout > 70) {
      suggestions
          .add('Nguy cơ kiệt sức cao! Hãy nghỉ ngơi và tự chăm sóc bản thân.');
    }

    final streak = _calculateStreak(tasks);
    if (streak > 7) {
      suggestions.add(
          'Tuyệt vời! Bạn đang có streak $streak ngày. Tiếp tục phát huy!');
    }

    if (diaries.isEmpty) {
      suggestions.add(
          'Bạn chưa viết diary. Hãy dành vài phút mỗi ngày để ghi lại suy nghĩ.');
    }

    if (suggestions.isEmpty) {
      suggestions
          .add('Bạn đang làm rất tốt! Tiếp tục duy trì thói quen hiện tại.');
    }

    return suggestions;
  }
}

/// User Habit Profile
class UserHabitProfile {
  final int totalTasks;
  final int completedTasks;
  final double productivityScore;
  final List<int> peakProductivityHours;
  final double averageTasksPerDay;
  final int mostProductiveDayOfWeek;
  final double taskCompletionRate;
  final Duration averageTaskDuration;
  final Map<String, int> commonTaskCategories;
  final Map<String, double> taskPriorityDistribution;
  final int streakDays;
  final Map<String, dynamic> moodPatterns;
  final double procrastinationScore;
  final Map<String, dynamic> focusTimeRecommendation;
  final double burnoutRisk;
  final List<String> suggestions;

  UserHabitProfile({
    required this.totalTasks,
    required this.completedTasks,
    required this.productivityScore,
    required this.peakProductivityHours,
    required this.averageTasksPerDay,
    required this.mostProductiveDayOfWeek,
    required this.taskCompletionRate,
    required this.averageTaskDuration,
    required this.commonTaskCategories,
    required this.taskPriorityDistribution,
    required this.streakDays,
    required this.moodPatterns,
    required this.procrastinationScore,
    required this.focusTimeRecommendation,
    required this.burnoutRisk,
    required this.suggestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'productivityScore': productivityScore,
      'peakProductivityHours': peakProductivityHours,
      'averageTasksPerDay': averageTasksPerDay,
      'mostProductiveDayOfWeek': mostProductiveDayOfWeek,
      'taskCompletionRate': taskCompletionRate,
      'averageTaskDurationMinutes': averageTaskDuration.inMinutes,
      'commonTaskCategories': commonTaskCategories,
      'taskPriorityDistribution': taskPriorityDistribution,
      'streakDays': streakDays,
      'moodPatterns': moodPatterns,
      'procrastinationScore': procrastinationScore,
      'focusTimeRecommendation': focusTimeRecommendation,
      'burnoutRisk': burnoutRisk,
      'suggestions': suggestions,
    };
  }

  factory UserHabitProfile.fromJson(Map<String, dynamic> json) {
    return UserHabitProfile(
      totalTasks: json['totalTasks'] as int,
      completedTasks: json['completedTasks'] as int,
      productivityScore: (json['productivityScore'] as num).toDouble(),
      peakProductivityHours:
          List<int>.from(json['peakProductivityHours'] as List),
      averageTasksPerDay: (json['averageTasksPerDay'] as num).toDouble(),
      mostProductiveDayOfWeek: json['mostProductiveDayOfWeek'] as int,
      taskCompletionRate: (json['taskCompletionRate'] as num).toDouble(),
      averageTaskDuration:
          Duration(minutes: json['averageTaskDurationMinutes'] as int),
      commonTaskCategories: Map<String, int>.from(
          json['commonTaskCategories'] as Map<String, dynamic>),
      taskPriorityDistribution: Map<String, double>.from(
          json['taskPriorityDistribution'] as Map<String, dynamic>),
      streakDays: json['streakDays'] as int,
      moodPatterns: json['moodPatterns'] as Map<String, dynamic>,
      procrastinationScore: (json['procrastinationScore'] as num).toDouble(),
      focusTimeRecommendation:
          json['focusTimeRecommendation'] as Map<String, dynamic>,
      burnoutRisk: (json['burnoutRisk'] as num).toDouble(),
      suggestions: List<String>.from(json['suggestions'] as List),
    );
  }
}
