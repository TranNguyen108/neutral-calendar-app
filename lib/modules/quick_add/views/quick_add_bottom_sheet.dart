import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/quick_add_controller.dart';
import '../../../core/models/task.dart';

class QuickAddBottomSheet extends StatelessWidget {
  const QuickAddBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<QuickAddController>()
        ? Get.find<QuickAddController>()
        : Get.put(QuickAddController());

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.add_task, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'quick_add'.tr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Title Field
              TextField(
                controller: controller.titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'enter_title'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Note Field
              TextField(
                controller: controller.noteController,
                decoration: InputDecoration(
                  hintText: 'enter_note'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),

              // Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: Obx(() => InkWell(
                          onTap: () => controller.pickDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.calendar_today),
                              labelText: 'date'.tr,
                            ),
                            child: Text(
                              controller.selectedDate.value != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(controller.selectedDate.value!)
                                  : 'select_date'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: controller.selectedDate.value != null
                                    ? null
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => InkWell(
                          onTap: () => controller.pickStartTime(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.access_time),
                              labelText: 'time'.tr,
                            ),
                            child: Text(
                              controller.selectedTime.value?.format(context) ??
                                  'select_time'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: controller.selectedTime.value != null
                                    ? null
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Priority
              Text('priority'.tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              Obx(() => Row(
                    children: [
                      Expanded(
                        child: _buildPriorityChip(
                          controller,
                          Priority.high,
                          'high'.tr,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPriorityChip(
                          controller,
                          Priority.medium,
                          'medium'.tr,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPriorityChip(
                          controller,
                          Priority.low,
                          'low'.tr,
                          Colors.green,
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 20),

              // Category
              Text('category'.tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<String>(
                    value: controller.selectedCategory.value,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
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
                  )),
              const SizedBox(height: 20),

              // Subtasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('subtasks'.tr,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('${controller.subtasks.length}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.subtaskController,
                      decoration: InputDecoration(
                        hintText: 'add_subtask'.tr,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        controller.addSubtask(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 28),
                    color: Colors.blue,
                    onPressed: () {
                      controller.addSubtask(controller.subtaskController.text);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() => controller.subtasks.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      children: controller.subtasks
                          .asMap()
                          .entries
                          .map(
                            (entry) => Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                dense: true,
                                leading: const Icon(
                                    Icons.subdirectory_arrow_right,
                                    size: 18),
                                title: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    controller.removeSubtask(entry.key);
                                  },
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )),
              const SizedBox(height: 20),

              // Reminder & Recurrence Row
              Row(
                children: [
                  Expanded(
                    child: Obx(() => InkWell(
                          onTap: () => _showReminderPicker(controller, context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.notifications),
                              labelText: 'reminder'.tr,
                            ),
                            child: Text(
                              controller.selectedReminder.value != null
                                  ? '${controller.selectedReminder.value} min'
                                  : 'none'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: controller.selectedReminder.value != null
                                    ? null
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => InkWell(
                          onTap: () =>
                              _showRecurrencePicker(controller, context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.repeat),
                              labelText: 'repeat'.tr,
                            ),
                            child: Text(
                              _getRecurrenceText(
                                  controller.selectedRecurrence.value),
                              style: TextStyle(
                                fontSize: 14,
                                color: controller.selectedRecurrence.value !=
                                        RecurrenceRule.none
                                    ? null
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Attachments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('attachments'.tr,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  TextButton.icon(
                    onPressed: controller.showAttachmentPicker,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text('add'.tr),
                  ),
                ],
              ),
              Obx(() {
                if (controller.attachments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'no_attachments'.tr,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.attachments.map((attachment) {
                    return Chip(
                      avatar: Icon(attachment.icon, size: 18),
                      label: Text(
                        attachment.fileName.length > 20
                            ? '${attachment.fileName.substring(0, 20)}...'
                            : attachment.fileName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => controller.removeAttachment(attachment),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 24),

              // Add Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: controller.saveQuickTask,
                  icon: const Icon(Icons.check),
                  label: Text(
                    'add_task'.tr,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(
    QuickAddController controller,
    Priority priority,
    String label,
    Color color,
  ) {
    final isSelected = controller.selectedPriority.value == priority;
    return FilterChip(
      label: Center(child: Text(label, style: const TextStyle(fontSize: 13))),
      selected: isSelected,
      onSelected: (_) => controller.selectedPriority.value = priority,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300, width: 1.5),
    );
  }

  void _showReminderPicker(
      QuickAddController controller, BuildContext context) {
    final reminderOptions = [
      null, // No reminder
      5,
      15,
      30,
      60,
      1440, // 1 day
    ];

    Get.dialog(
      AlertDialog(
        title: Text('reminder'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reminderOptions.map((minutes) {
            final isSelected = controller.selectedReminder.value == minutes;
            return RadioListTile<int?>(
              title: Text(minutes == null
                  ? 'none'.tr
                  : minutes < 60
                      ? '$minutes ${'minutes_before'.tr}'
                      : minutes == 60
                          ? '1 ${'hour_before'.tr}'
                          : '1 ${'day_before'.tr}'),
              value: minutes,
              groupValue: controller.selectedReminder.value,
              onChanged: (value) {
                controller.selectedReminder.value = value;
                Get.back();
              },
              selected: isSelected,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRecurrencePicker(
      QuickAddController controller, BuildContext context) {
    final recurrenceOptions = [
      RecurrenceRule.none,
      RecurrenceRule.daily,
      RecurrenceRule.weekly,
      RecurrenceRule.monthly,
    ];

    Get.dialog(
      AlertDialog(
        title: Text('recurrence'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: recurrenceOptions.map((rule) {
            final isSelected = controller.selectedRecurrence.value == rule;
            return RadioListTile<RecurrenceRule>(
              title: Text(_getRecurrenceText(rule)),
              value: rule,
              groupValue: controller.selectedRecurrence.value,
              onChanged: (value) {
                controller.selectedRecurrence.value = value!;
                Get.back();
              },
              selected: isSelected,
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getRecurrenceText(RecurrenceRule rule) {
    switch (rule) {
      case RecurrenceRule.none:
        return 'none'.tr;
      case RecurrenceRule.daily:
        return 'daily'.tr;
      case RecurrenceRule.weekly:
        return 'weekly'.tr;
      case RecurrenceRule.monthly:
        return 'monthly'.tr;
      case RecurrenceRule.custom:
        return 'custom'.tr;
    }
  }
}
