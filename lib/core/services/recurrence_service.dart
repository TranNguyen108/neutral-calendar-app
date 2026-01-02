import 'package:get/get.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class RecurrenceService extends GetxService {
  StorageService get _storage => Get.find<StorageService>();

  NotificationService get _notifications {
    if (Get.isRegistered<NotificationService>()) {
      return Get.find<NotificationService>();
    }
    throw Exception('NotificationService not initialized');
  }

  /// Generate next occurrence of a recurring task
  Task? generateNextOccurrence(Task completedTask) {
    if (completedTask.recurrenceRule == RecurrenceRule.none) {
      return null;
    }

    DateTime nextDate;
    DateTime? nextStartTime;
    DateTime? nextEndTime;

    switch (completedTask.recurrenceRule) {
      case RecurrenceRule.daily:
        nextDate = completedTask.date.add(const Duration(days: 1));
        if (completedTask.startTime != null) {
          nextStartTime = completedTask.startTime!.add(const Duration(days: 1));
        }
        if (completedTask.endTime != null) {
          nextEndTime = completedTask.endTime!.add(const Duration(days: 1));
        }
        break;

      case RecurrenceRule.weekly:
        nextDate = completedTask.date.add(const Duration(days: 7));
        if (completedTask.startTime != null) {
          nextStartTime = completedTask.startTime!.add(const Duration(days: 7));
        }
        if (completedTask.endTime != null) {
          nextEndTime = completedTask.endTime!.add(const Duration(days: 7));
        }
        break;

      case RecurrenceRule.monthly:
        nextDate = DateTime(
          completedTask.date.year,
          completedTask.date.month + 1,
          completedTask.date.day,
        );
        if (completedTask.startTime != null) {
          nextStartTime = DateTime(
            completedTask.startTime!.year,
            completedTask.startTime!.month + 1,
            completedTask.startTime!.day,
            completedTask.startTime!.hour,
            completedTask.startTime!.minute,
          );
        }
        if (completedTask.endTime != null) {
          nextEndTime = DateTime(
            completedTask.endTime!.year,
            completedTask.endTime!.month + 1,
            completedTask.endTime!.day,
            completedTask.endTime!.hour,
            completedTask.endTime!.minute,
          );
        }
        break;

      case RecurrenceRule.custom:
        // For custom, use interval in days
        final interval = completedTask.recurrenceInterval ?? 1;
        nextDate = completedTask.date.add(Duration(days: interval));
        if (completedTask.startTime != null) {
          nextStartTime =
              completedTask.startTime!.add(Duration(days: interval));
        }
        if (completedTask.endTime != null) {
          nextEndTime = completedTask.endTime!.add(Duration(days: interval));
        }
        break;

      case RecurrenceRule.none:
        return null;
    }

    // Check if recurrence should end
    if (completedTask.recurrenceEndDate != null &&
        nextDate.isAfter(completedTask.recurrenceEndDate!)) {
      return null;
    }

    // Create new task
    final now = DateTime.now();
    return Task(
      id: now.millisecondsSinceEpoch.toString(),
      title: completedTask.title,
      date: nextDate,
      startTime: nextStartTime,
      endTime: nextEndTime,
      priority: completedTask.priority,
      status: TaskStatus.todo,
      category: completedTask.category,
      note: completedTask.note,
      createdAt: now,
      updatedAt: now,
      totalFocusMinutes: 0, // Reset focus minutes for new occurrence
      recurrenceRule: completedTask.recurrenceRule,
      recurrenceInterval: completedTask.recurrenceInterval,
      recurrenceEndDate: completedTask.recurrenceEndDate,
      reminderMinutesBefore: completedTask.reminderMinutesBefore,
    );
  }

  /// Handle task completion - generate next occurrence if recurring
  Future<void> handleTaskCompletion(Task task) async {
    if (task.status == TaskStatus.done &&
        task.recurrenceRule != RecurrenceRule.none) {
      final nextTask = generateNextOccurrence(task);
      if (nextTask != null) {
        await _storage.addTask(nextTask);
        // Schedule notification for the new recurring task
        if (Get.isRegistered<NotificationService>()) {
          await _notifications.scheduleTaskReminder(nextTask);
        }
      }
    }
  }
}
