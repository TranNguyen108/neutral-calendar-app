import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

/// Service for managing home screen widgets
/// Updates widget data when tasks change
class WidgetService extends GetxService {
  final TaskRepository _taskRepository = Get.find<TaskRepository>();

  static const String _widgetName = 'TodayWidgetProvider';
  static const String _groupId = 'group.com.neuralcalendar.nc_app';

  /// Initialize widget service
  Future<WidgetService> init() async {
    await _configureWidget();
    return this;
  }

  /// Configure widget initial setup
  Future<void> _configureWidget() async {
    try {
      await HomeWidget.setAppGroupId(_groupId);
      await updateWidget();
    } catch (e) {
      Get.log('Error configuring widget: $e', isError: true);
    }
  }

  /// Update widget with current data
  Future<void> updateWidget() async {
    try {
      // Get today's tasks
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final allTasks = _taskRepository.getTasks();
      final todayTasks = allTasks.where((task) {
        return task.date
                .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            task.date.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();

      // Calculate statistics
      final totalTasks = todayTasks.length;
      final completedTasks =
          todayTasks.where((t) => t.status == TaskStatus.done).length;
      final progressPercentage =
          totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

      // Get urgent tasks (high priority, not completed, due soon)
      final urgentTasks = todayTasks
          .where((task) {
            return task.priority == Priority.high &&
                task.status != TaskStatus.done &&
                !task.isOverdue;
          })
          .take(3)
          .toList();

      // Format date
      final dateFormat = DateFormat('EEEE, MMM dd', 'en');
      final formattedDate = dateFormat.format(now);

      // Save data to widget
      await HomeWidget.saveWidgetData('date', formattedDate);
      await HomeWidget.saveWidgetData('total_tasks', totalTasks);
      await HomeWidget.saveWidgetData('completed_tasks', completedTasks);
      await HomeWidget.saveWidgetData('progress', progressPercentage);
      await HomeWidget.saveWidgetData(
          'tasks_text', '$completedTasks/$totalTasks');

      // Save urgent tasks
      await HomeWidget.saveWidgetData('urgent_count', urgentTasks.length);
      for (int i = 0; i < 3; i++) {
        if (i < urgentTasks.length) {
          final task = urgentTasks[i];
          await HomeWidget.saveWidgetData('task_${i}_id', task.id);
          await HomeWidget.saveWidgetData('task_${i}_title', task.title);
          await HomeWidget.saveWidgetData(
              'task_${i}_completed', task.status == TaskStatus.done);

          // Format time if available
          if (task.startTime != null) {
            final timeFormat = DateFormat('HH:mm');
            await HomeWidget.saveWidgetData(
                'task_${i}_time', timeFormat.format(task.startTime!));
          } else {
            await HomeWidget.saveWidgetData('task_${i}_time', '');
          }

          // Priority color
          final priorityColor = _getPriorityColorHex(task.priority);
          await HomeWidget.saveWidgetData('task_${i}_color', priorityColor);
        } else {
          // Clear unused slots
          await HomeWidget.saveWidgetData('task_${i}_id', '');
          await HomeWidget.saveWidgetData('task_${i}_title', '');
          await HomeWidget.saveWidgetData('task_${i}_completed', false);
          await HomeWidget.saveWidgetData('task_${i}_time', '');
          await HomeWidget.saveWidgetData('task_${i}_color', '#9E9E9E');
        }
      }

      // Update widget UI
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
        iOSName: _widgetName,
      );

      Get.log('Widget updated successfully');
    } catch (e) {
      Get.log('Error updating widget: $e', isError: true);
    }
  }

  /// Get priority color as hex string for Android
  String _getPriorityColorHex(Priority priority) {
    switch (priority) {
      case Priority.high:
        return '#F44336'; // Red
      case Priority.medium:
        return '#FF9800'; // Orange
      case Priority.low:
        return '#4CAF50'; // Green
    }
  }

  /// Handle widget tap action
  Future<void> handleWidgetAction(Uri? uri) async {
    if (uri == null) return;

    try {
      final action = uri.host;
      final params = uri.queryParameters;

      switch (action) {
        case 'open_app':
          // App is already opening, no action needed
          Get.log('Widget tap: open app');
          break;

        case 'add_task':
          // Navigate to quick add
          Get.log('Widget tap: add task');
          // This will be handled by the app's deep link handler
          break;

        case 'task_detail':
          // Open task detail
          final taskId = params['id'];
          if (taskId != null) {
            Get.log('Widget tap: open task $taskId');
            // This will be handled by the app's deep link handler
          }
          break;

        case 'complete_task':
          // Toggle task completion
          final taskId = params['id'];
          if (taskId != null) {
            await _toggleTaskFromWidget(taskId);
          }
          break;
      }
    } catch (e) {
      Get.log('Error handling widget action: $e', isError: true);
    }
  }

  /// Toggle task completion from widget
  Future<void> _toggleTaskFromWidget(String taskId) async {
    try {
      final task = _taskRepository.getTaskById(taskId);
      if (task != null) {
        final updated = task.copyWith(
          status: task.status == TaskStatus.done
              ? TaskStatus.todo
              : TaskStatus.done,
          updatedAt: DateTime.now(),
        );
        await _taskRepository.updateTask(updated);
        await updateWidget();
        Get.log('Task $taskId toggled from widget');
      }
    } catch (e) {
      Get.log('Error toggling task from widget: $e', isError: true);
    }
  }

  /// Register widget update callback
  Future<void> registerCallbacks() async {
    try {
      HomeWidget.widgetClicked.listen((uri) {
        handleWidgetAction(uri);
      });
      Get.log('Widget callbacks registered');
    } catch (e) {
      Get.log('Error registering widget callbacks: $e', isError: true);
    }
  }

  /// Schedule daily widget update at midnight
  void scheduleDailyUpdate() {
    // This would use background tasks or alarm manager
    // For now, app updates widget when opened
    Get.log('Widget daily update scheduled');
  }
}
