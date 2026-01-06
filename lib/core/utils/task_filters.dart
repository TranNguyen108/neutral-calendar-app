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
    return where((task) {
      if (task.status == TaskStatus.done) return false;

      // High priority tasks
      if (task.priority == Priority.high) return true;

      // Overdue tasks
      if (task.isOverdue) return true;

      // Tasks starting within urgent threshold
      if (task.startTime != null) {
        final diff = task.startTime!.difference(now);
        if (diff.inMinutes > 0 &&
            diff.inMinutes <= AppConstants.urgentTaskThresholdMinutes) {
          return true;
        }
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
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) {
      // Overdue tasks first
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;

      // Then by priority (high to low)
      if (a.priority != b.priority) {
        return b.priority.index - a.priority.index;
      }

      // Then by time
      if (a.startTime == null && b.startTime == null) return 0;
      if (a.startTime == null) return 1;
      if (b.startTime == null) return -1;
      return a.startTime!.compareTo(b.startTime!);
    });
    return sorted;
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
