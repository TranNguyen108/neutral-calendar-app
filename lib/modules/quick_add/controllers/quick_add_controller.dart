import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/natural_language_parser.dart';
import '../../today/controllers/today_controller.dart';
import '../../calendar/controllers/calendar_controller.dart';

class QuickAddController extends GetxController {
  final NaturalLanguageParser _parser = Get.find();
  final titleController = TextEditingController();
  final selectedTime = Rx<TimeOfDay?>(null);
  final selectedPriority = Priority.medium.obs;
  final selectedDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    // Listen to title changes and parse input
    titleController.addListener(_onTitleChanged);
  }

  @override
  void onClose() {
    titleController.removeListener(_onTitleChanged);
    titleController.dispose();
    super.onClose();
  }

  void _onTitleChanged() {
    if (titleController.text.isEmpty) return;

    // Parse natural language input
    final parsed = _parser.parseInput(titleController.text);

    // Auto-fill parsed values
    if (parsed.date != null && selectedDate.value == null) {
      selectedDate.value = parsed.date;
    }

    if (parsed.startTime != null && selectedTime.value == null) {
      selectedTime.value = TimeOfDay.fromDateTime(parsed.startTime!);
    }

    if (parsed.priority != Priority.medium &&
        selectedPriority.value == Priority.medium) {
      selectedPriority.value = parsed.priority;
    }

    // Update title to cleaned version if different
    if (parsed.title.isNotEmpty && parsed.title != titleController.text) {
      final cursorPos = titleController.selection.baseOffset;
      titleController.value = titleController.value.copyWith(
        text: parsed.title,
        selection: TextSelection.collapsed(
          offset: cursorPos.clamp(0, parsed.title.length),
        ),
      );
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      selectedTime.value = time;
    }
  }

  Future<void> saveQuickTask() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'enter_title_error'.tr);
      return;
    }

    // Use selectedDate if set from parsing, otherwise use today
    final taskDate = selectedDate.value ?? DateTime.now();
    DateTime? startDateTime;

    if (selectedTime.value != null) {
      startDateTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        selectedTime.value!.hour,
        selectedTime.value!.minute,
      );
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      date: taskDate,
      startTime: startDateTime,
      endTime: startDateTime
          ?.add(const Duration(hours: 1)), // Default 1 hour duration
      priority: selectedPriority.value,
      status: TaskStatus.todo,
      category: 'Work', // Default category
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final storage = Get.find<StorageService>();
    await storage.addTask(task);

    Get.back();
    Get.snackbar('success'.tr, 'task_added'.tr);

    // Reload today tasks if TodayController exists
    if (Get.isRegistered<TodayController>()) {
      Get.find<TodayController>().loadTodayTasks();
    }
    // Reload calendar if CalendarController exists
    if (Get.isRegistered<CalendarController>()) {
      Get.find<CalendarController>().loadTasks();
    }
  }
}
