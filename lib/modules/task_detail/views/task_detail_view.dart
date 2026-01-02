import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/recurrence_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../routes/app_routes.dart';
import '../../today/controllers/today_controller.dart';
import '../../calendar/controllers/calendar_controller.dart';

class TaskDetailView extends StatelessWidget {
  const TaskDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final Task task = Get.arguments as Task;
    final storage = Get.find<StorageService>();
    final recurrence = Get.find<RecurrenceService>();
    final notifications = Get.find<NotificationService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.toNamed(AppRoutes.ADD_TASK, arguments: task);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('Delete Task'),
                  content:
                      const Text('Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await storage.deleteTask(task.id);
                        // Cancel notification when deleting task
                        await notifications.cancelTaskReminder(task.id);
                        Get.back(); // Close dialog
                        Get.back(); // Go back to previous screen
                        Get.snackbar('Success', 'Task deleted');

                        // Reload controllers
                        if (Get.isRegistered<TodayController>()) {
                          Get.find<TodayController>().loadTodayTasks();
                        }
                        if (Get.isRegistered<CalendarController>()) {
                          Get.find<CalendarController>().loadTasks();
                        }
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Date & Time Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Date',
                      DateFormat('EEEE, MMMM d, y').format(task.date),
                    ),
                    if (task.startTime != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.access_time,
                        'Time',
                        '${DateFormat('HH:mm').format(task.startTime!)}${task.endTime != null ? ' - ${DateFormat('HH:mm').format(task.endTime!)}' : ''}',
                      ),
                    ],
                    if (task.durationMinutes != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.timer,
                        'Duration',
                        _formatDuration(task.durationMinutes!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.flag,
                      'Priority',
                      task.priority.name.toUpperCase(),
                      color: _getPriorityColor(task.priority),
                    ),
                    if (task.category != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.label,
                        'Category',
                        task.category!,
                        color: _getCategoryColor(task.category!),
                      ),
                    ],
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.check_circle,
                      'Status',
                      task.status.name.toUpperCase(),
                      color: task.status == TaskStatus.done
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            if (task.note != null && task.note!.isNotEmpty) ...[
              const Text(
                'Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    task.note!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Metadata
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMetadataRow('Created', task.createdAt),
                    const SizedBox(height: 8),
                    _buildMetadataRow('Last Updated', task.updatedAt),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            final updatedTask = task.copyWith(
              status: task.status == TaskStatus.done
                  ? TaskStatus.todo
                  : TaskStatus.done,
              updatedAt: DateTime.now(),
            );
            await storage.updateTask(updatedTask);

            // Generate next occurrence if marking as done and task is recurring
            if (updatedTask.status == TaskStatus.done) {
              await recurrence.handleTaskCompletion(updatedTask);
            }

            Get.back();
            Get.snackbar(
                'Success',
                task.status == TaskStatus.done
                    ? 'Task marked as todo'
                    : 'Task completed!');

            // Reload controllers
            if (Get.isRegistered<TodayController>()) {
              Get.find<TodayController>().loadTodayTasks();
            }
            if (Get.isRegistered<CalendarController>()) {
              Get.find<CalendarController>().loadTasks();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                task.status == TaskStatus.done ? Colors.orange : Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            task.status == TaskStatus.done ? 'Mark as Todo' : 'Mark as Done',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, DateTime date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          DateFormat('MMM d, y HH:mm').format(date),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
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
}
