import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/task.dart';
import '../../../core/repositories/task_repository.dart';
import '../../../routes/app_routes.dart';
import '../../quick_add/views/quick_add_bottom_sheet.dart';
import '../../add_item/views/add_item_bottom_sheet.dart';
import '../../task_quick_view/views/task_quick_view.dart';
import '../controllers/today_controller.dart';
import 'widgets/suggestions_card.dart';

class TodayView extends GetView<TodayController> {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(TodayController());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('today_title'.tr),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed(AppRoutes.search),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Obx(
          () => RefreshIndicator(
            onRefresh: () async {
              controller.loadTodayTasks();
            },
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.getFormattedDate(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProgressCard(),
                      ],
                    ),
                  ),
                ),
                // Smart Suggestions Section
                SliverToBoxAdapter(
                  child: SuggestionsCard(),
                ),
                // Urgent Tasks Section
                SliverToBoxAdapter(
                  child: Obx(() {
                    if (controller.urgentTasks.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.priority_high,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'urgent_tasks'.tr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...controller.urgentTasks.map(
                              (task) => _buildTaskCard(task, isUrgent: true)),
                        ],
                      ),
                    );
                  }),
                ),
                // Tasks Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'all_tasks'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Tasks List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: controller.tasks.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'no_tasks_today'.tr,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'tap_add_task'.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              // Trigger load more when reaching near the end
                              if (index == controller.tasks.length - 5 &&
                                  controller.hasMoreTasks.value &&
                                  !controller.isLoadingMore.value) {
                                controller.loadMoreTasks();
                              }

                              final task = controller.tasks[index];
                              return _buildTaskCard(task);
                            },
                            childCount: controller.tasks.length,
                          ),
                        ),
                ),
                // Loading indicator for pagination
                SliverToBoxAdapter(
                  child: Obx(() {
                    if (controller.isLoadingMore.value) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                'loading_more'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    // Show "Load More" button if there are more tasks
                    else if (controller.hasMoreTasks.value &&
                        controller.tasks.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: controller.loadMoreTasks,
                            icon: const Icon(Icons.expand_more),
                            label: Text('load_more'.tr),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ),
                // Planning Prompt Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => AddItemBottomSheet.show(),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'planning_prompt'.tr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to add TODO, Event, Note, or Diary',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuickAddBottomSheet.show(),
        tooltip: 'quick_add'.tr,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'today_progress'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tasks_count'
                          .tr
                          .replaceAll(
                              '@completed', '${controller.completedTasks}')
                          .replaceAll('@total', '${controller.totalTasks}'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    '${controller.progressPercentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: controller.progressPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, {bool isUrgent = false}) {
    final isOverdue = task.isOverdue;
    final cardColor = isOverdue ? Colors.red.shade50 : null;
    final borderColor =
        isOverdue ? Colors.red : (isUrgent ? Colors.orange : null);

    return Dismissible(
      key: Key(task.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Left to right swipe - Complete task
          controller.toggleTaskStatus(task);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Right to left swipe - Show options menu
          final result = await Get.dialog<String>(
            AlertDialog(
              title: Text('task_actions'.tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.event_available, color: Colors.blue),
                    title: Text('reschedule_tomorrow'.tr),
                    onTap: () => Get.back(result: 'tomorrow'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.orange),
                    title: Text('delay_one_hour'.tr),
                    onTap: () => Get.back(result: 'delay'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text('delete'.tr),
                    onTap: () => Get.back(result: 'delete'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('cancel'.tr),
                ),
              ],
            ),
          );

          if (result == 'tomorrow') {
            await controller.rescheduleToTomorrow(task);
            return false;
          } else if (result == 'delay') {
            await controller.delayOneHour(task);
            return false;
          } else if (result == 'delete') {
            return true;
          }
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          controller.deleteTask(task);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          color: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              TaskQuickView.show(task);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox
                  InkWell(
                    onTap: () => controller.toggleTaskStatus(task),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.status == TaskStatus.done
                              ? Colors.green
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: task.status == TaskStatus.done
                            ? Colors.green
                            : Colors.transparent,
                      ),
                      child: task.status == TaskStatus.done
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Task Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: task.status == TaskStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (task.startTime != null) ...[
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('HH:mm').format(task.startTime!)}${task.endTime != null ? ' - ${DateFormat('HH:mm').format(task.endTime!)}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            if (task.durationMinutes != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${_formatDuration(task.durationMinutes!)})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (task.startTime != null ||
                                task.durationMinutes != null)
                              const SizedBox(width: 12),
                            if (task.category != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(task.category!)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task.category!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getCategoryColor(task.category!),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Subtask progress indicator
                        _buildSubtaskProgress(task),
                        // Attachment count indicator
                        if (task.attachments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.attach_file,
                                    size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${task.attachments.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Priority Indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtaskProgress(Task task) {
    final taskRepo = Get.find<TaskRepository>();
    final subtasks = taskRepo.getSubtasks(task.id);

    if (subtasks.isEmpty) return const SizedBox.shrink();

    final completed = subtasks.where((s) => s.status == TaskStatus.done).length;
    final progress = taskRepo.calculateTaskProgress(task.id);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.checklist, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            '$completed/${subtasks.length}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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

String _formatDuration(int minutes) {
  if (minutes < 60) {
    return '$minutes min';
  } else {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }
}
