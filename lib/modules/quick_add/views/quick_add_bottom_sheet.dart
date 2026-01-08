import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/quick_add_controller.dart';
import '../../../core/models/task.dart';

class QuickAddBottomSheet extends StatelessWidget {
  const QuickAddBottomSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const QuickAddBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Get.find if exists, otherwise create new instance
    final controller = Get.isRegistered<QuickAddController>()
        ? Get.find<QuickAddController>()
        : Get.put(QuickAddController());

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
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
          ),
          const Divider(height: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                TextField(
                  controller: controller.titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'enter_title'.tr,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // Note Field
                TextField(
                  controller: controller.noteController,
                  decoration: InputDecoration(
                    hintText: 'enter_note'.tr,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),

                // Priority Quick Selection (3 buttons)
                Text(
                  'priority'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Row(
                      children: [
                        Expanded(
                          child: _buildPriorityButton(
                            controller,
                            Priority.low,
                            'low'.tr,
                            Colors.green,
                            Icons.arrow_downward,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPriorityButton(
                            controller,
                            Priority.medium,
                            'medium'.tr,
                            Colors.orange,
                            Icons.remove,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPriorityButton(
                            controller,
                            Priority.high,
                            'high'.tr,
                            Colors.red,
                            Icons.priority_high,
                          ),
                        ),
                      ],
                    )),
                const SizedBox(height: 16),

                // Subtasks Section
                Text(
                  'subtasks'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtask input and add button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.subtaskController,
                        decoration: InputDecoration(
                          hintText: 'add_subtask'.tr,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
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
                        controller
                            .addSubtask(controller.subtaskController.text);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Display added subtasks
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
                                      size: 20),
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
                const SizedBox(height: 16),

                // Action Buttons Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildActionButton(
                      context,
                      controller,
                      icon: Icons.category_outlined,
                      label: 'category'.tr,
                      onTap: () => _showCategoryPicker(controller, context),
                    ),
                    _buildActionButton(
                      context,
                      controller,
                      icon: Icons.calendar_today,
                      label: 'date_time'.tr,
                      onTap: () => _showDateTimePicker(controller, context),
                    ),
                    _buildActionButton(
                      context,
                      controller,
                      icon: Icons.notifications_outlined,
                      label: 'reminder'.tr,
                      onTap: () => _showReminderPicker(controller, context),
                    ),
                    _buildActionButton(
                      context,
                      controller,
                      icon: Icons.repeat,
                      label: 'recurrence'.tr,
                      onTap: () => _showRecurrencePicker(controller, context),
                    ),
                    _buildActionButton(
                      context,
                      controller,
                      icon: Icons.attach_file,
                      label: 'attach'.tr,
                      onTap: controller.showAttachmentPicker,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Attachments display
                Obx(() {
                  if (controller.attachments.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'attachments'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
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
                            onDeleted: () =>
                                controller.removeAttachment(attachment),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),

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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build action button
  Widget _buildActionButton(
    BuildContext context,
    QuickAddController controller, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Obx(() {
      // Determine button value based on label
      String displayText = label;
      bool hasValue = false;

      if (label == 'category'.tr &&
          controller.selectedCategory.value.isNotEmpty &&
          controller.selectedCategory.value != 'None') {
        displayText = controller.selectedCategory.value;
        hasValue = true;
      } else if (label == 'date_time'.tr &&
          controller.selectedDate.value != null) {
        final date = controller.selectedDate.value!;
        displayText = DateFormat('dd/MM').format(date);
        if (controller.selectedTime.value != null) {
          displayText += ' ${controller.selectedTime.value!.format(context)}';
        }
        hasValue = true;
      } else if (label == 'reminder'.tr &&
          controller.selectedReminder.value != null) {
        final minutes = controller.selectedReminder.value!;
        if (minutes == 5) {
          displayText = '5min';
        } else if (minutes == 15) {
          displayText = '15min';
        } else if (minutes == 30) {
          displayText = '30min';
        } else if (minutes == 60) {
          displayText = '1hr';
        }
        hasValue = true;
      } else if (label == 'recurrence'.tr &&
          controller.selectedRecurrence.value != RecurrenceRule.none) {
        final rule = controller.selectedRecurrence.value;
        if (rule == RecurrenceRule.daily) {
          displayText = 'daily'.tr;
        } else if (rule == RecurrenceRule.weekly) {
          displayText = 'weekly'.tr;
        } else if (rule == RecurrenceRule.monthly) {
          displayText = 'monthly'.tr;
        }
        hasValue = true;
      } else if (label == 'priority'.tr &&
          controller.selectedPriority.value != Priority.medium) {
        final priority = controller.selectedPriority.value;
        if (priority == Priority.high) {
          displayText = 'high'.tr;
        } else if (priority == Priority.low) {
          displayText = 'low'.tr;
        }
        hasValue = true;
      }

      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(displayText),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(
            color: hasValue ? Colors.blue : Colors.grey.shade300,
            width: hasValue ? 2 : 1,
          ),
          foregroundColor: hasValue ? Colors.blue : Colors.grey.shade700,
        ),
      );
    });
  }

  // Show Category Picker Dialog
  void _showCategoryPicker(
      QuickAddController controller, BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('category'.tr),
        content: Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...controller.categories.map((cat) => FilterChip(
                      label: Text(cat),
                      selected: controller.selectedCategory.value == cat,
                      onSelected: (_) {
                        controller.selectedCategory.value = cat;
                        Get.back();
                      },
                      selectedColor: Colors.purple.withValues(alpha: 0.3),
                      checkmarkColor: Colors.purple,
                      side: BorderSide(
                          color: controller.selectedCategory.value == cat
                              ? Colors.purple
                              : Colors.grey.shade300),
                    )),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text('add_category'.tr),
                  onPressed: () => _showAddCategoryDialog(controller, context),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ],
            )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  // Show Date/Time Picker Dialog
  void _showDateTimePicker(
      QuickAddController controller, BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('date_time'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date shortcuts
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDateDialogChip(
                      controller, 'today'.tr, DateTime.now(), context),
                  _buildDateDialogChip(controller, 'tomorrow'.tr,
                      DateTime.now().add(const Duration(days: 1)), context),
                  _buildDateDialogChip(controller, '3_days_later'.tr,
                      DateTime.now().add(const Duration(days: 3)), context),
                  _buildDateDialogChip(
                      controller, 'this_sunday'.tr, _getNextSunday(), context),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month, size: 18),
                    label: Text('choose_date'.tr),
                    onPressed: () => controller.pickDate(context),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: Obx(() => InkWell(
                          onTap: () => controller.pickStartTime(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.access_time),
                              labelText: 'start_time'.tr,
                            ),
                            child: Text(
                              controller.selectedTime.value?.format(context) ??
                                  'select_time'.tr,
                            ),
                          ),
                        )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => InkWell(
                          onTap: () => controller.pickEndTime(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.access_time_filled),
                              labelText: 'end_time'.tr,
                            ),
                            child: Text(
                              controller.selectedEndTime.value
                                      ?.format(context) ??
                                  'select_time'.tr,
                            ),
                          ),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('done'.tr),
          ),
        ],
      ),
    );
  }

  // Show Reminder Picker Dialog
  void _showReminderPicker(
      QuickAddController controller, BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('reminder'.tr),
        content: Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildReminderDialogChip(controller, null, 'no_reminder'.tr),
                _buildReminderDialogChip(controller, 5, '5_min_before'.tr),
                _buildReminderDialogChip(controller, 15, '15_min_before'.tr),
                _buildReminderDialogChip(controller, 30, '30_min_before'.tr),
                _buildReminderDialogChip(controller, 60, '1_hour_before'.tr),
              ],
            )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  // Show Recurrence Picker Dialog
  void _showRecurrencePicker(
      QuickAddController controller, BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('recurrence'.tr),
        content: Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRecurrenceDialogChip(
                    controller, RecurrenceRule.none, 'none'.tr),
                _buildRecurrenceDialogChip(
                    controller, RecurrenceRule.daily, 'daily'.tr),
                _buildRecurrenceDialogChip(
                    controller, RecurrenceRule.weekly, 'weekly'.tr),
                _buildRecurrenceDialogChip(
                    controller, RecurrenceRule.monthly, 'monthly'.tr),
              ],
            )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  // Helper chips for dialogs
  Widget _buildDateDialogChip(QuickAddController controller, String label,
      DateTime date, BuildContext context) {
    final isSelected = controller.selectedDate.value != null &&
        _isSameDay(controller.selectedDate.value!, date);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        controller.setDate(date);
        Get.back();
      },
      selectedColor: Colors.blue.withValues(alpha: 0.3),
      checkmarkColor: Colors.blue,
      side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300),
    );
  }

  Widget _buildRecurrenceDialogChip(
      QuickAddController controller, RecurrenceRule rule, String label) {
    final isSelected = controller.selectedRecurrence.value == rule;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        controller.selectedRecurrence.value = rule;
        Get.back();
      },
      selectedColor: Colors.teal.withValues(alpha: 0.3),
      checkmarkColor: Colors.teal,
      side: BorderSide(color: isSelected ? Colors.teal : Colors.grey.shade300),
    );
  }

  Widget _buildReminderDialogChip(
      QuickAddController controller, int? minutes, String label) {
    final isSelected = controller.selectedReminder.value == minutes;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        controller.selectedReminder.value = minutes;
        Get.back();
      },
      selectedColor: Colors.amber.withValues(alpha: 0.3),
      checkmarkColor: Colors.amber,
      side: BorderSide(color: isSelected ? Colors.amber : Colors.grey.shade300),
    );
  }

  void _showAddCategoryDialog(
    QuickAddController controller,
    BuildContext context,
  ) {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('add_new_category'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'enter_category_name'.tr,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                controller.addCategory(textController.text.trim());
                Get.back();
              }
            },
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }

  // Helper method to build inline priority button
  Widget _buildPriorityButton(
    QuickAddController controller,
    Priority priority,
    String label,
    Color color,
    IconData icon,
  ) {
    final isSelected = controller.selectedPriority.value == priority;
    return InkWell(
      onTap: () {
        controller.selectedPriority.value = priority;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _getNextSunday() {
    final now = DateTime.now();
    final daysUntilSunday = (7 - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }
}
