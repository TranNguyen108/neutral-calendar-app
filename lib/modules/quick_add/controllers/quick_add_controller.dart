import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/task.dart';
import '../../../core/models/project.dart';
import '../../../core/repositories/project_repository.dart';
import '../../../core/services/natural_language_parser.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../../today/controllers/today_controller.dart';

class QuickAddController extends GetxController {
  final NaturalLanguageParser _parser = Get.find();
  final StorageService _storage = Get.find<StorageService>();
  final ProjectRepository _projectRepo = Get.find<ProjectRepository>();

  NotificationService get _notifications {
    if (Get.isRegistered<NotificationService>()) {
      return Get.find<NotificationService>();
    }
    throw Exception('NotificationService not initialized');
  }

  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final selectedTime = Rx<TimeOfDay?>(null);
  final selectedEndTime = Rx<TimeOfDay?>(null);
  final selectedPriority = Priority.medium.obs;
  final selectedDate = Rx<DateTime?>(null);
  final selectedCategory = 'Work'.obs;
  final selectedRecurrence = RecurrenceRule.none.obs;
  final selectedReminder = Rx<int?>(null);
  final selectedProject = Rx<Project?>(null);
  final projects = <Project>[].obs;

  // Default categories
  final categories = <String>[
    ...AppConstants.defaultCategories,
  ].obs;

  @override
  void onInit() {
    super.onInit();
    // Load custom categories from storage
    _loadCategories();
    // Load projects
    _loadProjects();
    // Set default date to today
    selectedDate.value = DateTime.now();
    // Listen to title changes for parsing
    titleController.addListener(_onTitleChanged);
  }

  void _loadProjects() {
    projects.value = _projectRepo.getProjects(includeArchived: false);
    // Set Inbox as default if exists
    final inbox = projects.firstWhereOrNull((p) => p.isInbox);
    if (inbox != null) {
      selectedProject.value = inbox;
    }
  }

  @override
  void onClose() {
    // Remove listener before disposal
    titleController.removeListener(_onTitleChanged);

    // Dispose controllers
    titleController.dispose();
    noteController.dispose();

    super.onClose();
  }

  void _loadCategories() {
    final savedCategories =
        _storage.read<List>(AppConstants.customCategoriesKey);
    if (savedCategories != null) {
      categories.addAll(savedCategories.map((e) => e.toString()));
    }
  }

  Future<void> addCategory(String category) async {
    if (!categories.contains(category)) {
      categories.add(category);
      // Save to storage (skip default categories)
      await _storage.write(
        AppConstants.customCategoriesKey,
        categories.sublist(AppConstants.defaultCategories.length).toList(),
      );
      selectedCategory.value = category;
    }
  }

  void _onTitleChanged() {
    if (titleController.text.isEmpty) return;

    // Parse natural language input
    final parsed = _parser.parseInput(titleController.text);

    // Auto-fill parsed date
    if (parsed.date != null) {
      selectedDate.value = parsed.date;
    }

    // Auto-fill parsed start time
    if (parsed.startTime != null) {
      selectedTime.value = TimeOfDay.fromDateTime(parsed.startTime!);
    }

    // Auto-fill parsed end time
    if (parsed.endTime != null) {
      selectedEndTime.value = TimeOfDay.fromDateTime(parsed.endTime!);
    }

    // Auto-fill parsed priority
    if (parsed.priority != Priority.medium &&
        selectedPriority.value == Priority.medium) {
      selectedPriority.value = parsed.priority;
    }
  }

  void setDate(DateTime date) {
    selectedDate.value = date;
  }

  Future<void> pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      selectedDate.value = date;
    }
  }

  Future<void> pickStartTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? TimeOfDay.now(),
    );
    if (time != null) {
      selectedTime.value = time;
    }
  }

  Future<void> pickEndTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedEndTime.value ??
          TimeOfDay.fromDateTime(
            DateTime.now().add(const Duration(hours: 1)),
          ),
    );
    if (time != null) {
      selectedEndTime.value = time;
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
    DateTime? endDateTime;

    if (selectedTime.value != null) {
      startDateTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        selectedTime.value!.hour,
        selectedTime.value!.minute,
      );
    }

    if (selectedEndTime.value != null) {
      endDateTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        selectedEndTime.value!.hour,
        selectedEndTime.value!.minute,
      );
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      date: taskDate,
      startTime: startDateTime,
      endTime: endDateTime,
      priority: selectedPriority.value,
      status: TaskStatus.todo,
      category: selectedCategory.value,
      projectId: selectedProject.value?.id,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recurrenceRule: selectedRecurrence.value,
      reminderMinutesBefore: selectedReminder.value,
    );

    await _storage.addTask(task);

    // Schedule notification for new task
    if (Get.isRegistered<NotificationService>()) {
      await _notifications.scheduleTaskReminder(task);
    }

    // Close bottom sheet FIRST
    Get.back();

    // Then show success message
    Get.snackbar(
      'success'.tr,
      'task_added'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
    );

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
