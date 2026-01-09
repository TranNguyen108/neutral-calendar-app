/// AI Request and Response Models

/// Type of AI request to determine processing logic
enum AIRequestType {
  createTask,
  createEvent,
  createHabit,
  createNote,
  analyzeSchedule,
  detectConflicts,
  generateSuggestions,
  generalChat,
}

/// AI Request with full context
class AIRequest {
  final String prompt;
  final SystemContext context;
  final AIRequestType type;

  AIRequest({
    required this.prompt,
    required this.context,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'context': context.toJson(),
      'type': type.toString(),
    };
  }
}

/// System context for AI to understand user's current state
class SystemContext {
  final DateTime currentTime;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> habits;
  final List<Map<String, dynamic>>? conversationHistory; // 🆕 Chat history
  final Map<String, dynamic>? userPreferences;

  SystemContext({
    required this.currentTime,
    this.tasks = const [],
    this.events = const [],
    this.habits = const [],
    this.conversationHistory,
    this.userPreferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentTime': currentTime.toIso8601String(),
      'tasks': tasks,
      'events': events,
      'habits': habits,
      'conversationHistory': conversationHistory,
      'userPreferences': userPreferences,
    };
  }
}

/// Error types for better error handling
enum AIErrorType {
  parseError,
  ambiguousInput,
  missingTime,
  missingDate,
  modelFailure,
  apiError,
  unknownIntent,
}

class AIResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final AIErrorType? errorType;
  final String? rawResponse;

  AIResponse({
    required this.success,
    this.data,
    this.error,
    this.errorType,
    this.rawResponse,
  });

  factory AIResponse.success(T data, {String? rawResponse}) {
    return AIResponse(
      success: true,
      data: data,
      rawResponse: rawResponse,
    );
  }

  factory AIResponse.failure(String error,
      {AIErrorType? errorType, String? rawResponse}) {
    return AIResponse(
      success: false,
      error: error,
      errorType: errorType,
      rawResponse: rawResponse,
    );
  }
}

/// User intent detected by AI
enum UserIntent {
  createTask,
  createEvent,
  createHabit,
  createNote,
  querySchedule,
  detectConflicts,
  requestSuggestions,
  generalQuestion,
  unclear,
}

/// Action type for AI to execute
enum AIActionType {
  createTask,
  createEvent,
  createHabit,
  createNote,
  updateTask,
  deleteTask,
  askConfirmation,
  provideInformation,
}

/// AI Action - what the system should do
class AIAction {
  final AIActionType type;
  final Map<String, dynamic> data;
  final String? message;

  AIAction({
    required this.type,
    required this.data,
    this.message,
  });

  factory AIAction.fromJson(Map<String, dynamic> json) {
    return AIAction(
      type: AIActionType.values.firstWhere(
        (e) => e.toString() == 'AIActionType.${json['type']}',
        orElse: () => AIActionType.provideInformation,
      ),
      data: json['data'] as Map<String, dynamic>,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'data': data,
      'message': message,
    };
  }
}

/// Recurring rule for habits and events
class RecurringRule {
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final int interval; // Every N days/weeks/months
  final List<int>? daysOfWeek; // [1=Mon, 2=Tue, ..., 7=Sun]
  final int? dayOfMonth; // For monthly recurring
  final DateTime? endDate;
  final int? occurrences; // End after N occurrences

  RecurringRule({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.occurrences,
  });

  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    return RecurringRule(
      frequency: json['frequency'] as String,
      interval: json['interval'] as int? ?? 1,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'] as List)
          : null,
      dayOfMonth: json['dayOfMonth'] as int?,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      occurrences: json['occurrences'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
    };
  }
}

/// AI Intent Result - comprehensive response from AI
class AIIntentResult {
  final UserIntent intent;
  final double confidence;
  final bool needsConfirmation;
  final List<String>? confirmationQuestions;
  final List<AIAction> actions;
  final Map<String, dynamic>? extractedData;
  final String? explanation;

  AIIntentResult({
    required this.intent,
    required this.confidence,
    this.needsConfirmation = false,
    this.confirmationQuestions,
    required this.actions,
    this.extractedData,
    this.explanation,
  });

  factory AIIntentResult.fromJson(Map<String, dynamic> json) {
    return AIIntentResult(
      intent: UserIntent.values.firstWhere(
        (e) => e.toString() == 'UserIntent.${json['intent']}',
        orElse: () => UserIntent.unclear,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      needsConfirmation: json['needsConfirmation'] as bool? ?? false,
      confirmationQuestions: json['confirmationQuestions'] != null
          ? List<String>.from(json['confirmationQuestions'] as List)
          : null,
      actions: json['actions'] != null
          ? (json['actions'] as List)
              .map((a) => AIAction.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
      extractedData: json['extractedData'] as Map<String, dynamic>?,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': intent.toString().split('.').last,
      'confidence': confidence,
      'needsConfirmation': needsConfirmation,
      'confirmationQuestions': confirmationQuestions,
      'actions': actions.map((a) => a.toJson()).toList(),
      'extractedData': extractedData,
      'explanation': explanation,
    };
  }
}

/// Task suggestion model
class TaskSuggestion {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final DateTime? startTime;
  final String? priority;
  final String? category;
  final List<String>? tags;
  final bool? hasReminder;
  final int? reminderMinutesBefore;

  TaskSuggestion({
    required this.title,
    this.description,
    this.dueDate,
    this.startTime,
    this.priority,
    this.category,
    this.tags,
    this.hasReminder,
    this.reminderMinutesBefore,
  });

  factory TaskSuggestion.fromJson(Map<String, dynamic> json) {
    return TaskSuggestion(
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'] as String)
          : null,
      priority: json['priority'] as String?,
      category: json['category'] as String?,
      tags:
          json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      hasReminder: json['hasReminder'] as bool?,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'priority': priority,
      'category': category,
      'tags': tags,
      'hasReminder': hasReminder,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }
}

/// @deprecated Use AIIntentResult instead for better intent detection
/// Simple AI Task Result - kept for backward compatibility
class AiTaskResult {
  final String title;
  final DateTime date;
  final DateTime? endDate; // For date ranges
  final String? time;
  final String priority;
  final double confidence;
  final String type; // 'task', 'event', 'note'
  final String? recurring; // 'none', 'daily', 'weekly', 'monthly', 'yearly'
  final List<String>? subtasks; // Subtask list
  final String? description;

  AiTaskResult({
    required this.title,
    required this.date,
    this.endDate,
    this.time,
    required this.priority,
    required this.confidence,
    this.type = 'task',
    this.recurring = 'none',
    this.subtasks,
    this.description,
  });

  factory AiTaskResult.fromJson(Map<String, dynamic> json) {
    return AiTaskResult(
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      time: json['time'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      type: json['type'] as String? ?? 'task',
      recurring: json['recurring'] as String? ?? 'none',
      subtasks: json['subtasks'] != null
          ? List<String>.from(json['subtasks'] as List)
          : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String().split('T')[0],
      'endDate': endDate?.toIso8601String().split('T')[0],
      'time': time,
      'priority': priority,
      'confidence': confidence,
      'type': type,
      'recurring': recurring,
      'subtasks': subtasks,
      'description': description,
    };
  }
}
