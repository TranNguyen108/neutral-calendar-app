import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/app_constants.dart';
import '../models/focus_session.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/diary.dart';
import '../models/event.dart';
import '../models/daily_mood.dart'; // NEW: Daily mood model
import '../utils/logger.dart';
import 'data_validator.dart';

class StorageService extends GetxService {
  late GetStorage _box;
  late Logger _logger;

  // Expose box for repositories (controlled access)
  GetStorage get box => _box;

  // In-memory caches to reduce disk reads
  List<Task>? _tasksCache;
  DateTime? _tasksCacheTimestamp;

  List<FocusSession>? _sessionsCache;
  DateTime? _sessionsCacheTimestamp;

  static const _cacheValidityDuration = Duration(minutes: 5);

  // Storage keys (centralized for easier maintenance)
  static const _backupSuffix = '_backup';
  static const _behaviorLogsKey = 'behaviorLogs';

  Future<StorageService> init() async {
    try {
      await GetStorage.init();
      _box = GetStorage();
      _logger = Get.find<Logger>();

      // Perform data integrity check on startup
      await _checkDataIntegrity();

      return this;
    } catch (e) {
      // Critical error - use debugPrint as Logger may not be available yet
      debugPrint('CRITICAL: StorageService init failed: $e');
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

  // Invalidate specific caches
  void _invalidateTasksCache() {
    _tasksCache = null;
    _tasksCacheTimestamp = null;
  }

  void _invalidateSessionsCache() {
    _sessionsCache = null;
    _sessionsCacheTimestamp = null;
  }

  void _invalidateAllCaches() {
    _invalidateTasksCache();
    _invalidateSessionsCache();
  }

  // Tasks
  List<Task> getTasks() {
    // Check cache validity
    if (_isCacheValid(_tasksCache, _tasksCacheTimestamp)) {
      return List.from(_tasksCache!);
    }

    try {
      final tasksJson = _box.read<List>(AppConstants.tasksKey) ?? [];
      _tasksCache = tasksJson
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
      _tasksCacheTimestamp = DateTime.now();
      return List.from(_tasksCache!);
    } catch (e) {
      _logger.error('Error loading tasks', tag: 'StorageService', error: e);
      _tasksCache = [];
      _tasksCacheTimestamp = DateTime.now();
      return [];
    }
  }

  /// Check if a cache is still valid
  bool _isCacheValid(List? cache, DateTime? timestamp) {
    if (cache == null || timestamp == null) return false;
    final cacheAge = DateTime.now().difference(timestamp);
    return cacheAge < _cacheValidityDuration;
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
      _invalidateTasksCache(); // Force cache refresh
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
    final backupKey = '$key$_backupSuffix';

    while (attempts < maxRetries) {
      try {
        // Create backup of current data before write
        final currentData = _box.read(key);
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
      final backupKey = '$key$_backupSuffix';
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
      final tasks = getTasks();
      final lowerQuery = query.toLowerCase();
      final hasQuery = query.isNotEmpty;
      final hasCategories = categories != null && categories.isNotEmpty;
      final hasPriorities = priorities != null && priorities.isNotEmpty;
      final hasStatuses = statuses != null && statuses.isNotEmpty;

      // Single-pass filtering for better performance
      return tasks.where((task) {
        // Query filter
        if (hasQuery) {
          final titleMatch = task.title.toLowerCase().contains(lowerQuery);
          final noteMatch =
              task.note?.toLowerCase().contains(lowerQuery) ?? false;
          if (!titleMatch && !noteMatch) return false;
        }

        // Category filter
        if (hasCategories &&
            (task.category == null || !categories.contains(task.category))) {
          return false;
        }

        // Priority filter
        if (hasPriorities && !priorities.contains(task.priority)) {
          return false;
        }

        // Status filter
        if (hasStatuses && !statuses.contains(task.status)) {
          return false;
        }

        return true;
      }).toList();
    } catch (e) {
      _logger.error('Error searching tasks', tag: 'StorageService', error: e);
      return [];
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

  // AI API Key
  String? getApiKey() {
    try {
      return _box.read('ai_api_key');
    } catch (e) {
      _logger.error('Error reading API key', tag: 'StorageService', error: e);
      return null;
    }
  }

  Future<void> setApiKey(String? value) async {
    try {
      if (value == null || value.isEmpty) {
        await _box.remove('ai_api_key');
      } else {
        await _box.write('ai_api_key', value);
      }
    } catch (e) {
      _logger.error('Error setting API key', tag: 'StorageService', error: e);
    }
  }

  Future<void> clearAll() async {
    try {
      await _box.erase();
      _invalidateAllCaches();
      _logger.info('All data cleared', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error clearing all data', tag: 'StorageService', error: e);
      throw Exception('Failed to clear data: $e');
    }
  }

  // Focus Sessions
  List<FocusSession> getFocusSessions() {
    // Check cache validity
    if (_isCacheValid(_sessionsCache, _sessionsCacheTimestamp)) {
      return List.from(_sessionsCache!);
    }

    try {
      final sessionsJson = _box.read<List>(AppConstants.focusSessionsKey) ?? [];
      _sessionsCache = sessionsJson
          .map((json) => FocusSession.fromJson(json as Map<String, dynamic>))
          .toList();
      _sessionsCacheTimestamp = DateTime.now();
      return List.from(_sessionsCache!);
    } catch (e) {
      _logger.error('Error loading focus sessions',
          tag: 'StorageService', error: e);
      _sessionsCache = [];
      _sessionsCacheTimestamp = DateTime.now();
      return [];
    }
  }

  Future<void> saveFocusSessions(List<FocusSession> sessions) async {
    try {
      await _box.write(
        AppConstants.focusSessionsKey,
        sessions.map((s) => s.toJson()).toList(),
      );
      _invalidateSessionsCache();
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

      final todayTasks = tasks.where((t) => _isSameDay(t.date, today)).toList();
      final todayCompletedTasks =
          todayTasks.where((t) => t.status == TaskStatus.done).length;

      final todaySessions =
          sessions.where((s) => _isSameDay(s.startTime, today)).toList();
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
      return _getEmptyStatsMap();
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get empty stats map for error fallback
  Map<String, dynamic> _getEmptyStatsMap() {
    return {
      'totalTasks': 0,
      'completedTasks': 0,
      'focusMinutes': 0,
      'focusSessions': 0,
    };
  }

  // Behavior Logs
  List<Map<String, dynamic>> getBehaviorLogs() {
    try {
      final logs = _box.read<List>(_behaviorLogsKey) ?? [];
      return logs.map((log) => Map<String, dynamic>.from(log)).toList();
    } catch (e) {
      _logger.error('Error loading behavior logs',
          tag: 'StorageService', error: e);
      return [];
    }
  }

  Future<void> saveBehaviorLogs(List<Map<String, dynamic>> logs) async {
    try {
      await _box.write(_behaviorLogsKey, logs);
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
  // Batch Operations for better performance

  /// Add multiple tasks at once (more efficient than individual adds)
  Future<void> addTasksBatch(List<Task> newTasks) async {
    if (newTasks.isEmpty) return;

    try {
      final tasks = getTasks();
      tasks.addAll(newTasks);
      await saveTasks(tasks);
      _logger.info('Batch added ${newTasks.length} tasks',
          tag: 'StorageService');
    } catch (e) {
      _logger.error('Error batch adding tasks',
          tag: 'StorageService', error: e);
      rethrow;
    }
  }

  /// Update multiple tasks at once
  Future<void> updateTasksBatch(List<Task> updatedTasks) async {
    if (updatedTasks.isEmpty) return;

    try {
      final tasks = getTasks();
      final taskMap = {for (var t in tasks) t.id: t};

      for (final updatedTask in updatedTasks) {
        taskMap[updatedTask.id] = updatedTask;
      }

      await saveTasks(taskMap.values.toList());
      _logger.info('Batch updated ${updatedTasks.length} tasks',
          tag: 'StorageService');
    } catch (e) {
      _logger.error('Error batch updating tasks',
          tag: 'StorageService', error: e);
      rethrow;
    }
  }

  /// Delete multiple tasks at once
  Future<void> deleteTasksBatch(List<String> taskIds) async {
    if (taskIds.isEmpty) return;

    try {
      final tasks = getTasks();
      final idsToDelete = taskIds.toSet();
      final filteredTasks =
          tasks.where((t) => !idsToDelete.contains(t.id)).toList();

      await saveTasks(filteredTasks);
      _logger.info('Batch deleted ${taskIds.length} tasks',
          tag: 'StorageService');
    } catch (e) {
      _logger.error('Error batch deleting tasks',
          tag: 'StorageService', error: e);
      rethrow;
    }
  }

  /// Execute multiple storage operations in a transaction-like manner
  Future<void> executeInTransaction(Future<void> Function() operation) async {
    // Create backup of critical data
    final tasksBackup = _box.read<List>(AppConstants.tasksKey);
    final sessionsBackup = _box.read<List>(AppConstants.focusSessionsKey);

    try {
      await operation();
    } catch (e) {
      // Restore from backup on failure
      _logger.error('Transaction failed, restoring backup',
          tag: 'StorageService', error: e);

      if (tasksBackup != null) {
        await _box.write(AppConstants.tasksKey, tasksBackup);
      }
      if (sessionsBackup != null) {
        await _box.write(AppConstants.focusSessionsKey, sessionsBackup);
      }

      _invalidateAllCaches();
      rethrow;
    }
  }

  // ==================== NOTES ====================
  List<Note> getNotes() {
    try {
      final notesJson = _box.read<List>(AppConstants.notesKey) ?? [];
      return notesJson
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Error loading notes', tag: 'StorageService', error: e);
      return [];
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    try {
      await _box.write(
        AppConstants.notesKey,
        notes.map((n) => n.toJson()).toList(),
      );
    } catch (e) {
      _logger.error('Error saving notes', tag: 'StorageService', error: e);
      throw Exception('Failed to save notes: $e');
    }
  }

  Future<void> addNote(Note note) async {
    try {
      final notes = getNotes();
      notes.add(note);
      await saveNotes(notes);
      _logger.info('Note added: ${note.id}', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error adding note', tag: 'StorageService', error: e);
      throw Exception('Failed to add note: $e');
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      final notes = getNotes();
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        notes[index] = note;
        await saveNotes(notes);
        _logger.info('Note updated: ${note.id}', tag: 'StorageService');
      }
    } catch (e) {
      _logger.error('Error updating note', tag: 'StorageService', error: e);
      throw Exception('Failed to update note: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final notes = getNotes();
      notes.removeWhere((n) => n.id == noteId);
      await saveNotes(notes);
      _logger.info('Note deleted: $noteId', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error deleting note', tag: 'StorageService', error: e);
      throw Exception('Failed to delete note: $e');
    }
  }

  // ==================== DIARIES ====================
  List<Diary> getDiaries() {
    try {
      final diariesJson = _box.read<List>(AppConstants.diariesKey) ?? [];
      return diariesJson
          .map((json) => Diary.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Error loading diaries', tag: 'StorageService', error: e);
      return [];
    }
  }

  Future<void> saveDiaries(List<Diary> diaries) async {
    try {
      await _box.write(
        AppConstants.diariesKey,
        diaries.map((d) => d.toJson()).toList(),
      );
    } catch (e) {
      _logger.error('Error saving diaries', tag: 'StorageService', error: e);
      throw Exception('Failed to save diaries: $e');
    }
  }

  Future<void> addDiary(Diary diary) async {
    try {
      final diaries = getDiaries();
      diaries.add(diary);
      await saveDiaries(diaries);
      _logger.info('Diary added: ${diary.id}', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error adding diary', tag: 'StorageService', error: e);
      throw Exception('Failed to add diary: $e');
    }
  }

  Future<void> updateDiary(Diary diary) async {
    try {
      final diaries = getDiaries();
      final index = diaries.indexWhere((d) => d.id == diary.id);
      if (index != -1) {
        diaries[index] = diary;
        await saveDiaries(diaries);
        _logger.info('Diary updated: ${diary.id}', tag: 'StorageService');
      }
    } catch (e) {
      _logger.error('Error updating diary', tag: 'StorageService', error: e);
      throw Exception('Failed to update diary: $e');
    }
  }

  Future<void> deleteDiary(String diaryId) async {
    try {
      final diaries = getDiaries();
      diaries.removeWhere((d) => d.id == diaryId);
      await saveDiaries(diaries);
      _logger.info('Diary deleted: $diaryId', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error deleting diary', tag: 'StorageService', error: e);
      throw Exception('Failed to delete diary: $e');
    }
  }

  // ==================== DAILY MOODS (NEW) ====================
  /// Storage key for daily moods
  static const String _dailyMoodsKey = 'daily_moods';

  /// Get all daily moods
  List<DailyMood> getDailyMoods() {
    try {
      final moodsJson = _box.read<List>(_dailyMoodsKey) ?? [];
      return moodsJson
          .map((json) => DailyMood.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Error loading daily moods',
          tag: 'StorageService', error: e);
      return [];
    }
  }

  /// Save all daily moods
  Future<void> saveDailyMoods(List<DailyMood> moods) async {
    try {
      await _box.write(
        _dailyMoodsKey,
        moods.map((m) => m.toJson()).toList(),
      );
    } catch (e) {
      _logger.error('Error saving daily moods',
          tag: 'StorageService', error: e);
      throw Exception('Failed to save daily moods: $e');
    }
  }

  /// Get daily mood for a specific date
  /// Returns null if no daily mood exists for that date
  DailyMood? getDailyMoodForDate(DateTime date) {
    try {
      final id = DailyMood.generateId(date);
      final moods = getDailyMoods();
      return moods.firstWhereOrNull((m) => m.id == id);
    } catch (e) {
      _logger.error('Error getting daily mood for date',
          tag: 'StorageService', error: e);
      return null;
    }
  }

  /// Set or update daily mood for a specific date
  /// If a daily mood already exists, it will be updated
  Future<void> setDailyMood(DailyMood dailyMood) async {
    try {
      final moods = getDailyMoods();
      final index = moods.indexWhere((m) => m.id == dailyMood.id);

      if (index != -1) {
        // Update existing
        moods[index] = dailyMood.copyWith(updatedAt: DateTime.now());
      } else {
        // Add new
        moods.add(dailyMood);
      }

      await saveDailyMoods(moods);
      _logger.info('Daily mood set: ${dailyMood.id} - ${dailyMood.mood}',
          tag: 'StorageService');
    } catch (e) {
      _logger.error('Error setting daily mood',
          tag: 'StorageService', error: e);
      throw Exception('Failed to set daily mood: $e');
    }
  }

  /// Check if user has been prompted for daily mood today
  /// This prevents showing the prompt multiple times per day
  bool hasBeenPromptedToday() {
    try {
      final today = DateTime.now();
      final key = 'mood_prompt_shown_${DailyMood.generateId(today)}';
      return _box.read<bool>(key) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark that user has been prompted today
  Future<void> markPromptedToday() async {
    try {
      final today = DateTime.now();
      final key = 'mood_prompt_shown_${DailyMood.generateId(today)}';
      await _box.write(key, true);
      print('📥 [STORAGE] Marked prompted for today: $key');
    } catch (e) {
      _logger.error('Error marking prompted today',
          tag: 'StorageService', error: e);
    }
  }

  /// Clear prompt state for today (for debugging)
  Future<void> clearPromptedToday() async {
    try {
      final today = DateTime.now();
      final key = 'mood_prompt_shown_${DailyMood.generateId(today)}';
      await _box.remove(key);
      print('🧹 [STORAGE] Cleared prompted state for today');
    } catch (e) {
      _logger.error('Error clearing prompted today',
          tag: 'StorageService', error: e);
    }
  }

  /// Get diaries for a specific date
  /// Helper method used by mood detection logic
  List<Diary> getDiariesForDate(DateTime date) {
    try {
      final allDiaries = getDiaries();
      return allDiaries.where((diary) {
        return diary.date.year == date.year &&
            diary.date.month == date.month &&
            diary.date.day == date.day;
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date)); // Oldest first
    } catch (e) {
      _logger.error('Error getting diaries for date',
          tag: 'StorageService', error: e);
      return [];
    }
  }

  // ==================== EVENTS ====================
  List<Event> getEvents() {
    try {
      final eventsJson = _box.read<List>(AppConstants.eventsKey) ?? [];
      return eventsJson
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Error loading events', tag: 'StorageService', error: e);
      return [];
    }
  }

  Future<void> saveEvents(List<Event> events) async {
    try {
      await _box.write(
        AppConstants.eventsKey,
        events.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      _logger.error('Error saving events', tag: 'StorageService', error: e);
      throw Exception('Failed to save events: $e');
    }
  }

  Future<void> addEvent(Event event) async {
    try {
      final events = getEvents();
      events.add(event);
      await saveEvents(events);
      _logger.info('Event added: ${event.id}', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error adding event', tag: 'StorageService', error: e);
      throw Exception('Failed to add event: $e');
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      final events = getEvents();
      final index = events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        events[index] = event;
        await saveEvents(events);
        _logger.info('Event updated: ${event.id}', tag: 'StorageService');
      }
    } catch (e) {
      _logger.error('Error updating event', tag: 'StorageService', error: e);
      throw Exception('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final events = getEvents();
      events.removeWhere((e) => e.id == eventId);
      await saveEvents(events);
      _logger.info('Event deleted: $eventId', tag: 'StorageService');
    } catch (e) {
      _logger.error('Error deleting event', tag: 'StorageService', error: e);
      throw Exception('Failed to delete event: $e');
    }
  }
}
