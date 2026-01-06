import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task.dart';
import '../../../core/models/attachment.dart';
import '../../../core/repositories/task_repository.dart';
import '../../../core/repositories/project_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/recurrence_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/attachment_service.dart';
import '../../today/controllers/today_controller.dart';
import '../../calendar/controllers/calendar_controller.dart';

class TaskDetailView extends StatefulWidget {
  const TaskDetailView({super.key});

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late Task task;
  late StorageService storage;
  late TaskRepository taskRepo;
  late RecurrenceService recurrence;
  late NotificationService notifications;
  late AttachmentService attachmentService;
  late ProjectRepository projectRepo;
  List<Task> subtasks = [];
  final subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    task = Get.arguments as Task;
    storage = Get.find<StorageService>();
    taskRepo = Get.find<TaskRepository>();
    recurrence = Get.find<RecurrenceService>();
    attachmentService = Get.find<AttachmentService>();
    notifications = Get.find<NotificationService>();
    _loadSubtasks();
  }

  @override
  void dispose() {
    subtaskController.dispose();
    super.dispose();
  }

  void _loadSubtasks() {
    setState(() {
      subtasks = taskRepo.getSubtasks(task.id);
    });
  }

  Future<void> _addSubtask() async {
    if (subtaskController.text.trim().isEmpty) return;

    final subtask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: subtaskController.text.trim(),
      date: task.date,
      priority: Priority.medium,
      status: TaskStatus.todo,
      category: task.category,
      projectId: task.projectId,
      sectionId: task.sectionId,
      parentTaskId: task.id,
      subtaskOrder: subtasks.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await storage.addTask(subtask);
    subtaskController.clear();
    _loadSubtasks();
    setState(() {});
  }

  Future<void> _toggleSubtask(Task subtask) async {
    final updated = subtask.copyWith(
      status: subtask.status == TaskStatus.done
          ? TaskStatus.todo
          : TaskStatus.done,
      updatedAt: DateTime.now(),
    );
    await storage.updateTask(updated);
    _loadSubtasks();
    setState(() {});
  }

  Future<void> _deleteSubtask(Task subtask) async {
    await storage.deleteTask(subtask.id);
    _loadSubtasks();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final progress = subtasks.isEmpty
        ? (task.status == TaskStatus.done ? 1.0 : 0.0)
        : taskRepo.calculateTaskProgress(task.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('Delete Task'),
                  content: const Text(
                    'Are you sure you want to delete this task?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Delete all subtasks first
                        for (final subtask in subtasks) {
                          await storage.deleteTask(subtask.id);
                        }
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
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
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
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Progress indicator (if has subtasks)
            if (subtasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade400,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.projectId != null) ...[
                      _buildInfoRow(
                        Icons.folder,
                        'Project',
                        projectRepo.getById(task.projectId!)?.name ?? 'Inbox',
                        color: projectRepo.getById(task.projectId!)?.color,
                      ),
                    ],
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(task.note!),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 24),

            // Subtasks Section
            const Text(
              'Subtasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Subtask list
            if (subtasks.isNotEmpty) ...[
              Card(
                child: Column(
                  children: subtasks.map((subtask) {
                    return ListTile(
                      leading: Checkbox(
                        value: subtask.status == TaskStatus.done,
                        onChanged: (_) => _toggleSubtask(subtask),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Text(
                        subtask.title,
                        style: TextStyle(
                          decoration: subtask.status == TaskStatus.done
                              ? TextDecoration.lineThrough
                              : null,
                          color: subtask.status == TaskStatus.done
                              ? Colors.grey
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _deleteSubtask(subtask),
                        color: Colors.grey,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Add subtask input
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: subtaskController,
                        decoration: InputDecoration(
                          hintText: 'add_subtask'.tr,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, size: 20),
                      onPressed: _addSubtask,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Task details
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(task.note!, style: const TextStyle(fontSize: 16)),
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

            const SizedBox(height: 24),

            // Attachments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attachments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAttachmentPicker,
                  tooltip: 'Add Attachment',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Attachments grid
            Builder(
              builder: (context) {
                if (task.attachments.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No attachments',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: task.attachments.length,
                  itemBuilder: (context, index) {
                    final attachment = task.attachments[index];
                    return _buildAttachmentCard(attachment);
                  },
                );
              },
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
                  : 'Task completed!',
            );

            // Reload controllers
            if (Get.isRegistered<TodayController>()) {
              Get.find<TodayController>().loadTodayTasks();
            }
            if (Get.isRegistered<CalendarController>()) {
              Get.find<CalendarController>().loadTasks();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: task.status == TaskStatus.done
                ? Colors.orange
                : Colors.green,
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Get.back();
                final attachment = await attachmentService
                    .pickImageFromCamera();
                if (attachment != null) {
                  _addAttachment(attachment);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Get.back();
                final attachment = await attachmentService
                    .pickImageFromGallery();
                if (attachment != null) {
                  _addAttachment(attachment);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Choose File'),
              onTap: () async {
                Get.back();
                final attachment = await attachmentService.pickFile();
                if (attachment != null) {
                  _addAttachment(attachment);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAttachment(Attachment attachment) async {
    final updatedTask = task.copyWith(
      attachments: [...task.attachments, attachment],
      updatedAt: DateTime.now(),
    );
    await storage.updateTask(updatedTask);
    setState(() {
      task = updatedTask;
    });
    Get.snackbar('Success', 'Attachment added');
  }

  Future<void> _removeAttachment(Attachment attachment) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Attachment'),
        content: Text(
          'Are you sure you want to delete ${attachment.fileName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await attachmentService.deleteAttachment(attachment);
      final updatedTask = task.copyWith(
        attachments: task.attachments
            .where((a) => a.id != attachment.id)
            .toList(),
        updatedAt: DateTime.now(),
      );
      await storage.updateTask(updatedTask);
      setState(() {
        task = updatedTask;
      });
      Get.snackbar('Success', 'Attachment deleted');
    }
  }

  Widget _buildAttachmentCard(Attachment attachment) {
    return GestureDetector(
      onTap: () => _viewAttachment(attachment),
      onLongPress: () => _removeAttachment(attachment),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail or icon
            if (attachment.type == AttachmentType.image &&
                attachment.thumbnailPath != null)
              Image.file(File(attachment.thumbnailPath!), fit: BoxFit.cover)
            else
              Container(
                color: attachment.color.withValues(alpha: 0.1),
                child: Icon(attachment.icon, size: 40, color: attachment.color),
              ),
            // File size badge
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  attachment.formattedSize,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewAttachment(Attachment attachment) {
    if (attachment.type == AttachmentType.image) {
      Get.dialog(
        Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(attachment.fileName),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      Get.back();
                      _removeAttachment(attachment);
                    },
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.file(
                    File(attachment.filePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      Get.snackbar(
        'File Info',
        '${attachment.fileName}\n${attachment.formattedSize}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
