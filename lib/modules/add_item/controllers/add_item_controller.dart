import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/note.dart';
import '../../../core/models/diary.dart';
import '../../../core/models/event.dart';
import '../../../core/models/attachment.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/attachment_service.dart';

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

  final categories = <String>[
    'None',
    ...AppConstants.defaultCategories,
  ].obs;

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
    Get.back();
    Get.snackbar('success'.tr, 'note_saved'.tr);
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
    );

    await _storage.addDiary(diary);
    Get.back();
    _clearForm();
    Get.snackbar('success'.tr, 'diary_saved'.tr);
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

    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      date: selectedDate.value,
      time: eventTime,
      hasNotification: hasNotification.value,
      reminderMinutesBefore:
          hasNotification.value ? reminderMinutesBefore.value : null,
      isRecurring: isRecurring.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.addEvent(event);
    Get.back();
    _clearForm();
    Get.snackbar('success'.tr, 'event_saved'.tr);
  }

  void _clearForm() {
    titleController.clear();
    contentController.clear();
    descriptionController.clear();
    attachments.clear();
    selectedCategory.value = 'None';
    selectedTime.value = null;
    showTime.value = false;
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
