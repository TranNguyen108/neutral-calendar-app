import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/note.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../manage/controllers/manage_controller.dart';

class NoteEditorController extends GetxController {
  late final StorageService _storage;
  final ImagePicker _imagePicker = ImagePicker();

  final titleController = TextEditingController();
  final contentController = TextEditingController();

  // Undo/Redo stacks (observable for GetX reactivity)
  final _undoStack = <String>[].obs;
  final _redoStack = <String>[].obs;
  String _lastSavedContent = '';

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();

    // Listen to content changes for undo/redo
    contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    final currentContent = contentController.text;
    if (currentContent != _lastSavedContent) {
      _undoStack.add(_lastSavedContent);
      _lastSavedContent = currentContent;
      _redoStack.clear(); // Clear redo stack on new change
    }
  }

  // Formatting
  final fontSize = 16.0.obs;
  final isBold = false.obs;
  final isItalic = false.obs;
  final isUnderline = false.obs;
  final showFormatToolbar = false.obs;

  // Colors
  final backgroundColor = Colors.white.obs;

  // Category
  final selectedCategory = 'None'.obs;
  final categories = <String>[
    'None',
    ...AppConstants.defaultCategories,
  ].obs;

  // Media
  final images = <File>[].obs;
  final checkboxItems = <Map<String, dynamic>>[].obs;

  // State
  final isPinned = false.obs;
  bool get hasChanges =>
      titleController.text.isNotEmpty || contentController.text.isNotEmpty;

  @override
  void onClose() {
    contentController.removeListener(_onContentChanged);
    titleController.dispose();
    contentController.dispose();
    super.onClose();
  }

  // Undo/Redo Methods
  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_lastSavedContent);
      final previousContent = _undoStack.removeLast();
      _lastSavedContent = previousContent;
      contentController.removeListener(_onContentChanged);
      contentController.text = previousContent;
      contentController.addListener(_onContentChanged);
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_lastSavedContent);
      final nextContent = _redoStack.removeLast();
      _lastSavedContent = nextContent;
      contentController.removeListener(_onContentChanged);
      contentController.text = nextContent;
      contentController.addListener(_onContentChanged);
    }
  }

  bool get canUndo => _undoStack.length > 0;
  bool get canRedo => _redoStack.length > 0;

  // Format Methods
  void toggleFormatToolbar() {
    showFormatToolbar.value = !showFormatToolbar.value;
  }

  void setFontSize(double size) {
    fontSize.value = size;
  }

  void toggleBold() {
    isBold.value = !isBold.value;
  }

  void toggleItalic() {
    isItalic.value = !isItalic.value;
  }

  void toggleUnderline() {
    isUnderline.value = !isUnderline.value;
  }

  void clearFormat() {
    fontSize.value = 16.0;
    isBold.value = false;
    isItalic.value = false;
    isUnderline.value = false;
  }

  // Color Methods
  void setBackgroundColor(Color color) {
    backgroundColor.value = color;
  }

  // Category Methods
  void setCategory(String category) {
    selectedCategory.value = category;
  }

  void addNewCategory(String categoryName) {
    final trimmed = categoryName.trim();
    if (trimmed.isNotEmpty && !categories.contains(trimmed)) {
      categories.add(trimmed);
      selectedCategory.value = trimmed;
      Get.snackbar(
        'success'.tr,
        'Đã thêm danh mục "$trimmed"',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Media Methods
  Future<void> addImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        images.add(File(image.path));
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Không thể thêm hình ảnh: $e');
    }
  }

  void removeImage(File image) {
    images.remove(image);
  }

  Future<void> addAudio() async {
    // TODO: Implement audio recording
    Get.snackbar(
      'Thông báo',
      'Tính năng ghi âm đang được phát triển',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openDrawing() {
    // TODO: Implement drawing feature
    Get.snackbar(
      'Thông báo',
      'Tính năng vẽ tay đang được phát triển',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void addLink(String text, String url) {
    // Add link to content
    final currentText = contentController.text;
    contentController.text = '$currentText\n[$text]($url)';
  }

  void addCheckbox() {
    checkboxItems.add({
      'text': 'Mục mới',
      'checked': false,
    });
  }

  void toggleCheckbox(int index) {
    final item = checkboxItems[index];
    checkboxItems[index] = {
      'text': item['text'],
      'checked': !(item['checked'] as bool),
    };
  }

  void updateCheckboxText(int index, String text) {
    final item = checkboxItems[index];
    checkboxItems[index] = {
      'text': text,
      'checked': item['checked'],
    };
  }

  void removeCheckbox(int index) {
    checkboxItems.removeAt(index);
  }

  // Actions
  void togglePin() {
    isPinned.value = !isPinned.value;
  }

  // Reminder
  final reminderDate = Rx<DateTime?>(null);
  final reminderTime = Rx<TimeOfDay?>(null);

  void setReminder(DateTime date, TimeOfDay time) {
    reminderDate.value = date;
    reminderTime.value = time;
    Get.back();
    Get.snackbar(
      'success'.tr,
      'Đã đặt nhắc nhở',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void clearReminder() {
    reminderDate.value = null;
    reminderTime.value = null;
  }

  // Menu Actions
  void exportPDF() {
    Get.snackbar(
      'Thông báo',
      'Tính năng xuất PDF đang được phát triển',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void shareNote() {
    Get.snackbar(
      'Thông báo',
      'Tính năng chia sẻ đang được phát triển',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> deleteNote() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa ghi chú này?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Get.back();
      Get.snackbar(
        'success'.tr,
        'Đã xóa ghi chú',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Save
  Future<void> saveNote() async {
    if (titleController.text.trim().isEmpty &&
        contentController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'Vui lòng nhập tiêu đề hoặc nội dung');
      return;
    }

    // Build content with formatting metadata
    String formattedContent = contentController.text;

    // Add checkboxes to content
    if (checkboxItems.isNotEmpty) {
      final checkboxText = checkboxItems
          .map((item) => '${item['checked'] ? '[x]' : '[ ]'} ${item['text']}')
          .join('\n');
      formattedContent = '$formattedContent\n\n$checkboxText';
    }

    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim().isEmpty
          ? 'Không có tiêu đề'
          : titleController.text.trim(),
      content: formattedContent,
      category:
          selectedCategory.value == 'None' ? null : selectedCategory.value,
      isFavorite: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.addNote(note);

    // Refresh ManageController
    try {
      if (Get.isRegistered<ManageController>()) {
        Get.find<ManageController>().loadData();
      }
    } catch (e) {
      // Ignore if not registered
    }

    Get.back();
    Get.snackbar(
      'success'.tr,
      'Đã lưu ghi chú',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
