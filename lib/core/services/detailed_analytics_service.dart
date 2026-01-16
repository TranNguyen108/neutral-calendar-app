import 'package:get/get.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/diary.dart';
import '../models/note.dart';
import 'storage_service.dart';
import 'content_service.dart';

/// Service analytics chi tiết với real-time tracking
class DetailedAnalyticsService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  late final ContentService _content;

  // Real-time observable analytics
  final productivity = ProductivityMetrics().obs;
  final taskStats = TaskStatistics().obs;
  final timeManagement = TimeManagementMetrics().obs;
  final wellbeing = WellbeingMetrics().obs;

  @override
  void onInit() {
    super.onInit();
    _content = Get.find<ContentService>();
    refreshAllMetrics();
  }

  /// Refresh tất cả metrics
  Future<void> refreshAllMetrics() async {
    await Future.wait([
      _updateProductivityMetrics(),
      _updateTaskStatistics(),
      _updateTimeManagement(),
      _updateWellbeingMetrics(),
    ]);
  }

  /// === PRODUCTIVITY METRICS ===
  Future<void> _updateProductivityMetrics() async {
    final tasks = _storage.getTasks();
    final now = DateTime.now();

    // Today
    final todayTasks = tasks.where((t) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      final today = DateTime(now.year, now.month, now.day);
      return date.isAtSameMomentAs(today);
    }).toList();

    // This week
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekTasks = tasks.where((t) => t.date.isAfter(weekStart)).toList();

    // This month
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTasks = tasks.where((t) => t.date.isAfter(monthStart)).toList();

    productivity.value = ProductivityMetrics(
      todayCompleted:
          todayTasks.where((t) => t.status == TaskStatus.done).length,
      todayTotal: todayTasks.length,
      weekCompleted: weekTasks.where((t) => t.status == TaskStatus.done).length,
      weekTotal: weekTasks.length,
      monthCompleted:
          monthTasks.where((t) => t.status == TaskStatus.done).length,
      monthTotal: monthTasks.length,
      overallCompletionRate: tasks.isEmpty
          ? 0.0
          : (tasks.where((t) => t.status == TaskStatus.done).length /
                  tasks.length *
                  100)
              .roundToDouble(),
      streakDays: _calculateStreak(tasks),
      averageTasksPerDay: _calculateAvgTasksPerDay(tasks),
      productivityScore: _calculateProductivityScore(tasks),
    );
  }

  int _calculateStreak(List<Task> tasks) {
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
      if (streak > 365) break;
    }

    return streak;
  }

  double _calculateAvgTasksPerDay(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    final recentTasks = tasks.where((t) => t.createdAt.isAfter(last30Days));
    return (recentTasks.length / 30).roundToDouble();
  }

  double _calculateProductivityScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;

    final completionRate =
        tasks.where((t) => t.status == TaskStatus.done).length / tasks.length;
    final streakBonus = (_calculateStreak(tasks) / 30).clamp(0.0, 1.0);

    return ((completionRate * 70) + (streakBonus * 30)).clamp(0.0, 100.0);
  }

  /// === TASK STATISTICS ===
  Future<void> _updateTaskStatistics() async {
    final tasks = _storage.getTasks();

    final byStatus = {
      'todo': tasks.where((t) => t.status == TaskStatus.todo).length,
      'inProgress':
          tasks.where((t) => t.status == TaskStatus.inProgress).length,
      'done': tasks.where((t) => t.status == TaskStatus.done).length,
    };

    final byPriority = {
      'high': tasks.where((t) => t.priority == Priority.high).length,
      'medium': tasks.where((t) => t.priority == Priority.medium).length,
      'low': tasks.where((t) => t.priority == Priority.low).length,
    };

    final overdueTasks = tasks.where((t) {
      return t.status != TaskStatus.done &&
          t.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    }).length;

    final upcomingTasks = tasks.where((t) {
      final now = DateTime.now();
      return t.date.isAfter(now) &&
          t.date.isBefore(now.add(const Duration(days: 7)));
    }).length;

    taskStats.value = TaskStatistics(
      total: tasks.length,
      byStatus: byStatus,
      byPriority: byPriority,
      overdue: overdueTasks,
      upcoming: upcomingTasks,
      highPriorityCompleted: tasks
          .where(
              (t) => t.priority == Priority.high && t.status == TaskStatus.done)
          .length,
      averageCompletionTime: _calculateAvgCompletionTime(tasks),
    );
  }

  Duration _calculateAvgCompletionTime(List<Task> tasks) {
    final completed = tasks.where((t) => t.status == TaskStatus.done);
    if (completed.isEmpty) return const Duration(hours: 1);

    int totalMinutes = 0;
    int count = 0;

    for (var task in completed) {
      final duration = task.updatedAt.difference(task.createdAt);
      if (duration.inDays < 7) {
        totalMinutes += duration.inMinutes;
        count++;
      }
    }

    if (count == 0) return const Duration(hours: 1);
    return Duration(minutes: (totalMinutes / count).round());
  }

  /// === TIME MANAGEMENT ===
  Future<void> _updateTimeManagement() async {
    final tasks = _storage.getTasks();

    final peakHours = _findPeakHours(tasks);
    final mostProductiveDay = _findMostProductiveDay(tasks);
    final timeDistribution = _analyzeTimeDistribution(tasks);

    timeManagement.value = TimeManagementMetrics(
      peakProductivityHours: peakHours,
      mostProductiveDayOfWeek: mostProductiveDay,
      morningTasksCompleted: timeDistribution['morning']!,
      afternoonTasksCompleted: timeDistribution['afternoon']!,
      eveningTasksCompleted: timeDistribution['evening']!,
      averageStartTime: _calculateAvgStartTime(tasks),
      tasksWithDeadline: tasks.where((t) => t.startTime != null).length,
      tasksWithoutDeadline: tasks.where((t) => t.startTime == null).length,
    );
  }

  List<int> _findPeakHours(List<Task> tasks) {
    final hourCounts = <int, int>{};

    for (var task in tasks) {
      if (task.status == TaskStatus.done && task.startTime != null) {
        final hour = task.startTime!.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }

    if (hourCounts.isEmpty) return [9, 14, 16];

    final sorted = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  int _findMostProductiveDay(List<Task> tasks) {
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

  Map<String, int> _analyzeTimeDistribution(List<Task> tasks) {
    int morning = 0, afternoon = 0, evening = 0;

    for (var task in tasks) {
      if (task.status == TaskStatus.done && task.startTime != null) {
        final hour = task.startTime!.hour;
        if (hour >= 6 && hour < 12) {
          morning++;
        } else if (hour >= 12 && hour < 18) {
          afternoon++;
        } else {
          evening++;
        }
      }
    }

    return {
      'morning': morning,
      'afternoon': afternoon,
      'evening': evening,
    };
  }

  String _calculateAvgStartTime(List<Task> tasks) {
    final tasksWithTime = tasks.where((t) => t.startTime != null).toList();

    if (tasksWithTime.isEmpty) return '09:00';

    int totalMinutes = 0;
    for (var task in tasksWithTime) {
      totalMinutes += task.startTime!.hour * 60 + task.startTime!.minute;
    }

    final avgMinutes = (totalMinutes / tasksWithTime.length).round();
    final hour = (avgMinutes ~/ 60).toString().padLeft(2, '0');
    final minute = (avgMinutes % 60).toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  /// === WELLBEING METRICS ===
  Future<void> _updateWellbeingMetrics() async {
    final diaries = _content.diaries;
    final tasks = _storage.getTasks();

    final moodData = _analyzeMoodData(diaries);
    final workload = _assessWorkload(tasks);
    final burnout = _assessBurnout(tasks, diaries);

    wellbeing.value = WellbeingMetrics(
      averageMood: moodData['average'] as String,
      moodTrend: moodData['trend'] as String,
      diaryEntriesThisMonth: moodData['count'] as int,
      workloadLevel: workload,
      burnoutRisk: burnout,
      stressIndicators: _identifyStressIndicators(tasks),
      wellnessScore: _calculateWellnessScore(tasks, diaries),
    );
  }

  Map<String, dynamic> _analyzeMoodData(List<Diary> diaries) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final recentDiaries =
        diaries.where((d) => d.date.isAfter(monthStart)).toList();

    if (recentDiaries.isEmpty) {
      return {'average': 'neutral', 'trend': 'stable', 'count': 0};
    }

    final moods =
        recentDiaries.where((d) => d.mood != null).map((d) => d.mood!).toList();

    if (moods.isEmpty) {
      return {
        'average': 'neutral',
        'trend': 'stable',
        'count': recentDiaries.length
      };
    }

    final moodCounts = <String, int>{};
    for (var mood in moods) {
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    final mostCommon =
        moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return {
      'average': mostCommon,
      'trend': 'stable',
      'count': recentDiaries.length
    };
  }

  String _assessWorkload(List<Task> tasks) {
    final avgTasksPerDay = _calculateAvgTasksPerDay(tasks);

    if (avgTasksPerDay < 3) return 'light';
    if (avgTasksPerDay < 7) return 'moderate';
    if (avgTasksPerDay < 10) return 'heavy';
    return 'overload';
  }

  double _assessBurnout(List<Task> tasks, List<Diary> diaries) {
    double risk = 0.0;

    final avgTasksPerDay = _calculateAvgTasksPerDay(tasks);
    if (avgTasksPerDay > 10) risk += 30;

    final completionRate = tasks.isEmpty
        ? 0.0
        : tasks.where((t) => t.status == TaskStatus.done).length / tasks.length;
    if (completionRate < 0.5) risk += 20;

    if (diaries.isEmpty) risk += 20;

    final moodData = _analyzeMoodData(diaries);
    if (moodData['average'] == 'sad' || moodData['average'] == 'tired') {
      risk += 30;
    }

    return risk.clamp(0.0, 100.0);
  }

  List<String> _identifyStressIndicators(List<Task> tasks) {
    final indicators = <String>[];

    final overdueTasks = tasks.where((t) {
      return t.status != TaskStatus.done &&
          t.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    }).length;

    if (overdueTasks > 5) {
      indicators.add('Nhiều task quá hạn ($overdueTasks)');
    }

    final highPriorityPending = tasks
        .where(
            (t) => t.priority == Priority.high && t.status != TaskStatus.done)
        .length;

    if (highPriorityPending > 3) {
      indicators.add('Nhiều task ưu tiên cao chưa hoàn thành');
    }

    final avgTasksPerDay = _calculateAvgTasksPerDay(tasks);
    if (avgTasksPerDay > 10) {
      indicators.add('Khối lượng công việc quá cao');
    }

    return indicators;
  }

  double _calculateWellnessScore(List<Task> tasks, List<Diary> diaries) {
    double score = 100.0;

    final burnout = _assessBurnout(tasks, diaries);
    score -= burnout * 0.5;

    final completionRate = tasks.isEmpty
        ? 0.0
        : tasks.where((t) => t.status == TaskStatus.done).length / tasks.length;
    score = score * completionRate + (score * 0.3);

    if (diaries.isEmpty) {
      score -= 20;
    }

    return score.clamp(0.0, 100.0);
  }

  /// === EXPORT ANALYTICS ===
  Map<String, dynamic> exportFullReport() {
    return {
      'productivity': productivity.value.toJson(),
      'taskStats': taskStats.value.toJson(),
      'timeManagement': timeManagement.value.toJson(),
      'wellbeing': wellbeing.value.toJson(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Productivity Metrics Model
class ProductivityMetrics {
  final int todayCompleted;
  final int todayTotal;
  final int weekCompleted;
  final int weekTotal;
  final int monthCompleted;
  final int monthTotal;
  final double overallCompletionRate;
  final int streakDays;
  final double averageTasksPerDay;
  final double productivityScore;

  ProductivityMetrics({
    this.todayCompleted = 0,
    this.todayTotal = 0,
    this.weekCompleted = 0,
    this.weekTotal = 0,
    this.monthCompleted = 0,
    this.monthTotal = 0,
    this.overallCompletionRate = 0.0,
    this.streakDays = 0,
    this.averageTasksPerDay = 0.0,
    this.productivityScore = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'todayCompleted': todayCompleted,
        'todayTotal': todayTotal,
        'weekCompleted': weekCompleted,
        'weekTotal': weekTotal,
        'monthCompleted': monthCompleted,
        'monthTotal': monthTotal,
        'overallCompletionRate': overallCompletionRate,
        'streakDays': streakDays,
        'averageTasksPerDay': averageTasksPerDay,
        'productivityScore': productivityScore,
      };
}

/// Task Statistics Model
class TaskStatistics {
  final int total;
  final Map<String, int> byStatus;
  final Map<String, int> byPriority;
  final int overdue;
  final int upcoming;
  final int highPriorityCompleted;
  final Duration averageCompletionTime;

  TaskStatistics({
    this.total = 0,
    this.byStatus = const {},
    this.byPriority = const {},
    this.overdue = 0,
    this.upcoming = 0,
    this.highPriorityCompleted = 0,
    this.averageCompletionTime = const Duration(hours: 1),
  });

  Map<String, dynamic> toJson() => {
        'total': total,
        'byStatus': byStatus,
        'byPriority': byPriority,
        'overdue': overdue,
        'upcoming': upcoming,
        'highPriorityCompleted': highPriorityCompleted,
        'averageCompletionTimeHours': averageCompletionTime.inHours,
      };
}

/// Time Management Metrics
class TimeManagementMetrics {
  final List<int> peakProductivityHours;
  final int mostProductiveDayOfWeek;
  final int morningTasksCompleted;
  final int afternoonTasksCompleted;
  final int eveningTasksCompleted;
  final String averageStartTime;
  final int tasksWithDeadline;
  final int tasksWithoutDeadline;

  TimeManagementMetrics({
    this.peakProductivityHours = const [],
    this.mostProductiveDayOfWeek = 1,
    this.morningTasksCompleted = 0,
    this.afternoonTasksCompleted = 0,
    this.eveningTasksCompleted = 0,
    this.averageStartTime = '09:00',
    this.tasksWithDeadline = 0,
    this.tasksWithoutDeadline = 0,
  });

  Map<String, dynamic> toJson() => {
        'peakProductivityHours': peakProductivityHours,
        'mostProductiveDayOfWeek': mostProductiveDayOfWeek,
        'morningTasksCompleted': morningTasksCompleted,
        'afternoonTasksCompleted': afternoonTasksCompleted,
        'eveningTasksCompleted': eveningTasksCompleted,
        'averageStartTime': averageStartTime,
        'tasksWithDeadline': tasksWithDeadline,
        'tasksWithoutDeadline': tasksWithoutDeadline,
      };
}

/// Wellbeing Metrics
class WellbeingMetrics {
  final String averageMood;
  final String moodTrend;
  final int diaryEntriesThisMonth;
  final String workloadLevel;
  final double burnoutRisk;
  final List<String> stressIndicators;
  final double wellnessScore;

  WellbeingMetrics({
    this.averageMood = 'neutral',
    this.moodTrend = 'stable',
    this.diaryEntriesThisMonth = 0,
    this.workloadLevel = 'moderate',
    this.burnoutRisk = 0.0,
    this.stressIndicators = const [],
    this.wellnessScore = 50.0,
  });

  Map<String, dynamic> toJson() => {
        'averageMood': averageMood,
        'moodTrend': moodTrend,
        'diaryEntriesThisMonth': diaryEntriesThisMonth,
        'workloadLevel': workloadLevel,
        'burnoutRisk': burnoutRisk,
        'stressIndicators': stressIndicators,
        'wellnessScore': wellnessScore,
      };
}
