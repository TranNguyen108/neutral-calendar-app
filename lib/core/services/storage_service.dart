import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/task.dart';
import '../models/focus_session.dart';

class StorageService extends GetxService {
  late GetStorage _box;

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // Tasks
  List<Task> getTasks() {
    final tasksJson = _box.read<List>('tasks') ?? [];
    return tasksJson.map((json) => Task.fromJson(json)).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    await _box.write('tasks', tasks.map((task) => task.toJson()).toList());
  }

  Future<void> addTask(Task task) async {
    final tasks = getTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  Future<void> updateTask(Task task) async {
    final tasks = getTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await saveTasks(tasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = getTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks);
  }

  // Search & Filter
  List<Task> searchTasks(
    String query, {
    List<String>? categories,
    List<Priority>? priorities,
    List<TaskStatus>? statuses,
  }) {
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
  }

  List<String> getAllCategories() {
    final tasks = getTasks();
    final categories = tasks
        .where((task) => task.category != null)
        .map((task) => task.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // Settings
  bool isDarkMode() {
    return _box.read('darkMode') ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    await _box.write('darkMode', value);
  }

  String getLanguage() {
    return _box.read('language') ?? 'en';
  }

  Future<void> setLanguage(String value) async {
    await _box.write('language', value);
  }

  Future<void> clearAll() async {
    await _box.erase();
  }

  // Focus Sessions
  List<FocusSession> getFocusSessions() {
    final sessionsJson = _box.read<List>('focus_sessions') ?? [];
    return sessionsJson.map((json) => FocusSession.fromJson(json)).toList();
  }

  Future<void> saveFocusSessions(List<FocusSession> sessions) async {
    await _box.write(
        'focus_sessions', sessions.map((s) => s.toJson()).toList());
  }

  Future<void> addFocusSession(FocusSession session) async {
    final sessions = getFocusSessions();
    sessions.add(session);
    await saveFocusSessions(sessions);
  }

  List<FocusSession> getSessionsByTaskId(String taskId) {
    return getFocusSessions().where((s) => s.taskId == taskId).toList();
  }

  int getTotalFocusMinutesForTask(String taskId) {
    final sessions = getSessionsByTaskId(taskId);
    return sessions.fold(0, (sum, session) => sum + session.durationMinutes);
  }

  // Daily Streak
  int getDailyStreak() {
    return _box.read('daily_streak') ?? 0;
  }

  Future<void> setDailyStreak(int value) async {
    await _box.write('daily_streak', value);
  }

  DateTime? getLastCompletionDate() {
    final dateStr = _box.read<String>('last_completion_date');
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  Future<void> setLastCompletionDate(DateTime date) async {
    await _box.write('last_completion_date', date.toIso8601String());
  }

  // Achievements
  List<Map<String, dynamic>> getAchievements() {
    final achievementsJson = _box.read<List>('achievements');
    if (achievementsJson == null) return [];
    return achievementsJson.cast<Map<String, dynamic>>();
  }

  Future<void> saveAchievements(List<Map<String, dynamic>> achievements) async {
    await _box.write('achievements', achievements);
  }

  // Statistics
  int getTotalCompletedTasks() {
    final tasks = getTasks();
    return tasks.where((t) => t.status == TaskStatus.done).length;
  }

  int getTotalFocusMinutes() {
    final sessions = getFocusSessions();
    return sessions.fold(0, (sum, session) => sum + session.durationMinutes);
  }

  // End of Day Summary
  Map<String, dynamic> getTodayStats() {
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

    final todayFocusMinutes =
        todaySessions.fold(0, (sum, session) => sum + session.durationMinutes);

    return {
      'totalTasks': todayTasks.length,
      'completedTasks': todayCompletedTasks,
      'focusMinutes': todayFocusMinutes,
      'focusSessions': todaySessions.length,
    };
  }

  // Behavior Logs
  List<Map<String, dynamic>> getBehaviorLogs() {
    final logs = _box.read<List>('behaviorLogs') ?? [];
    return logs.map((log) => Map<String, dynamic>.from(log)).toList();
  }

  Future<void> saveBehaviorLogs(List<Map<String, dynamic>> logs) async {
    await _box.write('behaviorLogs', logs);
  }

  // Generic read/write for custom data
  T? read<T>(String key) {
    return _box.read<T>(key);
  }

  Future<void> write<T>(String key, T value) async {
    await _box.write(key, value);
  }
}
