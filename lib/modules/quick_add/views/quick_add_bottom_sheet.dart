import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quick_add_controller.dart';
import '../../../core/models/task.dart';

class QuickAddBottomSheet extends StatelessWidget {
  const QuickAddBottomSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const QuickAddBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuickAddController());

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),

            // Title Field
            TextField(
              controller: controller.titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'enter_title'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.saveQuickTask(),
            ),
            const SizedBox(height: 16),

            // Time Picker
            Obx(() => InkWell(
                  onTap: () => controller.pickTime(context),
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
            const SizedBox(height: 16),

            // Priority Selector
            Text('priority'.tr,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
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
            const SizedBox(height: 24),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.saveQuickTask,
                child: Text(
                  'add_task'.tr,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
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
    return ChoiceChip(
      label: Center(child: Text(label)),
      selected: isSelected,
      onSelected: (_) => controller.selectedPriority.value = priority,
      selectedColor: color.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
    );
  }
}
