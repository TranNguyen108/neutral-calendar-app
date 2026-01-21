/// DailyMood Model
///
/// Represents a user's confirmed "daily mood" for a specific day.
/// This is separate from individual diary entry moods.
///
/// Purpose:
/// - One daily mood per day (aggregated view)
/// - User can explicitly set this when prompted
/// - Falls back to automatic calculation if not set
/// - Used in mood statistics and calendar heatmaps
class DailyMood {
  final String id; // Format: 'YYYY-MM-DD'
  final DateTime date;
  final String mood; // One of MoodConstants values
  final bool
      isUserConfirmed; // True if user explicitly chose, false if auto-calculated
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyMood({
    required this.id,
    required this.date,
    required this.mood,
    required this.isUserConfirmed,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'isUserConfirmed': isUserConfirmed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory DailyMood.fromJson(Map<String, dynamic> json) {
    return DailyMood(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mood: json['mood'] as String,
      isUserConfirmed: json['isUserConfirmed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Create a copy with some fields updated
  DailyMood copyWith({
    String? id,
    DateTime? date,
    String? mood,
    bool? isUserConfirmed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyMood(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      isUserConfirmed: isUserConfirmed ?? this.isUserConfirmed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Generate ID from date (ensures one daily mood per day)
  static String generateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Factory for creating new daily mood
  factory DailyMood.create({
    required DateTime date,
    required String mood,
    required bool isUserConfirmed,
  }) {
    final now = DateTime.now();
    return DailyMood(
      id: generateId(date),
      date: DateTime(date.year, date.month, date.day), // Normalize to midnight
      mood: mood,
      isUserConfirmed: isUserConfirmed,
      createdAt: now,
      updatedAt: now,
    );
  }
}
