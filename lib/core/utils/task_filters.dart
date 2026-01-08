import '../constants/app_constants.dart';
import '../models/task.dart';

/// Extension methods for filtering and querying lists of tasks
extension TaskListFilters on List<Task> {
  /// Returns tasks for a specific date (ignoring time)
  List<Task> forDate(DateTime date) {
    return where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
  }

  /// Returns tasks for today
  List<Task> forToday() {
    return forDate(DateTime.now());
  }

  /// Returns only incomplete tasks (not done)
  List<Task> incomplete() {
    return where((task) => task.status != TaskStatus.done).toList();
  }

  /// Returns only completed tasks
  List<Task> completed() {
    return where((task) => task.status == TaskStatus.done).toList();
  }

  /// Returns only overdue tasks
  List<Task> overdue() {
    return where((task) => task.isOverdue).toList();
  }

  /// Returns tasks with high priority
  List<Task> highPriority() {
    return where((task) => task.priority == Priority.high).toList();
  }

  /// Returns urgent tasks (high priority, overdue, or starting soon)
  /// Takes up to [limit] tasks (default: 3)
  List<Task> urgent({int limit = 3}) {
    final now = DateTime.now();
    const threshold = AppConstants.urgentTaskThresholdMinutes;

    return where((task) {
      // Skip completed tasks early
      if (task.status == TaskStatus.done) return false;

      // High priority or overdue tasks
      if (task.priority == Priority.high || task.isOverdue) return true;

      // Tasks starting within threshold (combine conditions)
      if (task.startTime != null) {
        final diffMinutes = task.startTime!.difference(now).inMinutes;
        return diffMinutes > 0 && diffMinutes <= threshold;
      }

      return false;
    }).take(limit).toList();
  }

  /// Returns tasks for today that are incomplete
  List<Task> todayIncomplete() {
    return forToday().incomplete();
  }

  /// Sorts tasks by: overdue first, then priority (high to low), then by start time
  List<Task> sortedByUrgency() {
    return List<Task>.from(this)
      ..sort((a, b) {
        // Overdue tasks first
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;

        // Then by priority (high to low)
        final priorityCompare = b.priority.index - a.priority.index;
        if (priorityCompare != 0) return priorityCompare;

        // Then by start time (nulls last)
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });
  }

  /// Returns tasks for a specific project
  List<Task> forProject(String projectId) {
    return where((task) => task.projectId == projectId).toList();
  }

  /// Returns tasks for a specific section
  List<Task> forSection(String? sectionId) {
    return where((task) => task.sectionId == sectionId).toList();
  }
}
