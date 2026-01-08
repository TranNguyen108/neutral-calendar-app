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

    // Calculate days to add based on recurrence rule
    final daysToAdd = _calculateDaysToAdd(completedTask);
    if (daysToAdd == null) return null;

    // Calculate next dates
    final nextDate = _addDaysToDate(completedTask.date, daysToAdd);
    final nextStartTime = completedTask.startTime != null
        ? _addDaysToDate(completedTask.startTime!, daysToAdd)
        : null;
    final nextEndTime = completedTask.endTime != null
        ? _addDaysToDate(completedTask.endTime!, daysToAdd)
        : null;

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
      projectId: completedTask.projectId,
      sectionId: completedTask.sectionId,
      note: completedTask.note,
      createdAt: now,
      updatedAt: now,
      totalFocusMinutes: 0,
      recurrenceRule: completedTask.recurrenceRule,
      recurrenceInterval: completedTask.recurrenceInterval,
      recurrenceEndDate: completedTask.recurrenceEndDate,
      reminderMinutesBefore: completedTask.reminderMinutesBefore,
    );
  }

  /// Calculate days to add for recurrence rule
  int? _calculateDaysToAdd(Task task) {
    switch (task.recurrenceRule) {
      case RecurrenceRule.daily:
        return 1;
      case RecurrenceRule.weekly:
        return 7;
      case RecurrenceRule.monthly:
        return null; // Monthly is special case
      case RecurrenceRule.custom:
        return task.recurrenceInterval ?? 1;
      case RecurrenceRule.none:
        return null;
    }
  }

  /// Add days to a DateTime
  DateTime _addDaysToDate(DateTime date, int? days) {
    if (days == null) {
      // Monthly recurrence
      return DateTime(
        date.year,
        date.month + 1,
        date.day,
        date.hour,
        date.minute,
        date.second,
      );
    }
    return date.add(Duration(days: days));
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
