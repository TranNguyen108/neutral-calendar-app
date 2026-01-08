import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/task.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/services/behavior_logging_service.dart';
import '../../../core/services/daily_summary_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/recurrence_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/widget_service.dart';
import '../../../core/utils/task_filters.dart';

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

  // All today's tasks (full dataset)
  final _allTodayTasks = <Task>[];

  // Paginated visible tasks
  final tasks = <Task>[].obs;
  final urgentTasks = <Task>[].obs;
  final selectedDate = DateTime.now().obs;

  // Pagination state
  static const int _pageSize = 30;
  final currentPage = 0.obs;
  final isLoadingMore = false.obs;
  final hasMoreTasks = true.obs;

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

    // Use extension methods for clean filtering and sorting
    _allTodayTasks.clear();
    _allTodayTasks.addAll(allTasks.forToday().sortedByUrgency());

    // Reset pagination
    currentPage.value = 0;
    hasMoreTasks.value = _allTodayTasks.length > _pageSize;

    // Load first page
    final endIndex = _pageSize.clamp(0, _allTodayTasks.length);
    tasks.value = _allTodayTasks.sublist(0, endIndex);

    // Load urgent tasks using the extension method
    urgentTasks.value = allTasks.urgent(limit: 3);
  }

  /// Load more tasks for pagination (lazy loading)
  void loadMoreTasks() {
    if (isLoadingMore.value || !hasMoreTasks.value) return;

    isLoadingMore.value = true;

    // Simulate slight delay for smooth UX (optional)
    Future.delayed(const Duration(milliseconds: 100), () {
      final nextPage = currentPage.value + 1;
      final startIndex = nextPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, _allTodayTasks.length);

      if (startIndex < _allTodayTasks.length) {
        // Add next batch to visible tasks
        final newBatch = _allTodayTasks.sublist(startIndex, endIndex);
        tasks.addAll(newBatch);
        currentPage.value = nextPage;

        // Check if there are more tasks
        hasMoreTasks.value = endIndex < _allTodayTasks.length;
      } else {
        hasMoreTasks.value = false;
      }

      isLoadingMore.value = false;
    });
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

    // Update widget after task status change
    if (Get.isRegistered<WidgetService>()) {
      Get.find<WidgetService>().updateWidget();
    }
  }

  Future<void> deleteTask(Task task) async {
    await _storage.deleteTask(task.id);
    // Cancel notification when deleting task
    if (Get.isRegistered<NotificationService>()) {
      await _notifications.cancelTaskReminder(task.id);
    }
    loadTodayTasks();

    // Update widget after task deletion
    if (Get.isRegistered<WidgetService>()) {
      Get.find<WidgetService>().updateWidget();
    }
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
