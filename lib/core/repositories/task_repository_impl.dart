import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task.dart';
import '../repositories/repository_validators.dart';
import '../repositories/task_repository.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

/// Implementation of TaskRepository using StorageService
/// This layer abstracts storage details from business logic
class TaskRepositoryImpl with RepositoryValidators implements TaskRepository {
  final StorageService _storage;
  final Logger _logger = Get.find<Logger>();

  TaskRepositoryImpl(this._storage);

  @override
  List<Task> getTasks() {
    try {
      final tasks = _storage.getTasks();
      // Defensive check: filter out any null/invalid tasks
      return tasks
          .where((task) => task.id.isNotEmpty && task.title.isNotEmpty)
          .toList();
    } catch (e) {
      _logger.error('Error getting tasks', tag: 'TaskRepository', error: e);
      return []; // Safe fallback
    }
  }

  @override
  List<Task> getTasksForDate(DateTime date) {
    try {
      final tasks = _storage.getTasks();
      // Defensive check: validate tasks and filter by date
      return tasks.where((task) {
        if (task.id.isEmpty || task.title.isEmpty) return false;
        return isSameDay(task.date, date);
      }).toList();
    } catch (e) {
      _logger.error('Error getting tasks for date: $date',
          tag: 'TaskRepository', error: e);
      return []; // Safe fallback
    }
  }

  @override
  Task? getTaskById(String id) {
    try {
      // Defensive check: validate ID
      if (id.isEmpty) {
        _logger.warning('getTaskById called with empty ID',
            tag: 'TaskRepository');
        return null;
      }

      final tasks = _storage.getTasks();
      return tasks.firstWhere(
        (task) => task.id == id,
        orElse: () => throw Exception('Task not found'),
      );
    } catch (e) {
      // This is expected when task is not found, don't log as error
      if (e.toString().contains('Task not found')) {
        _logger.info('Task not found: $id', tag: 'TaskRepository');
      } else {
        _logger.error('Error getting task by ID: $id',
            tag: 'TaskRepository', error: e);
      }
      return null;
    }
  }

  @override
  Future<void> addTask(Task task) async {
    try {
      validateId(task.id, fieldName: 'task.id');
      validateName(task.title, fieldName: 'task.title');

      // Check for duplicate ID
      final existingTask = getTaskById(task.id);
      if (existingTask != null) {
        _logger.warning(
            'Task with ID ${task.id} already exists, updating instead',
            tag: 'TaskRepository');
        await updateTask(task);
        return;
      }

      await _storage.addTask(task);
      _logger.info('Task added: ${task.id}', tag: 'TaskRepository');
    } catch (e) {
      _logger.error('Error adding task: ${task.id}',
          tag: 'TaskRepository', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    try {
      validateId(task.id, fieldName: 'task.id');
      validateName(task.title, fieldName: 'task.title');

      // Verify task exists
      final existingTask = getTaskById(task.id);
      if (existingTask == null) {
        _logger.warning('Task not found for update: ${task.id}, adding instead',
            tag: 'TaskRepository');
        await addTask(task);
        return;
      }

      await _storage.updateTask(task);
      _logger.info('Task updated: ${task.id}', tag: 'TaskRepository');
    } catch (e) {
      _logger.error('Error updating task: ${task.id}',
          tag: 'TaskRepository', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      validateId(taskId, fieldName: 'taskId');

      // Check if task has subtasks and delete them first
      final subtasks = getSubtasks(taskId);
      if (subtasks.isNotEmpty) {
        _logger.warning(
            'Deleting task with ${subtasks.length} subtasks: $taskId',
            tag: 'TaskRepository');
        for (final subtask in subtasks) {
          await _storage.deleteTask(subtask.id);
        }
      }

      await _storage.deleteTask(taskId);
      _logger.info('Task deleted: $taskId', tag: 'TaskRepository');
    } catch (e) {
      _logger.error('Error deleting task: $taskId',
          tag: 'TaskRepository', error: e);
      rethrow;
    }
  }

  @override
  List<Task> searchTasks(
    String query, {
    List<String>? categories,
    List<Priority>? priorities,
    List<TaskStatus>? statuses,
  }) {
    try {
      final results = _storage.searchTasks(
        query,
        categories: categories,
        priorities: priorities,
        statuses: statuses,
      );
      // Defensive check: filter out invalid tasks
      return results
          .where((task) => task.id.isNotEmpty && task.title.isNotEmpty)
          .toList();
    } catch (e) {
      _logger.error('Error searching tasks with query: "$query"',
          tag: 'TaskRepository', error: e);
      return []; // Safe fallback
    }
  }

  @override
  List<String> getAllCategories() {
    try {
      final categories = _storage.getAllCategories();
      // Defensive check: filter out empty categories
      return categories.where((cat) => cat.trim().isNotEmpty).toList();
    } catch (e) {
      _logger.error('Error getting all categories',
          tag: 'TaskRepository', error: e);
      return []; // Safe fallback
    }
  }

  @override
  int getTotalCompletedTasks() {
    try {
      final tasks = _storage.getTasks();
      return tasks.where((t) => t.status == TaskStatus.done).length;
    } catch (e) {
      _logger.error('Error getting total completed tasks',
          tag: 'TaskRepository', error: e);
      return 0; // Safe fallback
    }
  }

  @override
  List<Task> getSubtasks(String parentTaskId) {
    try {
      // Defensive check: validate ID
      if (parentTaskId.isEmpty) {
        _logger.warning('getSubtasks called with empty parentTaskId',
            tag: 'TaskRepository');
        return [];
      }

      final tasks = _storage.getTasks();
      final subtasks = tasks
          .where((task) => task.parentTaskId == parentTaskId)
          .toList()
        ..sort((a, b) => a.subtaskOrder.compareTo(b.subtaskOrder));

      return subtasks;
    } catch (e) {
      _logger.error('Error getting subtasks for parent: $parentTaskId',
          tag: 'TaskRepository', error: e);
      return []; // Safe fallback
    }
  }

  @override
  Future<void> addSubtask(String parentTaskId, Task subtask) async {
    try {
      validateId(parentTaskId, fieldName: 'parentTaskId');
      validateId(subtask.id, fieldName: 'subtask.id');
      validateName(subtask.title, fieldName: 'subtask.title');

      // Verify parent task exists
      validateNotNull(getTaskById(parentTaskId), fieldName: 'parentTask');

      // Get next order number
      final existingSubtasks = getSubtasks(parentTaskId);
      final nextOrder = existingSubtasks.isEmpty
          ? 0
          : existingSubtasks
                  .map((s) => s.subtaskOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;

      final newSubtask = subtask.copyWith(
        parentTaskId: parentTaskId,
        subtaskOrder: nextOrder,
        updatedAt: DateTime.now(),
      );

      await _storage.addTask(newSubtask);
      _logger.info('Subtask added to parent $parentTaskId: ${newSubtask.id}',
          tag: 'TaskRepository');

      await updateParentTaskStatus(parentTaskId);
    } catch (e) {
      _logger.error('Error adding subtask to parent: $parentTaskId',
          tag: 'TaskRepository', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateSubtask(Task subtask) async {
    try {
      // Defensive checks
      if (subtask.id.isEmpty) {
        throw Exception('Cannot update subtask with empty ID');
      }
      if (!subtask.isSubtask) {
        throw Exception('Task ${subtask.id} is not a subtask');
      }
      if (subtask.title.trim().isEmpty) {
        throw Exception('Cannot update subtask with empty title');
      }

      // Verify subtask exists
      final existingSubtask = getTaskById(subtask.id);
      if (existingSubtask == null) {
        throw Exception('Subtask not found: ${subtask.id}');
      }

      await _storage.updateTask(subtask);
      _logger.info('Subtask updated: ${subtask.id}', tag: 'TaskRepository');

      // Update parent task status based on subtask changes
      if (subtask.parentTaskId != null) {
        await updateParentTaskStatus(subtask.parentTaskId!);
      }
    } catch (e) {
      _logger.error('Error updating subtask: ${subtask.id}',
          tag: 'TaskRepository', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteSubtask(String subtaskId) async {
    try {
      // Defensive check
      if (subtaskId.isEmpty) {
        throw Exception('Cannot delete subtask with empty ID');
      }

      // Get subtask to verify it's a subtask and get parent ID
      final subtask = getTaskById(subtaskId);
      if (subtask == null) {
        throw Exception('Subtask not found: $subtaskId');
      }
      if (!subtask.isSubtask) {
        throw Exception(
            'Task $subtaskId is not a subtask, use deleteTask instead');
      }

      final parentTaskId = subtask.parentTaskId!;

      // Delete the subtask
      await _storage.deleteTask(subtaskId);
      _logger.info('Subtask deleted: $subtaskId', tag: 'TaskRepository');

      // Update parent task status after deletion
      await updateParentTaskStatus(parentTaskId);
    } catch (e) {
      _logger.error('Error deleting subtask: $subtaskId',
          tag: 'TaskRepository', error: e);
      rethrow;
    }
  }

  @override
  Future<void> toggleSubtaskStatus(String subtaskId) async {
    try {
      // Defensive check
      if (subtaskId.isEmpty) {
        throw Exception('Cannot toggle subtask with empty ID');
      }

      final subtask = getTaskById(subtaskId);
      if (subtask == null) {
        throw Exception('Subtask not found: $subtaskId');
      }
      if (!subtask.isSubtask) {
        throw Exception('Task $subtaskId is not a subtask');
      }

      // Toggle status
      final newStatus =
          subtask.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done;

      final updatedSubtask = subtask.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await _storage.updateTask(updatedSubtask);
      _logger.info('Subtask status toggled: $subtaskId -> ${newStatus.name}',
          tag: 'TaskRepository');

      // Update parent task status
      if (subtask.parentTaskId != null) {
        await updateParentTaskStatus(subtask.parentTaskId!);
      }
    } catch (e) {
      _logger.error('Error toggling subtask status: $subtaskId',
          tag: 'TaskRepository', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateParentTaskStatus(String parentTaskId) async {
    try {
      // Defensive check
      if (parentTaskId.isEmpty) {
        _logger.warning('updateParentTaskStatus called with empty ID',
            tag: 'TaskRepository');
        return;
      }

      final parentTask = getTaskById(parentTaskId);
      if (parentTask == null) {
        _logger.warning('Parent task not found: $parentTaskId',
            tag: 'TaskRepository');
        return;
      }

      final subtasks = getSubtasks(parentTaskId);
      if (subtasks.isEmpty) {
        // No subtasks, don't auto-update parent status
        return;
      }

      // Count subtask statuses
      final allDone = subtasks.every((s) => s.status == TaskStatus.done);
      final anyInProgress =
          subtasks.any((s) => s.status == TaskStatus.inProgress);
      final anyDone = subtasks.any((s) => s.status == TaskStatus.done);

      TaskStatus newStatus = parentTask.status;

      // Auto-update logic:
      // 1. If all subtasks are done -> parent is done
      // 2. If any subtask is in-progress or some are done -> parent is in-progress
      // 3. Otherwise -> keep parent as todo (unless manually set otherwise)
      if (allDone) {
        newStatus = TaskStatus.done;
      } else if (anyInProgress || anyDone) {
        // Only auto-set to in-progress if parent is currently todo
        if (parentTask.status == TaskStatus.todo) {
          newStatus = TaskStatus.inProgress;
        }
      } else {
        // All subtasks are todo
        // Only auto-revert to todo if parent was auto-completed
        if (parentTask.status == TaskStatus.done) {
          newStatus = TaskStatus.todo;
        }
      }

      // Update parent if status changed
      if (newStatus != parentTask.status) {
        final updatedParent = parentTask.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        await _storage.updateTask(updatedParent);
        _logger.info(
            'Parent task status auto-updated: $parentTaskId -> ${newStatus.name}',
            tag: 'TaskRepository');
      }
    } catch (e) {
      _logger.error('Error updating parent task status: $parentTaskId',
          tag: 'TaskRepository', error: e);
      // Don't rethrow - this is a helper function, shouldn't break main flow
    }
  }

  @override
  double calculateTaskProgress(String taskId, {Set<String>? visitedIds}) {
    try {
      // Defensive check: validate ID
      if (taskId.isEmpty) {
        _logger.warning('calculateTaskProgress called with empty taskId',
            tag: 'TaskRepository');
        return 0.0;
      }

      // Prevent infinite recursion
      visitedIds ??= <String>{};
      if (visitedIds.contains(taskId)) {
        _logger.warning(
            'Circular reference detected in task hierarchy: $taskId',
            tag: 'TaskRepository');
        return 0.0;
      }
      visitedIds.add(taskId);

      final task = getTaskById(taskId);
      if (task == null) {
        _logger.warning('Task not found for progress calculation: $taskId',
            tag: 'TaskRepository');
        return 0.0;
      }

      // If task is done, return 1.0
      if (task.status == TaskStatus.done) return 1.0;

      // Get all subtasks
      final subtasks = getSubtasks(taskId);
      if (subtasks.isEmpty) {
        // No subtasks, return based on task status
        return task.status == TaskStatus.done ? 1.0 : 0.0;
      }

      // Calculate progress based on subtasks
      double totalProgress = 0.0;

      for (final subtask in subtasks) {
        // Recursively calculate subtask progress
        final subtaskProgress =
            calculateTaskProgress(subtask.id, visitedIds: visitedIds);
        totalProgress += subtaskProgress;
      }

      return totalProgress / subtasks.length;
    } catch (e) {
      _logger.error('Error calculating task progress for: $taskId',
          tag: 'TaskRepository', error: e);
      return 0.0; // Safe fallback
    }
  }

  @override
  Future<void> reorderSubtasks(
      String parentTaskId, List<String> subtaskIds) async {
    try {
      // Defensive checks: validate inputs
      if (parentTaskId.isEmpty) {
        throw Exception('Cannot reorder subtasks: empty parentTaskId');
      }
      if (subtaskIds.isEmpty) {
        _logger.warning('reorderSubtasks called with empty subtaskIds',
            tag: 'TaskRepository');
        return; // Nothing to do
      }

      final allTasks = _storage.getTasks();
      int reorderedCount = 0;

      for (int i = 0; i < subtaskIds.length; i++) {
        final taskIndex = allTasks.indexWhere((t) => t.id == subtaskIds[i]);
        if (taskIndex != -1) {
          // Verify this is actually a subtask of the parent
          if (allTasks[taskIndex].parentTaskId == parentTaskId) {
            allTasks[taskIndex] = allTasks[taskIndex].copyWith(subtaskOrder: i);
            reorderedCount++;
          } else {
            _logger.warning(
                'Task ${subtaskIds[i]} is not a subtask of $parentTaskId',
                tag: 'TaskRepository');
          }
        } else {
          _logger.warning('Subtask not found: ${subtaskIds[i]}',
              tag: 'TaskRepository');
        }
      }

      if (reorderedCount > 0) {
        await _storage.saveTasks(allTasks);
        _logger.info(
            'Reordered $reorderedCount subtasks for parent: $parentTaskId',
            tag: 'TaskRepository');
      }
    } catch (e) {
      _logger.error('Error reordering subtasks for parent: $parentTaskId',
          tag: 'TaskRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      // Only clear tasks, not all storage
      await _storage.saveTasks([]);
      _logger.info('All tasks cleared', tag: 'TaskRepository');
    } catch (e) {
      _logger.error('Error clearing all tasks',
          tag: 'TaskRepository', error: e);
      rethrow; // This is critical, let caller handle
    }
  }
}
