import 'package:get/get.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';

class ReportController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final totalTasksToday = 0.obs;
  final completedTasksToday = 0.obs;
  final totalTasksWeek = 0.obs;
  final completedTasksWeek = 0.obs;
  final totalFocusMinutesToday = 0.obs;
  final totalFocusMinutesWeek = 0.obs;
  final dailyStreak = 0.obs;

  final weeklyTasksByCategory = <String, int>{}.obs;
  final weeklyCompletionByDay = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadStatistics();
  }

  void loadStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    final allTasks = _storage.getTasks();
    final allSessions = _storage.getFocusSessions();

    // Today stats
    final todayTasks = allTasks
        .where((task) =>
            task.date.year == today.year &&
            task.date.month == today.month &&
            task.date.day == today.day)
        .toList();

    totalTasksToday.value = todayTasks.length;
    completedTasksToday.value =
        todayTasks.where((t) => t.status == TaskStatus.done).length;

    final todaySessions = allSessions
        .where((s) =>
            s.startTime.year == today.year &&
            s.startTime.month == today.month &&
            s.startTime.day == today.day)
        .toList();

    totalFocusMinutesToday.value =
        todaySessions.fold(0, (sum, s) => sum + s.durationMinutes);

    // Week stats
    final weekTasks =
        allTasks.where((task) => task.date.isAfter(weekAgo)).toList();
    totalTasksWeek.value = weekTasks.length;
    completedTasksWeek.value =
        weekTasks.where((t) => t.status == TaskStatus.done).length;

    final weekSessions =
        allSessions.where((s) => s.startTime.isAfter(weekAgo)).toList();
    totalFocusMinutesWeek.value =
        weekSessions.fold(0, (sum, s) => sum + s.durationMinutes);

    // Tasks by category
    final categoryMap = <String, int>{};
    for (var task in weekTasks) {
      if (task.category != null) {
        categoryMap[task.category!] = (categoryMap[task.category!] ?? 0) + 1;
      }
    }
    weeklyTasksByCategory.value = categoryMap;

    // Completion by day
    final dayMap = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: 6 - i));
      final dayTasks = allTasks
          .where((task) =>
              task.date.year == day.year &&
              task.date.month == day.month &&
              task.date.day == day.day &&
              task.status == TaskStatus.done)
          .length;
      dayMap[_getDayName(i)] = dayTasks;
    }
    weeklyCompletionByDay.value = dayMap;

    // Daily streak
    dailyStreak.value = _storage.getDailyStreak();
    _updateStreak();
  }

  void _updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCompletion = _storage.getLastCompletionDate();

    if (completedTasksToday.value > 0) {
      if (lastCompletion == null) {
        // First completion ever
        _storage.setDailyStreak(1);
        _storage.setLastCompletionDate(today);
        dailyStreak.value = 1;
      } else {
        final lastDay = DateTime(
            lastCompletion.year, lastCompletion.month, lastCompletion.day);
        final diff = today.difference(lastDay).inDays;

        if (diff == 0) {
          // Already counted today
        } else if (diff == 1) {
          // Consecutive day
          final newStreak = _storage.getDailyStreak() + 1;
          _storage.setDailyStreak(newStreak);
          _storage.setLastCompletionDate(today);
          dailyStreak.value = newStreak;
        } else {
          // Streak broken
          _storage.setDailyStreak(1);
          _storage.setLastCompletionDate(today);
          dailyStreak.value = 1;
        }
      }
    }
  }

  double get todayCompletionRate => totalTasksToday.value == 0
      ? 0
      : (completedTasksToday.value / totalTasksToday.value * 100);

  double get weekCompletionRate => totalTasksWeek.value == 0
      ? 0
      : (completedTasksWeek.value / totalTasksWeek.value * 100);

  String _getDayName(int index) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index % 7];
  }

  String get topCategory {
    if (weeklyTasksByCategory.isEmpty) return 'N/A';
    final sorted = weeklyTasksByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  int get maxCompletionDay {
    if (weeklyCompletionByDay.isEmpty) return 0;
    return weeklyCompletionByDay.values.reduce((a, b) => a > b ? a : b);
  }
}
