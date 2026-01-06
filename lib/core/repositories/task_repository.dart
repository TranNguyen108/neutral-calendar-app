import '../models/task.dart';

/// Abstract repository interface for task data operations
/// Makes it easy to swap storage implementations and improves testability
abstract class TaskRepository {
  /// Get all tasks
  List<Task> getTasks();

  /// Get tasks for a specific date
  List<Task> getTasksForDate(DateTime date);

  /// Get a single task by ID
  Task? getTaskById(String id);

  /// Add a new task
  Future<void> addTask(Task task);

  /// Update an existing task
  Future<void> updateTask(Task task);

  /// Delete a task by ID
  Future<void> deleteTask(String taskId);

  /// Search tasks with filters
  List<Task> searchTasks(
    String query, {
    List<String>? categories,
    List<Priority>? priorities,
    List<TaskStatus>? statuses,
  });

  /// Get all unique categories
  List<String> getAllCategories();

  /// Get total completed tasks count
  int getTotalCompletedTasks();

  /// Get subtasks for a specific parent task
  List<Task> getSubtasks(String parentTaskId);

  /// Add a subtask to a parent task
  /// Automatically sets parentTaskId and subtaskOrder
  Future<void> addSubtask(String parentTaskId, Task subtask);

  /// Update a subtask and recalculate parent progress
  Future<void> updateSubtask(Task subtask);

  /// Delete a subtask and recalculate parent progress
  Future<void> deleteSubtask(String subtaskId);

  /// Toggle subtask completion status and update parent
  Future<void> toggleSubtaskStatus(String subtaskId);

  /// Calculate completion progress of a task including its subtasks
  /// Returns a value between 0.0 and 1.0
  /// Optional visitedIds parameter to prevent infinite recursion in circular references
  double calculateTaskProgress(String taskId, {Set<String>? visitedIds});

  /// Update parent task status based on all subtasks
  /// Auto-marks parent as done if all subtasks are done
  /// Auto-marks parent as in-progress if any subtask is in-progress
  Future<void> updateParentTaskStatus(String parentTaskId);

  /// Reorder subtasks within their parent
  Future<void> reorderSubtasks(String parentTaskId, List<String> subtaskIds);

  /// Clear all tasks
  Future<void> clearAll();
}
