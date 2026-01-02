import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/add_task_controller.dart';
import '../../../core/models/task.dart';

class AddTaskView extends GetView<AddTaskController> {
  const AddTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AddTaskController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() =>
            Text(controller.isEditing.value ? 'edit_task'.tr : 'add_task'.tr)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: controller.titleController,
              decoration: InputDecoration(
                labelText: 'title_required'.tr,
                hintText: 'enter_title'.tr,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // Date
            Obx(() => InkWell(
                  onTap: () => controller.pickDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'date'.tr,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('EEEE, MMMM d, y')
                        .format(controller.selectedDate.value)),
                  ),
                )),
            const SizedBox(height: 20),

            // Time Range
            Row(
              children: [
                Expanded(
                  child: Obx(() => InkWell(
                        onTap: () => controller.pickStartTime(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'start_time'.tr,
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.access_time),
                          ),
                          child: Text(
                            controller.selectedStartTime.value
                                    ?.format(context) ??
                                'select_time'.tr,
                          ),
                        ),
                      )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => InkWell(
                        onTap: () => controller.pickEndTime(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'end_time'.tr,
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.access_time),
                          ),
                          child: Text(
                            controller.selectedEndTime.value?.format(context) ??
                                'Select time',
                          ),
                        ),
                      )),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Priority
            Text('priority'.tr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _buildPriorityButton(
                          Priority.high, Colors.red, 'high'.tr),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriorityButton(
                          Priority.medium, Colors.orange, 'medium'.tr),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriorityButton(
                          Priority.low, Colors.green, 'low'.tr),
                    ),
                  ],
                )),
            const SizedBox(height: 20),

            // Category
            Text('category'.tr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCategoryChip('work'.tr),
                    _buildCategoryChip('study'.tr),
                    _buildCategoryChip('health'.tr),
                    _buildCategoryChip('personal'.tr),
                    _buildCategoryChip('other'.tr),
                  ],
                )),
            const SizedBox(height: 20),

            // Recurrence
            Text('recurrence'.tr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRecurrenceChip(RecurrenceRule.none, 'none'.tr),
                    _buildRecurrenceChip(RecurrenceRule.daily, 'daily'.tr),
                    _buildRecurrenceChip(RecurrenceRule.weekly, 'weekly'.tr),
                    _buildRecurrenceChip(RecurrenceRule.monthly, 'monthly'.tr),
                  ],
                )),
            const SizedBox(height: 20),

            // Reminder
            Text('reminder'.tr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildReminderChip(null, 'no_reminder'.tr),
                    _buildReminderChip(5, '5_min_before'.tr),
                    _buildReminderChip(15, '15_min_before'.tr),
                    _buildReminderChip(30, '30_min_before'.tr),
                    _buildReminderChip(60, '1_hour_before'.tr),
                  ],
                )),
            const SizedBox(height: 20),

            // Note
            TextField(
              controller: controller.noteController,
              decoration: InputDecoration(
                labelText: 'note'.tr,
                hintText: 'add_note'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.saveTask,
                child: Obx(() => Text(
                      controller.isEditing.value
                          ? 'update_task'.tr
                          : 'add_task'.tr,
                      style: const TextStyle(fontSize: 16),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(Priority priority, Color color, String label) {
    final isSelected = controller.selectedPriority.value == priority;
    return InkWell(
      onTap: () => controller.selectedPriority.value = priority,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = controller.selectedCategory.value == category;
    final color = _getCategoryColor(category);

    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        controller.selectedCategory.value = selected ? category : null;
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildRecurrenceChip(RecurrenceRule rule, String label) {
    final isSelected = controller.selectedRecurrence.value == rule;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        controller.selectedRecurrence.value = rule;
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildReminderChip(int? minutes, String label) {
    final isSelected = controller.selectedReminder.value == minutes;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        controller.selectedReminder.value = minutes;
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.orange : Colors.grey.shade300,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blue;
      case 'study':
        return Colors.purple;
      case 'health':
        return Colors.green;
      case 'personal':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
