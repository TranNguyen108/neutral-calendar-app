class Task {
  final String id;
  final String title;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final Priority priority;
  final TaskStatus status;
  final String? category;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalFocusMinutes;
  final RecurrenceRule recurrenceRule;
  final int? recurrenceInterval;
  final DateTime? recurrenceEndDate;
  final int? reminderMinutesBefore;

  Task({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.priority = Priority.medium,
    this.status = TaskStatus.todo,
    this.category,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.totalFocusMinutes = 0,
    this.recurrenceRule = RecurrenceRule.none,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.reminderMinutesBefore,
  });

  // Check if task is overdue
  bool get isOverdue {
    if (status == TaskStatus.done) return false;
    final now = DateTime.now();
    if (endTime != null) {
      return now.isAfter(endTime!);
    }
    // If no endTime but date is past
    final taskEndOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return now.isAfter(taskEndOfDay);
  }

  // Get task duration in minutes
  int? get durationMinutes {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!).inMinutes;
    }
    return null;
  }

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    Priority? priority,
    TaskStatus? status,
    String? category,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalFocusMinutes,
    RecurrenceRule? recurrenceRule,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    int? reminderMinutesBefore,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'priority': priority.name,
      'status': status.name,
      'category': category,
      'note': note,
      'totalFocusMinutes': totalFocusMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'recurrenceRule': recurrenceRule.name,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      priority: Priority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => Priority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.todo,
      ),
      category: json['category'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      totalFocusMinutes: json['totalFocusMinutes'] ?? 0,
      recurrenceRule: json['recurrenceRule'] != null
          ? RecurrenceRule.values.firstWhere(
              (e) => e.name == json['recurrenceRule'],
              orElse: () => RecurrenceRule.none,
            )
          : RecurrenceRule.none,
      recurrenceInterval: json['recurrenceInterval'],
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'])
          : null,
      reminderMinutesBefore: json['reminderMinutesBefore'],
    );
  }
}

enum Priority {
  low,
  medium,
  high,
}

enum TaskStatus {
  todo,
  inProgress,
  done,
}

enum RecurrenceRule {
  none,
  daily,
  weekly,
  monthly,
  custom,
}
