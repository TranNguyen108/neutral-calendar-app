import 'package:get/get.dart';
import '../../../core/models/task.dart';
import '../../../core/models/focus_session.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/services/behavior_logging_service.dart';

class FocusController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AchievementService _achievements = Get.find<AchievementService>();
  final BehaviorLoggingService _behavior = Get.find<BehaviorLoggingService>();

  final remainingSeconds = 1500.obs; // 25 minutes in seconds
  final isRunning = false.obs;
  final selectedTask = Rx<Task?>(null);
  final todayTasks = <Task>[].obs;

  DateTime? sessionStartTime;
  String? currentSessionId;

  @override
  void onInit() {
    super.onInit();
    loadTodayTasks();
  }

  void loadTodayTasks() {
    final allTasks = _storage.getTasks();
    final today = DateTime.now();
    todayTasks.value = allTasks.where((task) {
      return task.date.year == today.year &&
          task.date.month == today.month &&
          task.date.day == today.day &&
          task.status != TaskStatus.done;
    }).toList();
  }

  void selectTask(Task? task) {
    selectedTask.value = task;
  }

  void startTimer() {
    if (sessionStartTime == null) {
      sessionStartTime = DateTime.now();
      currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    }
    isRunning.value = true;
    _runTimer();
  }

  void pauseTimer() {
    isRunning.value = false;
  }

  Future<void> resetTimer() async {
    if (sessionStartTime != null && remainingSeconds.value < 1500) {
      // Save incomplete session
      await _saveFocusSession(completed: false);
    }

    isRunning.value = false;
    remainingSeconds.value = 1500;
    sessionStartTime = null;
    currentSessionId = null;
  }

  void _runTimer() {
    if (isRunning.value && remainingSeconds.value > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        remainingSeconds.value--;
        _runTimer();
      });
    } else if (remainingSeconds.value == 0) {
      isRunning.value = false;
      _onTimerCompleted();
    }
  }

  Future<void> _onTimerCompleted() async {
    // Save completed session
    await _saveFocusSession(completed: true);

    // Update focus achievements
    await _achievements.updateFocusAchievements();

    // Log focus session completion
    await _behavior.logFocusSession(25, true);

    Get.snackbar(
      'success'.tr,
      'focus_completed'.tr,
      duration: const Duration(seconds: 3),
    );

    // Reset for next session
    remainingSeconds.value = 1500;
    sessionStartTime = null;
    currentSessionId = null;
  }

  Future<void> _saveFocusSession({required bool completed}) async {
    if (sessionStartTime == null || currentSessionId == null) return;

    final endTime = DateTime.now();
    final actualMinutes = ((1500 - remainingSeconds.value) / 60).ceil();

    final session = FocusSession(
      id: currentSessionId!,
      taskId: selectedTask.value?.id,
      startTime: sessionStartTime!,
      endTime: endTime,
      durationMinutes: actualMinutes,
      completed: completed,
    );

    await _storage.addFocusSession(session);

    // Update task's total focus time
    if (selectedTask.value != null && completed) {
      final task = selectedTask.value!;
      final updatedTask = task.copyWith(
        totalFocusMinutes: task.totalFocusMinutes + 25,
        updatedAt: DateTime.now(),
      );
      await _storage.updateTask(updatedTask);

      // Reload tasks
      loadTodayTasks();
    }
  }

  String getFormattedTime() {
    final minutes = remainingSeconds.value ~/ 60;
    final seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
