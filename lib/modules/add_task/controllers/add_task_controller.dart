import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../today/controllers/today_controller.dart';
import '../../calendar/controllers/calendar_controller.dart';

class AddTaskController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final NotificationService _notifications = Get.find<NotificationService>();

  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final selectedDate = DateTime.now().obs;
  final selectedStartTime = Rx<TimeOfDay?>(null);
  final selectedEndTime = Rx<TimeOfDay?>(null);
  final selectedPriority = Priority.medium.obs;
  final selectedCategory = Rx<String?>('Work');
  final selectedRecurrence = RecurrenceRule.none.obs;
  final selectedReminder = Rx<int?>(null);

  final isEditing = false.obs;
  Task? editingTask;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Task) {
      editingTask = Get.arguments as Task;
      isEditing.value = true;
      _loadTaskData();
    }
  }

  void _loadTaskData() {
    if (editingTask != null) {
      titleController.text = editingTask!.title;
      noteController.text = editingTask!.note ?? '';
      selectedDate.value = editingTask!.date;
      if (editingTask!.startTime != null) {
        selectedStartTime.value =
            TimeOfDay.fromDateTime(editingTask!.startTime!);
      }
      if (editingTask!.endTime != null) {
        selectedEndTime.value = TimeOfDay.fromDateTime(editingTask!.endTime!);
      }
      selectedPriority.value = editingTask!.priority;
      selectedCategory.value = editingTask!.category;
      selectedRecurrence.value = editingTask!.recurrenceRule;
      selectedReminder.value = editingTask!.reminderMinutesBefore;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      selectedDate.value = date;
    }
  }

  Future<void> pickStartTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedStartTime.value ?? TimeOfDay.now(),
    );
    if (time != null) {
      selectedStartTime.value = time;
    }
  }

  Future<void> pickEndTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedEndTime.value ?? TimeOfDay.now(),
    );
    if (time != null) {
      selectedEndTime.value = time;
    }
  }

  Future<void> saveTask() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'enter_title_error'.tr);
      return;
    }

    DateTime? startDateTime;
    DateTime? endDateTime;

    if (selectedStartTime.value != null) {
      startDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        selectedStartTime.value!.hour,
        selectedStartTime.value!.minute,
      );
    }

    if (selectedEndTime.value != null) {
      endDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        selectedEndTime.value!.hour,
        selectedEndTime.value!.minute,
      );
    }

    final task = Task(
      id: isEditing.value
          ? editingTask!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      date: selectedDate.value,
      startTime: startDateTime,
      endTime: endDateTime,
      priority: selectedPriority.value,
      status: isEditing.value ? editingTask!.status : TaskStatus.todo,
      category: selectedCategory.value,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      createdAt: isEditing.value ? editingTask!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      recurrenceRule: selectedRecurrence.value,
      reminderMinutesBefore: selectedReminder.value,
    );

    if (isEditing.value) {
      await _storage.updateTask(task);
      // Cancel old notification and schedule new one
      await _notifications.cancelTaskReminder(task.id);
      await _notifications.scheduleTaskReminder(task);
      Get.snackbar('success'.tr, 'task_updated'.tr);
    } else {
      await _storage.addTask(task);
      // Schedule notification for new task
      await _notifications.scheduleTaskReminder(task);
      Get.snackbar('success'.tr, 'task_added'.tr);
    }

    Get.back();

    // Reload today tasks if TodayController exists
    if (Get.isRegistered<TodayController>()) {
      Get.find<TodayController>().loadTodayTasks();
    }
    // Reload calendar if CalendarController exists
    if (Get.isRegistered<CalendarController>()) {
      Get.find<CalendarController>().loadTasks();
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
