import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task.dart';
import '../../../routes/app_routes.dart';
import '../controllers/search_controller.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TaskSearchController());

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'search_tasks'.tr,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: controller.updateSearchQuery,
        ),
        actions: [
          Obx(() {
            final hasFilters = controller.selectedCategories.isNotEmpty ||
                controller.selectedPriorities.isNotEmpty ||
                controller.selectedStatuses.isNotEmpty;

            return hasFilters
                ? IconButton(
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'clear_filters'.tr,
                    onPressed: controller.clearFilters,
                  )
                : const SizedBox.shrink();
          }),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Section
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Category filters
                  Obx(() {
                    if (controller.allCategories.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Wrap(
                      spacing: 8,
                      children: controller.allCategories.map((category) {
                        final isSelected =
                            controller.selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) =>
                              controller.toggleCategory(category),
                        );
                      }).toList(),
                    );
                  }),

                  const SizedBox(width: 8),

                  // Priority filters
                  ...Priority.values.map((priority) {
                    return Obx(() {
                      final isSelected =
                          controller.selectedPriorities.contains(priority);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(priority.name.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) =>
                              controller.togglePriority(priority),
                          backgroundColor:
                              _getPriorityColor(priority).withValues(alpha: 0.1),
                          selectedColor:
                              _getPriorityColor(priority).withValues(alpha: 0.3),
                        ),
                      );
                    });
                  }),

                  const SizedBox(width: 8),

                  // Status filters
                  ...TaskStatus.values.map((status) {
                    return Obx(() {
                      final isSelected =
                          controller.selectedStatuses.contains(status);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.name.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) => controller.toggleStatus(status),
                        ),
                      );
                    });
                  }),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Search Results
          Expanded(
            child: Obx(() {
              final results = controller.searchResults;

              if (results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'no_results'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final task = results[index];
                  return _buildTaskCard(context, task);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Get.toNamed(AppRoutes.taskDetail, arguments: task),
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(task.priority).withValues(alpha: 0.2),
          child: Icon(
            task.status == TaskStatus.done
                ? Icons.check_circle
                : Icons.circle_outlined,
            color: _getPriorityColor(task.priority),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.done
                ? TextDecoration.lineThrough
                : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, y').format(task.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (task.startTime != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.access_time,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(task.startTime!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            if (task.category != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor(task.category!).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.category!,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getCategoryColor(task.category!),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
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
