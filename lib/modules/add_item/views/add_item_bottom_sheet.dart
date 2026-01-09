import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/add_item_controller.dart';
import '../../quick_add/views/quick_add_bottom_sheet.dart';

class AddItemBottomSheet {
  static void show() {
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
            Text(
              'choose_type'.tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTypeButton(
                  icon: Icons.check_circle_outline,
                  label: 'TODO',
                  color: Colors.blue,
                  onTap: () {
                    Get.back();
                    Get.bottomSheet(
                      const QuickAddBottomSheet(),
                      isScrollControlled: true,
                    );
                  },
                ),
                _buildTypeButton(
                  icon: Icons.event,
                  label: 'EVENT',
                  color: Colors.purple,
                  onTap: () {
                    Get.back();
                    showEventForm();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTypeButton(
                  icon: Icons.note,
                  label: 'NOTE',
                  color: Colors.orange,
                  onTap: () {
                    Get.back();
                    showNoteForm();
                  },
                ),
                _buildTypeButton(
                  icon: Icons.book,
                  label: 'DIARY',
                  color: Colors.green,
                  onTap: () {
                    Get.back();
                    showDiaryForm();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildTypeButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Note Form
  static void showNoteForm() {
    final controller = Get.put(AddItemController());

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'add_note'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.titleController,
                decoration: InputDecoration(
                  labelText: 'note_title'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.contentController,
                decoration: InputDecoration(
                  labelText: 'content'.tr,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: controller.selectedCategory.value,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: controller.categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedCategory.value = value;
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.saveNote,
                  child: Text('add'.tr),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Diary Form
  static void showDiaryForm() {
    final controller = Get.put(AddItemController());

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'add_diary'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.titleController,
                decoration: InputDecoration(
                  labelText: 'diary_title'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.contentController,
                decoration: InputDecoration(
                  labelText: 'content'.tr,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => controller.pickDate(Get.context!),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'date'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  child: Obx(() => Text(
                        DateFormat('dd/MM/yyyy')
                            .format(controller.selectedDate.value),
                      )),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => CheckboxListTile(
                    title: Text('show_time'.tr),
                    value: controller.showTime.value,
                    onChanged: (value) {
                      controller.showTime.value = value ?? false;
                    },
                  )),
              Obx(() {
                if (controller.showTime.value) {
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => controller.pickTime(Get.context!),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'time'.tr,
                            border: const OutlineInputBorder(),
                          ),
                          child: Text(
                            controller.selectedTime.value
                                    ?.format(Get.context!) ??
                                'select_time'.tr,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),

              // Attachments section
              Row(
                children: [
                  Text(
                    'attachments'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate),
                    onPressed: controller.showAttachmentPicker,
                    tooltip: 'add_attachment'.tr,
                  ),
                ],
              ),
              Obx(() {
                if (controller.attachments.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.attachments.map((attachment) {
                    return Chip(
                      avatar: Icon(attachment.icon, size: 18),
                      label: Text(
                        attachment.fileName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => controller.removeAttachment(attachment),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.saveDiary,
                  child: Text('add'.tr),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Event Form
  static void showEventForm() {
    final controller = Get.put(AddItemController());

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'add_event'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.titleController,
                decoration: InputDecoration(
                  labelText: 'event_title'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.descriptionController,
                decoration: InputDecoration(
                  labelText: 'event_description'.tr,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => controller.pickDate(Get.context!),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'date'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  child: Obx(() => Text(
                        DateFormat('dd/MM/yyyy')
                            .format(controller.selectedDate.value),
                      )),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => controller.pickTime(Get.context!),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'time'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  child: Obx(() => Text(
                        controller.selectedTime.value?.format(Get.context!) ??
                            'select_time'.tr,
                      )),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => CheckboxListTile(
                    title: Text('has_notification'.tr),
                    value: controller.hasNotification.value,
                    onChanged: (value) {
                      controller.hasNotification.value = value ?? true;
                    },
                  )),
              Obx(() => CheckboxListTile(
                    title: Text('is_recurring'.tr),
                    subtitle: const Text('Repeat yearly (e.g. birthdays)'),
                    value: controller.isRecurring.value,
                    onChanged: (value) {
                      controller.isRecurring.value = value ?? false;
                    },
                  )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.saveEvent,
                  child: Text('add'.tr),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
