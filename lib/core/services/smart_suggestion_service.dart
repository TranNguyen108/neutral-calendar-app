import 'package:get/get.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../services/behavior_logging_service.dart';

class SmartSuggestionService extends GetxService {
  StorageService get _storage => Get.find<StorageService>();
  BehaviorLoggingService get _behavior => Get.find<BehaviorLoggingService>();

  // Check if should suggest rescheduling a task
  bool shouldSuggestReschedule(Task task) {
    // Suggest if task is overdue
    if (task.isOverdue && task.status != TaskStatus.done) {
      return true;
    }

    // Suggest if task has been delayed multiple times
    final stats = _behavior.calculateStats(lastDays: 7);
    if (stats.delayFrequency > 0.3) {
      return true;
    }

    return false;
  }

  // Check if user should take a break or do a focus session
  bool shouldSuggestBreak() {
    final now = DateTime.now();
    final stats = _storage.getTodayStats();
    final completedTasks = stats['completedTasks'] as int;
    final focusMinutes = stats['focusMinutes'] as int;

    // Suggest break if worked for 2+ hours without focus
    if (completedTasks >= 3 && focusMinutes < 25 && now.hour >= 10) {
      return true;
    }

    return false;
  }

  bool shouldSuggestFocus() {
    final stats = _storage.getTodayStats();
    final focusMinutes = stats['focusMinutes'] as int;
    final now = DateTime.now();

    // Suggest focus if low focus time and afternoon
    if (focusMinutes < 30 && now.hour >= 14 && now.hour <= 17) {
      return true;
    }

    return false;
  }

  // Detect if today has too many tasks (overload)
  bool detectOverloadDay() {
    final tasks = _storage.getTasks();
    final today = DateTime.now();

    final todayTasks = tasks
        .where((t) =>
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day &&
            t.status != TaskStatus.done)
        .toList();

    // Overload if 10+ tasks or 8+ high priority tasks
    if (todayTasks.length >= 10) {
      return true;
    }

    final highPriorityTasks =
        todayTasks.where((t) => t.priority == Priority.high).length;
    if (highPriorityTasks >= 8) {
      return true;
    }

    return false;
  }

  // Get smart suggestions for today
  List<SmartSuggestion> getDailySuggestions() {
    final suggestions = <SmartSuggestion>[];
    final tasks = _storage.getTasks();
    final today = DateTime.now();

    final todayTasks = tasks
        .where((t) =>
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day)
        .toList();

    // Check overload
    if (detectOverloadDay()) {
      suggestions.add(SmartSuggestion(
        type: SuggestionType.overloadWarning,
        title: 'suggestion_overload_title',
        message: 'suggestion_overload_message',
        priority: SuggestionPriority.high,
        actionLabel: 'suggestion_reschedule_some',
      ));
    }

    // Check for overdue tasks
    final overdueTasks = todayTasks
        .where((t) => t.isOverdue && t.status != TaskStatus.done)
        .toList();
    if (overdueTasks.isNotEmpty) {
      suggestions.add(SmartSuggestion(
        type: SuggestionType.reschedule,
        title: 'suggestion_overdue_title',
        message: 'suggestion_overdue_message',
        priority: SuggestionPriority.medium,
        actionLabel: 'suggestion_reschedule',
        data: {'taskCount': overdueTasks.length},
      ));
    }

    // Suggest focus session
    if (shouldSuggestFocus()) {
      suggestions.add(SmartSuggestion(
        type: SuggestionType.focus,
        title: 'suggestion_focus_title',
        message: 'suggestion_focus_message',
        priority: SuggestionPriority.low,
        actionLabel: 'suggestion_start_focus',
      ));
    }

    // Suggest break
    if (shouldSuggestBreak()) {
      suggestions.add(SmartSuggestion(
        type: SuggestionType.break_,
        title: 'suggestion_break_title',
        message: 'suggestion_break_message',
        priority: SuggestionPriority.medium,
        actionLabel: 'suggestion_take_break',
      ));
    }

    // Sort by priority
    suggestions.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return suggestions;
  }

  // Get personalized insights from behavior
  List<String> getPersonalizedInsights() {
    final insights = _behavior.getInsights();
    final stats = _behavior.calculateStats(lastDays: 30);

    final messages = <String>[];

    if (insights.contains('insight_frequent_delays')) {
      messages.add('insight_frequent_delays_message');
    }

    if (insights.contains('insight_frequent_reschedules')) {
      messages.add('insight_frequent_reschedules_message');
    }

    if (insights.contains('insight_productive_hours') &&
        stats.productiveHours.isNotEmpty) {
      messages.add('insight_productive_hours_message');
    }

    if (insights.contains('insight_low_focus_usage')) {
      messages.add('insight_low_focus_usage_message');
    }

    return messages;
  }
}

class SmartSuggestion {
  final SuggestionType type;
  final String title;
  final String message;
  final SuggestionPriority priority;
  final String? actionLabel;
  final Map<String, dynamic>? data;

  SmartSuggestion({
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    this.actionLabel,
    this.data,
  });
}

enum SuggestionType {
  reschedule,
  focus,
  break_,
  overloadWarning,
}

enum SuggestionPriority {
  low,
  medium,
  high,
}
