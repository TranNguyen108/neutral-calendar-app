import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/note_editor_controller.dart';

class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NoteEditorController(), permanent: false);

    return Obx(() => Scaffold(
          backgroundColor: controller.backgroundColor.value,
          appBar: _NoteEditorAppBar(
            controller: controller,
            onExit: () => _showExitDialog(context, controller),
            onReminder: () => _showReminderDialog(context, controller),
            onCategory: () => _showAddCategoryDialog(context, controller),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextField(
                        controller: controller.titleController,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(height: 16),

                      // Content with formatting
                      Obx(() => TextField(
                            controller: controller.contentController,
                            style: TextStyle(
                              fontSize: controller.fontSize.value,
                              fontWeight: controller.isBold.value
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontStyle: controller.isItalic.value
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              decoration: controller.isUnderline.value
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Note',
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          )),

                      const SizedBox(height: 16),

                      // Checkbox list
                      Obx(() => Column(
                            children: controller.checkboxItems
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Row(
                                children: [
                                  Checkbox(
                                    value: item['checked'],
                                    onChanged: (value) =>
                                        controller.toggleCheckbox(index),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(
                                          text: item['text']),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Item ${index + 1}',
                                      ),
                                      style: TextStyle(
                                        decoration: item['checked']
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                      onChanged: (text) => controller
                                          .updateCheckboxText(index, text),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () =>
                                        controller.removeCheckbox(index),
                                  ),
                                ],
                              );
                            }).toList(),
                          )),

                      // Images
                      Obx(() => controller.images.isNotEmpty
                          ? Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: controller.images.map((image) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        image,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 16),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            controller.removeImage(image),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            )
                          : const SizedBox.shrink()),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Format Toolbar
              _buildFormatToolbar(controller),

              // Bottom Action Bar
              _buildBottomBar(context, controller),
            ],
          ),
        ));
  }

  Widget _buildFormatToolbar(NoteEditorController controller) {
    return Obx(() => controller.showFormatToolbar.value
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? Colors.grey[850] : Colors.grey[100],
              border: Border(
                top: BorderSide(
                  color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Text Size
                  Obx(() => _buildFormatButton(
                        label: 'H1',
                        isActive: controller.fontSize.value == 24,
                        onPressed: () => controller.setFontSize(24),
                      )),
                  Obx(() => _buildFormatButton(
                        label: 'H2',
                        isActive: controller.fontSize.value == 20,
                        onPressed: () => controller.setFontSize(20),
                      )),
                  Obx(() => _buildFormatButton(
                        label: 'H3',
                        isActive: controller.fontSize.value == 18,
                        onPressed: () => controller.setFontSize(18),
                      )),
                  const SizedBox(width: 8),

                  // Text Style
                  Obx(() => _buildFormatButton(
                        icon: Icons.format_bold,
                        isActive: controller.isBold.value,
                        onPressed: controller.toggleBold,
                      )),
                  Obx(() => _buildFormatButton(
                        icon: Icons.format_italic,
                        isActive: controller.isItalic.value,
                        onPressed: controller.toggleItalic,
                      )),
                  Obx(() => _buildFormatButton(
                        icon: Icons.format_underline,
                        isActive: controller.isUnderline.value,
                        onPressed: controller.toggleUnderline,
                      )),
                  const SizedBox(width: 8),

                  // Clear Format
                  _buildFormatButton(
                    icon: Icons.format_clear,
                    onPressed: controller.clearFormat,
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink());
  }

  Widget _buildFormatButton({
    IconData? icon,
    String? label,
    bool isActive = false,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color:
            isActive ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: label != null
                ? Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.blue : null,
                    ),
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: isActive ? Colors.blue : null,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, NoteEditorController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Obx(() => IconButton(
                  icon: Icon(controller.showFormatToolbar.value
                      ? Icons.keyboard_arrow_down
                      : Icons.text_fields),
                  onPressed: controller.toggleFormatToolbar,
                  tooltip: 'Format',
                )),
            IconButton(
              icon: const Icon(Icons.check_box_outlined),
              onPressed: controller.addCheckbox,
              tooltip: 'Checkbox',
            ),
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: controller.addImage,
              tooltip: 'Image',
            ),
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: () => _showAddLinkDialog(context, controller),
              tooltip: 'Link',
            ),
            IconButton(
              icon: const Icon(Icons.mic_outlined),
              onPressed: controller.addAudio,
              tooltip: 'Audio',
            ),
            IconButton(
              icon: const Icon(Icons.draw_outlined),
              onPressed: controller.openDrawing,
              tooltip: 'Draw',
            ),
            const SizedBox(width: 16), // Replace Spacer with fixed spacing
            IconButton(
              icon: const Icon(Icons.color_lens_outlined),
              onPressed: () => _showColorPicker(context, controller),
              tooltip: 'Color',
            ),
            Obx(() => controller.selectedCategory.value != 'None'
                ? Chip(
                    avatar: const Icon(Icons.label, size: 16),
                    label: Text(
                      controller.selectedCategory.value,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () => controller.setCategory('None'),
                    deleteIconColor: Colors.grey,
                  )
                : const SizedBox.shrink()),
            const SizedBox(width: 8), // Trailing padding
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, NoteEditorController controller) {
    if (controller.hasChanges) {
      Get.dialog(
        AlertDialog(
          title: const Text('Exit without saving?'),
          content: const Text('Changes will not be saved.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.back();
              },
              child: const Text('Exit'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                controller.saveNote();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      Get.back();
    }
  }

  void _showColorPicker(BuildContext context, NoteEditorController controller) {
    final colors = [
      Colors.white,
      Colors.red.shade100,
      Colors.orange.shade100,
      Colors.yellow.shade100,
      Colors.green.shade100,
      Colors.teal.shade100,
      Colors.blue.shade100,
      Colors.purple.shade100,
      Colors.pink.shade100,
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Background Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Obx(() => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        controller.setBackgroundColor(color);
                        Get.back();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: controller.backgroundColor.value == color
                                ? Colors.blue
                                : Colors.grey,
                            width: controller.backgroundColor.value == color
                                ? 3
                                : 2,
                          ),
                        ),
                        child: controller.backgroundColor.value == color
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                      ),
                    );
                  }).toList(),
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddLinkDialog(
      BuildContext context, NoteEditorController controller) {
    final urlController = TextEditingController();
    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Display Text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                controller.addLink(
                  textController.text.isEmpty
                      ? urlController.text
                      : textController.text,
                  urlController.text,
                );
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(
      BuildContext context, NoteEditorController controller) {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Work, Personal...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                controller.addNewCategory(textController.text);
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showReminderDialog(
      BuildContext context, NoteEditorController controller) {
    DateTime selectedDate = controller.reminderDate.value ?? DateTime.now();
    TimeOfDay selectedTime = controller.reminderTime.value ?? TimeOfDay.now();

    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange),
            SizedBox(width: 12),
            Text('Đặt nhắc nhở'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date picker
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Ngày'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 8),
                // Time picker
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Giờ'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
                if (controller.reminderDate.value != null) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      controller.clearReminder();
                      Get.back();
                    },
                    icon: const Icon(Icons.clear, color: Colors.red),
                    label: const Text(
                      'Xóa nhắc nhở',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.setReminder(selectedDate, selectedTime);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đặt'),
          ),
        ],
      ),
    );
  }
}

// Custom AppBar Widget
class _NoteEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final NoteEditorController controller;
  final VoidCallback onExit;
  final VoidCallback onReminder;
  final VoidCallback onCategory;

  const _NoteEditorAppBar({
    required this.controller,
    required this.onExit,
    required this.onReminder,
    required this.onCategory,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onExit,
        tooltip: 'Back',
      ),
      actions: [
        // Save button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton.icon(
            onPressed: controller.saveNote,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Undo button
        Obx(() => IconButton(
              icon: const Icon(Icons.undo),
              onPressed: controller.canUndo ? controller.undo : null,
              tooltip: 'Undo',
              color: controller.canUndo ? null : Colors.grey,
            )),

        // Redo button
        Obx(() => IconButton(
              icon: const Icon(Icons.redo),
              onPressed: controller.canRedo ? controller.redo : null,
              tooltip: 'Redo',
              color: controller.canRedo ? null : Colors.grey,
            )),

        const SizedBox(width: 4),

        // Reminder button
        Obx(() => IconButton(
              icon: Icon(
                controller.reminderDate.value != null
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                color: controller.reminderDate.value != null
                    ? Colors.orange
                    : null,
              ),
              onPressed: onReminder,
              tooltip: 'Reminder',
            )),

        // More menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More',
          onSelected: (value) {
            switch (value) {
              case 'favorite':
                controller.togglePin();
                break;
              case 'category':
                onCategory();
                break;
              case 'export_pdf':
                controller.exportPDF();
                break;
              case 'share':
                controller.shareNote();
                break;
              case 'delete':
                controller.deleteNote();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'favorite',
              child: Obx(() => Row(
                    children: [
                      Icon(
                        controller.isPinned.value
                            ? Icons.star
                            : Icons.star_outline,
                        size: 20,
                        color: controller.isPinned.value ? Colors.amber : null,
                      ),
                      const SizedBox(width: 12),
                      Text(controller.isPinned.value
                          ? 'Bỏ yêu thích'
                          : 'Yêu thích'),
                    ],
                  )),
            ),
            const PopupMenuItem(
              value: 'category',
              child: Row(
                children: [
                  Icon(Icons.label_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Thêm thẻ'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export_pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Xuất PDF'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Chia sẻ'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),
      ],
    );
  }
}
