import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/app_constants.dart';
import '../models/focus_session.dart';
import '../models/task.dart';
import '../utils/logger.dart';
import 'data_validator.dart';

class StorageService extends GetxService {
  late GetStorage _box;
  late Logger _logger;

  // Expose box for repositories (controlled access)
  GetStorage get box => _box;

  // In-memory cache to reduce disk reads
  List<Task>? _tasksCache;
  bool _cacheInvalidated = true;

  Future<StorageService> init() async {
    try {
      await GetStorage.init();
      _box = GetStorage();
      _logger = Get.find<Logger>();

      // Perform data integrity check on startup
      await _checkDataIntegrity();

      return this;
    } catch (e) {
      // If Logger is not available yet, use print as fallback
      print('CRITICAL: StorageService init failed: $e');
      rethrow; // This is critical, app cannot run without storage
    }
  }

  /// Check data integrity on app start
  Future<void> _checkDataIntegrity() async {
    try {
      final tasks = getTasks();
      final integrityResult = DataValidator.checkTaskIntegrity(tasks);

      if (!integrityResult.isHealthy) {
        _logger.error('Data integrity issues detected', tag: 'StorageService');
        _logger.error(integrityResult.toString(), tag: 'StorageService');

        // Attempt auto-recovery for orphaned subtasks
        await _repairOrphanedSubtasks(tasks);
      } else if (integrityResult.hasWarnings) {
        _logger.warning('Data integrity warnings', tag: 'StorageService');
        _logger.warning(integrityResult.toString(), tag: 'StorageService');
      }
    } catch (e) {
      _logger.error('Error during data integrity check',
          tag: 'StorageService', error: e);
      // Don't throw - app should continue even if integrity check fails
    }
  }

  /// Repair orphaned subtasks by removing parentTaskId
  Future<void> _repairOrphanedSubtasks(List<Task> tasks) async {
    try {
      final taskIds = tasks.map((t) => t.id).toSet();
      bool modified = false;

      for (int i = 0; i < tasks.length; i++) {
        if (tasks[i].parentTaskId != null &&
            !taskIds.contains(tasks[i].parentTaskId)) {
          _logger.info(
              'Repairing orphaned subtask: ${tasks[i].title} (${tasks[i].id})',
              tag: 'StorageService');
          tasks[i] = tasks[i].copyWith(clearParentTaskId: true);
          modified = true;
        }
      }

      if (modified) {
        await saveTasks(tasks);
        _logger.info('Orphaned subtasks repaired', tag: 'StorageService');
      }
    } catch (e) {
      _logger.error('Failed to repair orphaned subtasks',
          tag: 'StorageService', error: e);
      // Don't throw - this is a recovery operation
    }
  }

  // Invalidate cache when data changes
  void _invalidateCache() {
    _tasksCache = null;
    _cacheInvalidated = true;
  }

  // Tasks
  List<Task> getTasks() {
    // Return from cache if valid
    if (!_cacheInvalidated && _tasksCache != null) {
      return List.from(
          _tasksCache!); // Return copy to prevent external modifications
    }

    try {
      final tasksJson = _box.read<List>(AppConstants.tasksKey) ?? [];
      _tasksCache = tasksJson.map((json) => Task.fromJson(json)).toList();
      _cacheInvalidated = false;
      return List.from(_tasksCache!);
    } catch (e) {
      _logger.error('Error loading tasks', tag: 'StorageService', error: e);
      _tasksCache = [];
      _cacheInvalidated = false;
      return []; // Return empty list as safe fallback
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    try {
      // Validate data before saving
      final tasksJson = tasks.map((task) => task.toJson()).toList();
      final validation = DataValidator.validateTaskList(tasksJson);

      if (!validation.isValid) {
        _logger.error('Task validation failed: ${validation.errors}',
            tag: 'StorageService');
        throw Exception('Data validation failed: ${validation.errors.first}');
      }

      // Check for duplicate IDs
      if (DataValidator.hasDuplicateIds(tasksJson)) {
        _logger.error('Duplicate task IDs detected', tag: 'StorageService');
        throw Exception('Cannot save: duplicate task IDs found');
      }

      // Atomic write with retry logic
      await _atomicWrite(AppConstants.tasksKey, tasksJson, maxRetries: 3);
      _invalidateCache(); // Force cache refresh
    } catch (e) {
      _logger.error('Error saving tasks', tag: 'StorageService', error: e);
      rethrow; // Rethrow for caller to handle
    }
  }

  /// Perform atomic write operation with retry logic
  Future<void> _atomicWrite(String key, dynamic value,
      {int maxRetries = 3}) async {
    int attempts = 0;
    Exception? lastError;

    while (attempts < maxRetries) {
      try {
        // Create backup of current data before write
        final currentData = _box.read(key);
        final backupKey = '${key}_backup';

        if (currentData != null) {
          await _box.write(backupKey, currentData);
        }

        // Write new data
        await _box.write(key, value);

        // Verify write was successful by reading back
        final writtenData = _box.read(key);
        if (writtenData == null) {
          throw Exception('Write verification failed: data is null');
        }

        // Success - remove backup
        await _box.remove(backupKey);
        return;
      } catch (e) {
        lastError = e as Exception;
        attempts++;
        _logger.error('Write attempt $attempts failed',
            tag: 'StorageService', error: e);

        if (attempts < maxRetries) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(milliseconds: 100 * attempts));
        }
      }
    }

    // All retries failed - try to restore from backup
    _logger.error(
        'All write attempts failed, attempting to restore from backup',
        tag: 'StorageService');
    await _restoreFromBackup(key);
    throw Exception(
        'Failed to write data after $maxRetries attempts: $lastError');
  }

  /// Restore data from backup
  Future<void> _restoreFromBackup(String key) async {
    try {
      final backupKey = '${key}_backup';
      final backupData = _box.read(backupKey);

      if (backupData != null) {
        await _box.write(key, backupData);
        _logger.info('Data restored from backup for key: $key',
            tag: 'StorageService');
      }
    } catch (e) {
      _logger.error('Failed to restore from backup',
          tag: 'StorageService', error: e);
      // Don't throw - this is already a recovery attempt
    }
  }

  Future<void> addTask(Task task) async {
    try {
      final tasks = getTasks();
      tasks.add(task);
      await saveTasks(tasks);
      _logger.info('Task added: ${task.id}', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error adding task: ${task.id}',
          tag: 'StorageService', error: e);
      // Don't rethrow - let the app continue, show user error via UI
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final tasks = getTasks();
      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        tasks[index] = task;
        await saveTasks(tasks);
        _logger.info('Task updated: ${task.id}', tag: 'StorageService');
      } else {
        _logger.error('Task not found for update: ${task.id}',
            tag: 'StorageService');
        throw Exception('Task not found: ${task.id}');
      }
    } catch (e) {
      _logger.error('Error updating task: ${task.id}',
          tag: 'StorageService', error: e);
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final tasks = getTasks();
      final initialLength = tasks.length;
      tasks.removeWhere((t) => t.id == taskId);

      if (tasks.length < initialLength) {
        await saveTasks(tasks);
        _logger.info('Task deleted: $taskId', tag: 'StorageService');
      } else {
        _logger.warning('Task not found for deletion: $taskId',
            tag: 'StorageService');
      }
    } catch (e) {
      _logger.error('Error deleting task: $taskId',
          tag: 'StorageService', error: e);
      throw Exception('Failed to delete task: $e');
    }
  }

  // Search & Filter
  List<Task> searchTasks(
    String query, {
    List<String>? categories,
    List<Priority>? priorities,
    List<TaskStatus>? statuses,
  }) {
    try {
      var tasks = getTasks();

      // Search by title and note
      if (query.isNotEmpty) {
        tasks = tasks.where((task) {
          final titleMatch =
              task.title.toLowerCase().contains(query.toLowerCase());
          final noteMatch =
              task.note?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return titleMatch || noteMatch;
        }).toList();
      }

      // Filter by categories
      if (categories != null && categories.isNotEmpty) {
        tasks = tasks
            .where((task) =>
                task.category != null && categories.contains(task.category))
            .toList();
      }

      // Filter by priorities
      if (priorities != null && priorities.isNotEmpty) {
        tasks =
            tasks.where((task) => priorities.contains(task.priority)).toList();
      }

      // Filter by statuses
      if (statuses != null && statuses.isNotEmpty) {
        tasks = tasks.where((task) => statuses.contains(task.status)).toList();
      }

      return tasks;
    } catch (e) {
      _logger.error('Error searching tasks', tag: 'StorageService', error: e);
      return []; // Return empty list as safe fallback
    }
  }

  List<String> getAllCategories() {
    try {
      final tasks = getTasks();
      final categories = tasks
          .where((task) => task.category != null)
          .map((task) => task.category!)
          .toSet()
          .toList();
      categories.sort();
      return categories;
    } catch (e) {
      _logger.error('Error getting categories',
          tag: 'StorageService', error: e);
      return []; // Return empty list as safe fallback
    }
  }

  // Settings
  bool isDarkMode() {
    try {
      return _box.read(AppConstants.darkModeKey) ?? false;
    } catch (e) {
      _logger.error('Error reading dark mode setting',
          tag: 'StorageService', error: e);
      return false; // Safe fallback
    }
  }

  Future<void> setDarkMode(bool value) async {
    try {
      await _box.write(AppConstants.darkModeKey, value);
    } catch (e) {
      _logger.error('Error setting dark mode', tag: 'StorageService', error: e);
      // Don't throw - this is not critical
    }
  }

  String getLanguage() {
    try {
      return _box.read(AppConstants.languageKey) ?? 'en';
    } catch (e) {
      _logger.error('Error reading language setting',
          tag: 'StorageService', error: e);
      return 'en'; // Safe fallback
    }
  }

  Future<void> setLanguage(String value) async {
    try {
      await _box.write(AppConstants.languageKey, value);
    } catch (e) {
      _logger.error('Error setting language', tag: 'StorageService', error: e);
      // Don't throw - this is not critical
    }
  }

  Future<void> clearAll() async {
    try {
      await _box.erase();
      _invalidateCache();
      _logger.info('All data cleared', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error clearing all data', tag: 'StorageService', error: e);
      throw Exception('Failed to clear data: $e');
    }
  }

  // Focus Sessions
  List<FocusSession> getFocusSessions() {
    try {
      final sessionsJson = _box.read<List>(AppConstants.focusSessionsKey) ?? [];
      return sessionsJson.map((json) => FocusSession.fromJson(json)).toList();
    } catch (e) {
      _logger.error('Error loading focus sessions',
          tag: 'StorageService', error: e);
      return []; // Return empty list as safe fallback
    }
  }

  Future<void> saveFocusSessions(List<FocusSession> sessions) async {
    try {
      await _box.write(
        AppConstants.focusSessionsKey,
        sessions.map((s) => s.toJson()).toList(),
      );
    } catch (e) {
      _logger.error('Error saving focus sessions',
          tag: 'StorageService', error: e);
      throw Exception('Failed to save focus sessions: $e');
    }
  }

  Future<void> addFocusSession(FocusSession session) async {
    try {
      final sessions = getFocusSessions();
      sessions.add(session);
      await saveFocusSessions(sessions);
      _logger.info('Focus session added: ${session.id}', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error adding focus session',
          tag: 'StorageService', error: e);
      throw Exception('Failed to add focus session: $e');
    }
  }

  List<FocusSession> getSessionsByTaskId(String taskId) {
    try {
      return getFocusSessions().where((s) => s.taskId == taskId).toList();
    } catch (e) {
      _logger.error('Error getting sessions by task ID: $taskId',
          tag: 'StorageService', error: e);
      return []; // Return empty list as safe fallback
    }
  }

  int getTotalFocusMinutesForTask(String taskId) {
    try {
      final sessions = getSessionsByTaskId(taskId);
      return sessions.fold(0, (sum, session) => sum + session.durationMinutes);
    } catch (e) {
      _logger.error('Error calculating focus minutes for task: $taskId',
          tag: 'StorageService', error: e);
      return 0; // Return 0 as safe fallback
    }
  }

  // Daily Streak
  int getDailyStreak() {
    try {
      return _box.read(AppConstants.dailyStreakKey) ?? 0;
    } catch (e) {
      _logger.error('Error reading daily streak',
          tag: 'StorageService', error: e);
      return 0; // Safe fallback
    }
  }

  Future<void> setDailyStreak(int value) async {
    try {
      await _box.write(AppConstants.dailyStreakKey, value);
    } catch (e) {
      _logger.error('Error setting daily streak',
          tag: 'StorageService', error: e);
      // Don't throw - this is not critical
    }
  }

  DateTime? getLastCompletionDate() {
    try {
      final dateStr = _box.read<String>(AppConstants.lastCompletionDateKey);
      return dateStr != null ? DateTime.parse(dateStr) : null;
    } catch (e) {
      _logger.error('Error reading last completion date',
          tag: 'StorageService', error: e);
      return null; // Safe fallback
    }
  }

  Future<void> setLastCompletionDate(DateTime date) async {
    try {
      await _box.write(
        AppConstants.lastCompletionDateKey,
        date.toIso8601String(),
      );
    } catch (e) {
      _logger.error('Error setting last completion date',
          tag: 'StorageService', error: e);
      // Don't throw - this is not critical
    }
  }

  // Achievements
  List<Map<String, dynamic>> getAchievements() {
    try {
      final achievementsJson = _box.read<List>(AppConstants.achievementsKey);
      if (achievementsJson == null) return [];
      return achievementsJson.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.error('Error loading achievements',
          tag: 'StorageService', error: e);
      return []; // Return empty list as safe fallback
    }
  }

  Future<void> saveAchievements(List<Map<String, dynamic>> achievements) async {
    try {
      await _box.write(AppConstants.achievementsKey, achievements);
    } catch (e) {
      _logger.error('Error saving achievements',
          tag: 'StorageService', error: e);
      // Don't throw - achievements are not critical
    }
  }

  // Statistics
  int getTotalCompletedTasks() {
    try {
      final tasks = getTasks();
      return tasks.where((t) => t.status == TaskStatus.done).length;
    } catch (e) {
      _logger.error('Error getting total completed tasks',
          tag: 'StorageService', error: e);
      return 0; // Safe fallback
    }
  }

  int getTotalFocusMinutes() {
    try {
      final sessions = getFocusSessions();
      return sessions.fold(0, (sum, session) => sum + session.durationMinutes);
    } catch (e) {
      _logger.error('Error getting total focus minutes',
          tag: 'StorageService', error: e);
      return 0; // Safe fallback
    }
  }

  // End of Day Summary
  Map<String, dynamic> getTodayStats() {
    try {
      final today = DateTime.now();
      final tasks = getTasks();
      final sessions = getFocusSessions();

      final todayTasks = tasks
          .where((t) =>
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day)
          .toList();

      final todayCompletedTasks =
          todayTasks.where((t) => t.status == TaskStatus.done).length;

      final todaySessions = sessions
          .where((s) =>
              s.startTime.year == today.year &&
              s.startTime.month == today.month &&
              s.startTime.day == today.day)
          .toList();

      final todayFocusMinutes = todaySessions.fold(
          0, (sum, session) => sum + session.durationMinutes);

      return {
        'totalTasks': todayTasks.length,
        'completedTasks': todayCompletedTasks,
        'focusMinutes': todayFocusMinutes,
        'focusSessions': todaySessions.length,
      };
    } catch (e) {
      _logger.error('Error getting today stats',
          tag: 'StorageService', error: e);
      // Return safe fallback with zero values
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'focusMinutes': 0,
        'focusSessions': 0,
      };
    }
  }

  // Behavior Logs
  List<Map<String, dynamic>> getBehaviorLogs() {
    try {
      final logs = _box.read<List>('behaviorLogs') ?? [];
      return logs.map((log) => Map<String, dynamic>.from(log)).toList();
    } catch (e) {
      _logger.error('Error loading behavior logs',
          tag: 'StorageService', error: e);
      return []; // Return empty list as safe fallback
    }
  }

  Future<void> saveBehaviorLogs(List<Map<String, dynamic>> logs) async {
    try {
      await _box.write('behaviorLogs', logs);
    } catch (e) {
      _logger.error('Error saving behavior logs',
          tag: 'StorageService', error: e);
      // Don't throw - behavior logs are not critical
    }
  }

  // Generic read/write for custom data
  T? read<T>(String key) {
    try {
      return _box.read<T>(key);
    } catch (e) {
      _logger.error('Error reading key: $key', tag: 'StorageService', error: e);
      return null; // Safe fallback
    }
  }

  Future<void> write<T>(String key, T value) async {
    try {
      await _box.write(key, value);
    } catch (e) {
      _logger.error('Error writing key: $key', tag: 'StorageService', error: e);
      // Don't throw for generic writes
    }
  }
}
