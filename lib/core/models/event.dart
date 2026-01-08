/// Model for Events (birthdays, special occasions, etc.)
class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? time;
  final bool hasNotification;
  final int? reminderMinutesBefore;
  final bool isRecurring; // For yearly events like birthdays
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.hasNotification = true,
    this.reminderMinutesBefore,
    this.isRecurring = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? time,
    bool? hasNotification,
    int? reminderMinutesBefore,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDescription = false,
    bool clearTime = false,
    bool clearReminder = false,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      date: date ?? this.date,
      time: clearTime ? null : (time ?? this.time),
      hasNotification: hasNotification ?? this.hasNotification,
      reminderMinutesBefore: clearReminder
          ? null
          : (reminderMinutesBefore ?? this.reminderMinutesBefore),
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time?.toIso8601String(),
      'hasNotification': hasNotification,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isRecurring': isRecurring,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: json['time'] != null ? DateTime.parse(json['time']) : null,
      hasNotification: json['hasNotification'] ?? true,
      reminderMinutesBefore: json['reminderMinutesBefore'],
      isRecurring: json['isRecurring'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
