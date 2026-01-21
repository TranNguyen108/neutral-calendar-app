import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/note.dart';
import '../../../core/models/diary.dart';
import '../../../core/models/event.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/daily_mood.dart'; // NEW: Daily mood model
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/mood_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/attachment_service.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../../manage/controllers/manage_controller.dart';

class AddItemController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AttachmentService _attachmentService = Get.find<AttachmentService>();

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final descriptionController = TextEditingController();

  final selectedCategory = 'None'.obs;
  final selectedDate = DateTime.now().obs;
  final selectedTime = Rx<TimeOfDay?>(null);
  final showTime = false.obs;
  final hasNotification = true.obs;
  final isRecurring = false.obs;
  final reminderMinutesBefore = Rx<int?>(15);
  final attachments = <Attachment>[].obs;

  // Diary specific
  final isDiaryPinned = false.obs;
  final selectedMood = Rx<String?>(MoodConstants.normal);

  final categories = <String>[
    'None',
    ...AppConstants.defaultCategories,
  ].obs;

  void addNewCategory(String categoryName) {
    final trimmed = categoryName.trim();
    if (trimmed.isNotEmpty && !categories.contains(trimmed)) {
      categories.add(trimmed);
      selectedCategory.value = trimmed;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      selectedDate.value = date;
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? TimeOfDay.now(),
    );
    if (time != null) {
      selectedTime.value = time;
    }
  }

  void toggleDiaryPin() {
    isDiaryPinned.value = !isDiaryPinned.value;
  }

  void setMood(String mood) {
    selectedMood.value = mood;
  }

  Future<void> saveNote() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'enter_title_error'.tr);
      return;
    }

    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      content: contentController.text.trim(),
      category:
          selectedCategory.value == 'None' ? null : selectedCategory.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.addNote(note);

    // Refresh ManageController nếu đang mở
    try {
      if (Get.isRegistered<ManageController>()) {
        Get.find<ManageController>().loadData();
      }
    } catch (e) {
      // Ignore if ManageController is not registered
    }

    Get.back();
    _clearForm();
  }

  Future<void> saveDiary() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'enter_title_error'.tr);
      return;
    }

    DateTime diaryDate = selectedDate.value;
    if (showTime.value && selectedTime.value != null) {
      diaryDate = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        selectedTime.value!.hour,
        selectedTime.value!.minute,
      );
    }

    final diary = Diary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      content: contentController.text.trim(),
      date: diaryDate,
      showTime: showTime.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      attachments: attachments.toList(),
      isPinned: isDiaryPinned.value,
      mood: selectedMood.value,
      backgroundColor: MoodConstants.getColorForMood(selectedMood.value),
    );

    await _storage.addDiary(diary);

    // === NEW: Mood Change Detection & Prompt Logic ===
    // After saving diary, check if we should prompt for daily mood
    await _checkAndPromptForDailyMood(diary);

    // Refresh ManageController nếu đang mở
    try {
      if (Get.isRegistered<ManageController>()) {
        Get.find<ManageController>().loadData();
      }
    } catch (e) {
      // Ignore if ManageController is not registered
    }

    Get.back();
    _clearForm();
  }

  /// === NEW: Mood Change Detection Logic ===
  /// Checks if we should prompt user to set daily mood
  ///
  /// Conditions for prompting:
  /// 1. Haven't prompted today yet
  /// 2. New diary has different mood compared to any existing diary today
  /// 3. There's a significant mood change (difference >= 2)
  Future<void> _checkAndPromptForDailyMood(Diary newDiary) async {
    try {
      // Check if already prompted today
      final hasPrompted = _storage.hasBeenPromptedToday();
      if (hasPrompted) {
        return; // Don't prompt again
      }

      // Get all diaries for today
      final today = newDiary.date;
      final todayDiaries = _storage.getDiariesForDate(today);

      // Need at least 2 diaries (including the new one)
      if (todayDiaries.length < 2) {
        return;
      }

      // Compare new diary mood with the most recent previous diary
      // (todayDiaries is sorted oldest first, so second-to-last is the previous one)
      final previousDiary = todayDiaries[todayDiaries.length - 2];

      // Check for significant mood change
      final isSignificant = MoodConstants.isSignificantMoodChange(
        previousDiary.mood,
        newDiary.mood,
      );

      if (isSignificant) {
        // Show non-blocking prompt right away
        // NOTE: Mark as prompted AFTER user responds, not before
        _showDailyMoodPrompt(todayDiaries);
      }
    } catch (e) {
      // Silent fail - don't interrupt user flow if mood detection fails
    }
  }

  /// === NEW: Show Daily Mood Prompt ===
  /// Non-blocking dialog that lets user choose or skip
  void _showDailyMoodPrompt(List<Diary> todayDiaries) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_emotions, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'How are you feeling today?',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your mood has changed throughout the day. Would you like to set an overall mood for today?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose your daily mood:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 12),
            // Mood selector buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MoodConstants.allMoods.map((mood) {
                return InkWell(
                  onTap: () async {
                    await _storage.markPromptedToday(); // Mark first
                    Get.back(); // Close dialog
                    _saveDailyMood(mood, isUserConfirmed: true);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:
                          MoodConstants.getColorForMood(mood).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MoodConstants.getColorForMood(mood),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          MoodConstants.getEmojiForMood(mood),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MoodConstants.getLabelForMood(mood).split(' ').first,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _storage.markPromptedToday(); // Mark first
              Get.back(); // Close dialog
              // Don't save daily mood, system will use automatic fallback
              _saveDailyMoodAutomatic(todayDiaries);
            },
            child: Text(
              'Skip',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      barrierDismissible: true, // Allow dismissing by tapping outside
    );
  }

  /// Save user-confirmed daily mood
  Future<void> _saveDailyMood(String mood,
      {required bool isUserConfirmed}) async {
    try {
      final dailyMood = DailyMood.create(
        date: DateTime.now(),
        mood: mood,
        isUserConfirmed: isUserConfirmed,
      );

      await _storage.setDailyMood(dailyMood);

      if (isUserConfirmed) {
        Get.snackbar(
          'Daily Mood Set',
          'Your mood for today has been recorded as ${MoodConstants.getLabelForMood(mood)}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: MoodConstants.getColorForMood(mood).withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Error saving daily mood
    }
  }

  /// Automatic fallback: use the latest diary mood as daily mood
  Future<void> _saveDailyMoodAutomatic(List<Diary> todayDiaries) async {
    if (todayDiaries.isEmpty) return;

    // Use the most recent diary's mood
    final latestMood = todayDiaries.last.mood;
    await _saveDailyMood(
      latestMood ?? MoodConstants.normal,
      isUserConfirmed: false,
    );
  }

  Future<void> saveEvent() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'enter_title_error'.tr);
      return;
    }

    DateTime? eventTime;
    if (selectedTime.value != null) {
      eventTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        selectedTime.value!.hour,
        selectedTime.value!.minute,
      );
    }

    // Đảm bảo date chỉ lưu ngày, không có giờ phút giây
    final eventDate = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );

    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      date: eventDate,
      time: eventTime,
      hasNotification: hasNotification.value,
      reminderMinutesBefore:
          hasNotification.value ? reminderMinutesBefore.value : null,
      isRecurring: isRecurring.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.addEvent(event);

    // Refresh calendar nếu đang mở
    try {
      if (Get.isRegistered<CalendarController>()) {
        Get.find<CalendarController>().refresh();
      }
    } catch (e) {
      // Ignore if CalendarController is not registered
    }

    Get.back();
    _clearForm();
  }

  void _clearForm() {
    titleController.clear();
    contentController.clear();
    descriptionController.clear();
    attachments.clear();
    selectedCategory.value = 'None';
    selectedTime.value = null;
    showTime.value = false;
    isDiaryPinned.value = false;
    selectedMood.value = MoodConstants.normal;
  }

  /// Debug helper: Clear prompt state to test again
  Future<void> clearPromptStateForToday() async {
    await _storage.clearPromptedToday();
    Get.snackbar(
      'Debug',
      'Cleared prompt state - you can test mood prompt again',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  /// Show diary edit dialog (popup form)
  void showDiaryEditDialog(dynamic diary) {
    // Load diary data into form
    titleController.text = diary.title;
    contentController.text = diary.content;
    selectedDate.value = diary.date;
    showTime.value = diary.showTime;
    if (diary.showTime && diary.date != null) {
      selectedTime.value = TimeOfDay.fromDateTime(diary.date);
    }
    selectedMood.value = diary.mood ?? MoodConstants.normal;
    isDiaryPinned.value = diary.isPinned;
    attachments.value = List.from(diary.attachments);

    // Show edit dialog
    Get.dialog(
      AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: Get.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.8,
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Diary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Get.back();
                        _clearForm();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mood Selector
                const Text(
                  'Mood',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: MoodConstants.allMoods.map((mood) {
                        final isSelected = selectedMood.value == mood;
                        return GestureDetector(
                          onTap: () => selectedMood.value = mood,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: MoodConstants.getColorForMood(mood),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    MoodConstants.getEmojiForMood(mood),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                MoodConstants.getLabelForMood(mood),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 20),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Diary Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 8,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => pickDate(Get.context!),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Obx(() => Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate.value),
                        )),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() => CheckboxListTile(
                      title: const Text('Show Time'),
                      value: showTime.value,
                      onChanged: (value) {
                        showTime.value = value ?? false;
                      },
                    )),
                Obx(() {
                  if (showTime.value) {
                    return Column(
                      children: [
                        InkWell(
                          onTap: () => pickTime(Get.context!),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              selectedTime.value?.format(Get.context!) ??
                                  'Select Time',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Update diary
                      final updatedDiary = diary.copyWith(
                        title: titleController.text.trim(),
                        content: contentController.text.trim(),
                        date: selectedDate.value,
                        showTime: showTime.value,
                        mood: selectedMood.value,
                        isPinned: isDiaryPinned.value,
                        backgroundColor:
                            MoodConstants.getColorForMood(selectedMood.value),
                        updatedAt: DateTime.now(),
                        attachments: attachments.toList(),
                      );

                      await _storage.updateDiary(updatedDiary);

                      // Refresh controllers
                      try {
                        if (Get.isRegistered<ManageController>()) {
                          Get.find<ManageController>().loadData();
                        }
                      } catch (e) {
                        // Ignore
                      }

                      Get.back(); // Close dialog
                      _clearForm();

                      Get.snackbar(
                        'Success',
                        'Diary updated successfully',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: const Text('Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
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
