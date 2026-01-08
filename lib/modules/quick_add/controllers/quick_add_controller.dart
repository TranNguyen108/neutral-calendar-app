import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/task.dart';
import '../../../core/models/attachment.dart';
import '../../../core/services/natural_language_parser.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/attachment_service.dart';
import '../../../core/services/widget_service.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../../today/controllers/today_controller.dart';

class QuickAddController extends GetxController {
  final NaturalLanguageParser _parser = Get.find();
  final StorageService _storage = Get.find<StorageService>();
  final AttachmentService _attachmentService = Get.find<AttachmentService>();

  NotificationService get _notifications {
    if (Get.isRegistered<NotificationService>()) {
      return Get.find<NotificationService>();
    }
    throw Exception('NotificationService not initialized');
  }

  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final subtaskController = TextEditingController();
  final selectedTime = Rx<TimeOfDay?>(null);
  final selectedEndTime = Rx<TimeOfDay?>(null);
  final selectedPriority = Priority.medium.obs;
  final selectedDate = Rx<DateTime?>(null);
  final selectedCategory = 'None'.obs;
  final selectedRecurrence = RecurrenceRule.none.obs;
  final selectedReminder = Rx<int?>(null);
  final subtasks = <String>[].obs;
  final attachments = <Attachment>[].obs;

  // Default categories
  final categories = <String>[
    'None',
    ...AppConstants.defaultCategories,
  ].obs;

  @override
  void onInit() {
    super.onInit();
    // Load custom categories from storage
    _loadCategories();
    // Set default date to today
    selectedDate.value = DateTime.now();
    // Listen to title changes for parsing
    titleController.addListener(_onTitleChanged);
  }

  @override
  void onClose() {
    // Remove listener before disposal
    titleController.removeListener(_onTitleChanged);

    // Dispose controllers
    titleController.dispose();
    noteController.dispose();
    subtaskController.dispose();

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

  void addSubtask(String subtaskTitle) {
    if (subtaskTitle.trim().isNotEmpty) {
      subtasks.add(subtaskTitle.trim());
      subtaskController.clear();
    }
  }

  void removeSubtask(int index) {
    if (index >= 0 && index < subtasks.length) {
      subtasks.removeAt(index);
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
      category:
          selectedCategory.value == 'None' ? null : selectedCategory.value,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recurrenceRule: selectedRecurrence.value,
      reminderMinutesBefore: selectedReminder.value,
      attachments: attachments.toList(),
    );

    await _storage.addTask(task);

    // Add subtasks if any
    for (int i = 0; i < subtasks.length; i++) {
      final subtask = Task(
        id: '${DateTime.now().millisecondsSinceEpoch}_subtask_$i',
        title: subtasks[i],
        date: taskDate,
        priority: Priority.medium,
        status: TaskStatus.todo,
        category:
            selectedCategory.value == 'None' ? null : selectedCategory.value,
        parentTaskId: task.id,
        subtaskOrder: i,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _storage.addTask(subtask);
    }

    // Schedule notification for new task
    if (Get.isRegistered<NotificationService>()) {
      await _notifications.scheduleTaskReminder(task);
    }

    // Close bottom sheet FIRST
    Get.back();

    // Clear form
    _clearForm();

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

    // Update widget after task added
    if (Get.isRegistered<WidgetService>()) {
      Get.find<WidgetService>().updateWidget();
    }
  }

  void _clearForm() {
    titleController.clear();
    noteController.clear();
    subtaskController.clear();
    attachments.clear();
    subtasks.clear();
    selectedTime.value = null;
    selectedEndTime.value = null;
    selectedPriority.value = Priority.medium;
    selectedDate.value = DateTime.now();
    selectedCategory.value = 'None';
    selectedRecurrence.value = RecurrenceRule.none;
    selectedReminder.value = null;
  }

  // Attachment methods
  Future<void> pickImageFromGallery() async {
    final attachment = await _attachmentService.pickImageFromGallery();
    if (attachment != null) {
      attachments.add(attachment);
      Get.snackbar('success'.tr, 'image_added'.tr);
    }
  }

  Future<void> pickImageFromCamera() async {
    final attachment = await _attachmentService.pickImageFromCamera();
    if (attachment != null) {
      attachments.add(attachment);
      Get.snackbar('success'.tr, 'image_added'.tr);
    }
  }

  Future<void> pickFile() async {
    final attachment = await _attachmentService.pickFile();
    if (attachment != null) {
      attachments.add(attachment);
      Get.snackbar('success'.tr, 'file_added'.tr);
    }
  }

  void removeAttachment(Attachment attachment) {
    attachments.remove(attachment);
    _attachmentService.deleteAttachment(attachment);
  }

  void showAttachmentPicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('take_photo'.tr),
              onTap: () {
                Get.back();
                pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('choose_gallery'.tr),
              onTap: () {
                Get.back();
                pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text('choose_file'.tr),
              onTap: () {
                Get.back();
                pickFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text('add_link'.tr),
              onTap: () {
                Get.back();
                _showAddLinkDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLinkDialog() {
    final linkController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('add_link'.tr),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              if (linkController.text.trim().isNotEmpty) {
                // Create a text attachment with the link
                final attachment = Attachment(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  fileName: linkController.text.trim(),
                  filePath: linkController.text.trim(),
                  type: AttachmentType.other,
                  fileSizeBytes: 0,
                );
                attachments.add(attachment);
                Get.back();
                Get.snackbar('success'.tr, 'link_added'.tr);
              }
            },
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }
}
