import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task.dart';
import '../controllers/task_quick_view_controller.dart';

class TaskQuickView {
  static void show(Task task) {
    Get.put(TaskQuickViewController());

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
          child: GetBuilder<TaskQuickViewController>(
            builder: (controller) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: controller.deleteTask,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status toggle
                Card(
                  child: ListTile(
                    leading: Icon(
                      task.status == TaskStatus.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: task.status == TaskStatus.done
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(
                      task.status == TaskStatus.done
                          ? 'Completed'
                          : 'Mark as Complete',
                    ),
                    onTap: controller.toggleStatus,
                  ),
                ),
                const SizedBox(height: 12),

                // Date & Time
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEE, MMM d, yyyy').format(task.date),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        if (task.startTime != null || task.endTime != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${task.startTime != null ? DateFormat('HH:mm').format(task.startTime!) : '?'} - ${task.endTime != null ? DateFormat('HH:mm').format(task.endTime!) : '?'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Priority selector
                Text(
                  'priority'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Row(
                      children: [
                        Expanded(
                          child: _buildPriorityChip(
                            controller,
                            Priority.low,
                            'low'.tr,
                            Colors.green,
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
                            Priority.high,
                            'high'.tr,
                            Colors.red,
                          ),
                        ),
                      ],
                    )),
                const SizedBox(height: 16),

                // Reminder selector
                Text(
                  'reminder'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      children: [
                        _buildReminderChip(controller, null, 'None'),
                        _buildReminderChip(controller, 5, '5 min'),
                        _buildReminderChip(controller, 15, '15 min'),
                        _buildReminderChip(controller, 30, '30 min'),
                        _buildReminderChip(controller, 60, '1 hour'),
                      ],
                    )),
                const SizedBox(height: 16),

                // Recurrence selector
                Text(
                  'recurrence'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      children: [
                        _buildRecurrenceChip(
                            controller, RecurrenceRule.none, 'none'.tr),
                        _buildRecurrenceChip(
                            controller, RecurrenceRule.daily, 'daily'.tr),
                        _buildRecurrenceChip(
                            controller, RecurrenceRule.weekly, 'weekly'.tr),
                        _buildRecurrenceChip(
                            controller, RecurrenceRule.monthly, 'monthly'.tr),
                      ],
                    )),
                const SizedBox(height: 16),

                // Note
                Text(
                  'note'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.noteController,
                  decoration: InputDecoration(
                    hintText: 'add_note'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: controller.updateTask,
                    icon: const Icon(Icons.save),
                    label: Text('save_changes'.tr),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
    );
  }

  static Widget _buildPriorityChip(
    TaskQuickViewController controller,
    Priority priority,
    String label,
    Color color,
  ) {
    final isSelected = controller.selectedPriority.value == priority;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.selectedPriority.value = priority,
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
    );
  }

  static Widget _buildReminderChip(
    TaskQuickViewController controller,
    int? minutes,
    String label,
  ) {
    final isSelected = controller.selectedReminder.value == minutes;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.selectedReminder.value = minutes,
      selectedColor: Colors.blue.withValues(alpha: 0.2),
      checkmarkColor: Colors.blue,
    );
  }

  static Widget _buildRecurrenceChip(
    TaskQuickViewController controller,
    RecurrenceRule rule,
    String label,
  ) {
    final isSelected = controller.selectedRecurrence.value == rule;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.selectedRecurrence.value = rule,
      selectedColor: Colors.purple.withValues(alpha: 0.2),
      checkmarkColor: Colors.purple,
    );
  }
}
