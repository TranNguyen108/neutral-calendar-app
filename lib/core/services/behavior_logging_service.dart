import 'package:get/get.dart';
import '../models/user_behavior.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

class BehaviorLoggingService extends GetxService {
  StorageService get _storage => Get.find<StorageService>();

  // Log task completion with time tracking
  Future<void> logTaskCompletion(Task task) async {
    final log = UserBehaviorLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: BehaviorType.taskCompleted,
      data: {
        'taskId': task.id,
        'category': task.category,
        'priority': task.priority.name,
        'completionTime': _calculateCompletionTime(task),
        'wasOverdue': task.isOverdue,
      },
    );
    await _saveBehaviorLog(log);
  }

  // Log task delay
  Future<void> logTaskDelay(Task task, int delayMinutes) async {
    final log = UserBehaviorLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: BehaviorType.taskDelayed,
      data: {
        'taskId': task.id,
        'delayMinutes': delayMinutes,
        'priority': task.priority.name,
      },
    );
    await _saveBehaviorLog(log);
  }

  // Log task reschedule
  Future<void> logTaskReschedule(Task task, DateTime newDate) async {
    final log = UserBehaviorLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: BehaviorType.taskRescheduled,
      data: {
        'taskId': task.id,
        'originalDate': task.date.toIso8601String(),
        'newDate': newDate.toIso8601String(),
        'daysDiff': newDate.difference(task.date).inDays,
      },
    );
    await _saveBehaviorLog(log);
  }

  // Log focus session completion
  Future<void> logFocusSession(int durationMinutes, bool completed) async {
    final log = UserBehaviorLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: completed
          ? BehaviorType.focusSessionCompleted
          : BehaviorType.focusSessionSkipped,
      data: {
        'durationMinutes': durationMinutes,
        'hour': DateTime.now().hour,
      },
    );
    await _saveBehaviorLog(log);
  }

  // Calculate completion time (from creation to done)
  double _calculateCompletionTime(Task task) {
    final completionTime = DateTime.now().difference(task.createdAt);
    return completionTime.inHours.toDouble();
  }

  Future<void> _saveBehaviorLog(UserBehaviorLog log) async {
    final logs = _getBehaviorLogs();
    logs.add(log);

    // Keep only last 1000 logs to avoid bloat
    if (logs.length > 1000) {
      logs.removeRange(0, logs.length - 1000);
    }

    await _storage.saveBehaviorLogs(logs.map((l) => l.toJson()).toList());
  }

  List<UserBehaviorLog> _getBehaviorLogs() {
    final logsJson = _storage.getBehaviorLogs();
    return logsJson.map((json) => UserBehaviorLog.fromJson(json)).toList();
  }

  // Calculate behavior statistics
  BehaviorStats calculateStats({int? lastDays}) {
    final logs = _getBehaviorLogs();
    final now = DateTime.now();

    final filteredLogs = lastDays != null
        ? logs
            .where((l) => now.difference(l.timestamp).inDays <= lastDays)
            .toList()
        : logs;

    final completedTasks = filteredLogs
        .where((l) => l.type == BehaviorType.taskCompleted)
        .toList();

    final delays =
        filteredLogs.where((l) => l.type == BehaviorType.taskDelayed).length;

    final reschedules = filteredLogs
        .where((l) => l.type == BehaviorType.taskRescheduled)
        .length;

    final focusSessions = filteredLogs
        .where((l) => l.type == BehaviorType.focusSessionCompleted)
        .length;

    // Calculate average completion time
    final completionTimes = completedTasks
        .map((l) => l.data['completionTime'] as double? ?? 0)
        .where((t) => t > 0)
        .toList();
    final avgCompletionTime = completionTimes.isEmpty
        ? 0.0
        : completionTimes.reduce((a, b) => a + b) / completionTimes.length;

    // Calculate tasks per day
    final daysSpan = lastDays ?? 30;
    final avgTasksPerDay = completedTasks.length / daysSpan;

    // Find productive hours
    final hourFrequency = <int, int>{};
    for (var log in completedTasks) {
      final hour = log.timestamp.hour;
      hourFrequency[hour] = (hourFrequency[hour] ?? 0) + 1;
    }
    final productiveHours = hourFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topHours = productiveHours.take(3).map((e) => e.key).toList();

    // Category frequency
    final categoryFreq = <String, int>{};
    for (var log in completedTasks) {
      final category = log.data['category'] as String?;
      if (category != null) {
        categoryFreq[category] = (categoryFreq[category] ?? 0) + 1;
      }
    }

    return BehaviorStats(
      totalTasksCompleted: completedTasks.length,
      totalDelays: delays,
      totalReschedules: reschedules,
      totalFocusSessions: focusSessions,
      avgCompletionTime: avgCompletionTime,
      avgTasksPerDay: avgTasksPerDay,
      productiveHours: topHours,
      categoryFrequency: categoryFreq,
    );
  }

  // Get insights based on behavior
  List<String> getInsights() {
    final stats = calculateStats(lastDays: 30);
    final insights = <String>[];

    if (stats.delayFrequency > 0.3) {
      insights.add('insight_frequent_delays');
    }

    if (stats.rescheduleFrequency > 0.4) {
      insights.add('insight_frequent_reschedules');
    }

    if (stats.avgTasksPerDay < 1) {
      insights.add('insight_low_task_completion');
    }

    if (stats.totalFocusSessions < 5) {
      insights.add('insight_low_focus_usage');
    }

    if (stats.productiveHours.isNotEmpty) {
      insights.add('insight_productive_hours');
    }

    return insights;
  }
}
