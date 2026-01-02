import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/recurrence_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/services/daily_summary_service.dart';
import '../../../core/services/behavior_logging_service.dart';

class TodayController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final RecurrenceService _recurrence = Get.find<RecurrenceService>();
  final AchievementService _achievements = Get.find<AchievementService>();
  final DailySummaryService _dailySummary = Get.find<DailySummaryService>();
  final BehaviorLoggingService _behavior = Get.find<BehaviorLoggingService>();

  NotificationService get _notifications {
    if (Get.isRegistered<NotificationService>()) {
      return Get.find<NotificationService>();
    }
    throw Exception('NotificationService not initialized');
  }

  final tasks = <Task>[].obs;
  final urgentTasks = <Task>[].obs;
  final selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadTodayTasks();
    _checkDailySummary();
  }

  Future<void> _checkDailySummary() async {
    // Check and show end-of-day summary if needed
    await _dailySummary.checkAndShowSummary();
  }

  void loadTodayTasks() {
    final allTasks = _storage.getTasks();
    final today = DateTime.now();
    tasks.value = allTasks.where((task) {
      return task.date.year == today.year &&
          task.date.month == today.month &&
          task.date.day == today.day;
    }).toList();

    // Sort tasks: Overdue first, then by priority, then by time
    tasks.sort((a, b) {
      // Overdue tasks first
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;

      // Then by priority (high to low)
      if (a.priority != b.priority) {
        return b.priority.index - a.priority.index;
      }

      // Then by time
      if (a.startTime == null && b.startTime == null) return 0;
      if (a.startTime == null) return 1;
      if (b.startTime == null) return -1;
      return a.startTime!.compareTo(b.startTime!);
    });

    _loadUrgentTasks();
  }

  void _loadUrgentTasks() {
    final now = DateTime.now();
    urgentTasks.value = tasks
        .where((task) {
          if (task.status == TaskStatus.done) return false;

          // High priority tasks
          if (task.priority == Priority.high) return true;

          // Overdue tasks
          if (task.isOverdue) return true;

          // Tasks starting within next 2 hours
          if (task.startTime != null) {
            final diff = task.startTime!.difference(now);
            if (diff.inMinutes > 0 && diff.inMinutes <= 120) return true;
          }

          return false;
        })
        .take(3)
        .toList();
  }

  int get totalTasks => tasks.length;
  int get completedTasks =>
      tasks.where((t) => t.status == TaskStatus.done).length;
  double get progressPercentage =>
      totalTasks == 0 ? 0 : (completedTasks / totalTasks * 100);

  Future<void> toggleTaskStatus(Task task) async {
    final updatedTask = task.copyWith(
      status:
          task.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done,
      updatedAt: DateTime.now(),
    );
    await _storage.updateTask(updatedTask);

    // Generate next occurrence if marking as done and task is recurring
    if (updatedTask.status == TaskStatus.done) {
      await _recurrence.handleTaskCompletion(updatedTask);

      // Log task completion
      await _behavior.logTaskCompletion(updatedTask);

      // Update achievements and streak
      await _achievements.updateTaskAchievements();
      await _dailySummary.updateDailyStreak();
    }

    loadTodayTasks();
  }

  Future<void> deleteTask(Task task) async {
    await _storage.deleteTask(task.id);
    // Cancel notification when deleting task
    if (Get.isRegistered<NotificationService>()) {
      await _notifications.cancelTaskReminder(task.id);
    }
    loadTodayTasks();
  }

  Future<void> rescheduleToTomorrow(Task task) async {
    final tomorrow = task.date.add(const Duration(days: 1));
    final updatedTask = task.copyWith(
      date: tomorrow,
      startTime: task.startTime != null
          ? DateTime(tomorrow.year, tomorrow.month, tomorrow.day,
              task.startTime!.hour, task.startTime!.minute)
          : null,
      endTime: task.endTime != null
          ? DateTime(tomorrow.year, tomorrow.month, tomorrow.day,
              task.endTime!.hour, task.endTime!.minute)
          : null,
      updatedAt: DateTime.now(),
    );
    await _storage.updateTask(updatedTask);

    // Log reschedule behavior
    await _behavior.logTaskReschedule(task, tomorrow);

    loadTodayTasks();
    Get.snackbar('success'.tr, 'Task rescheduled to tomorrow');
  }

  Future<void> delayOneHour(Task task) async {
    if (task.startTime == null) {
      Get.snackbar('error'.tr, 'Task has no start time');
      return;
    }

    final newStart = task.startTime!.add(const Duration(hours: 1));
    final newEnd = task.endTime?.add(const Duration(hours: 1));

    final updatedTask = task.copyWith(
      startTime: newStart,
      endTime: newEnd,
      updatedAt: DateTime.now(),
    );
    await _storage.updateTask(updatedTask);

    // Log delay behavior
    await _behavior.logTaskDelay(task, 60);

    loadTodayTasks();
    Get.snackbar('success'.tr, 'Task delayed by 1 hour');
  }

  String getFormattedDate() {
    return DateFormat('EEEE, MMMM d').format(selectedDate.value);
  }
}
