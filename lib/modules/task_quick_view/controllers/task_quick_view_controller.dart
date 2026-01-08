import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../today/controllers/today_controller.dart';
import '../../calendar/controllers/calendar_controller.dart';

class TaskQuickViewController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  late Task task;

  final selectedReminder = Rx<int?>(null);
  final selectedRecurrence = RecurrenceRule.none.obs;
  final selectedPriority = Priority.medium.obs;
  final noteController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    task = Get.arguments as Task;
    selectedReminder.value = task.reminderMinutesBefore;
    selectedRecurrence.value = task.recurrenceRule;
    selectedPriority.value = task.priority;
    noteController.text = task.note ?? '';
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  Future<void> updateTask() async {
    final updatedTask = task.copyWith(
      reminderMinutesBefore: selectedReminder.value,
      recurrenceRule: selectedRecurrence.value,
      priority: selectedPriority.value,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await _storage.updateTask(updatedTask);

    // Update notifications
    if (Get.isRegistered<NotificationService>()) {
      final notificationService = Get.find<NotificationService>();
      await notificationService.scheduleTaskReminder(updatedTask);
    }

    // Refresh lists
    if (Get.isRegistered<TodayController>()) {
      Get.find<TodayController>().loadTodayTasks();
    }
    if (Get.isRegistered<CalendarController>()) {
      Get.find<CalendarController>().loadTasks();
    }

    Get.back();
    Get.snackbar('success'.tr, 'task_updated'.tr);
  }

  Future<void> toggleStatus() async {
    final updatedTask = task.copyWith(
      status:
          task.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done,
      updatedAt: DateTime.now(),
    );
    await _storage.updateTask(updatedTask);
    task = updatedTask;
    update();

    if (Get.isRegistered<TodayController>()) {
      Get.find<TodayController>().loadTodayTasks();
    }
  }

  Future<void> deleteTask() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_task'.tr),
        content: Text('delete_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteTask(task.id);
      Get.back(); // Close the quick view
      Get.snackbar('success'.tr, 'task_deleted'.tr);

      if (Get.isRegistered<TodayController>()) {
        Get.find<TodayController>().loadTodayTasks();
      }
    }
  }
}
