class UserBehaviorLog {
  final String id;
  final DateTime timestamp;
  final BehaviorType type;
  final Map<String, dynamic> data;

  UserBehaviorLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'data': data,
    };
  }

  factory UserBehaviorLog.fromJson(Map<String, dynamic> json) {
    return UserBehaviorLog(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      type: BehaviorType.values.firstWhere((e) => e.name == json['type']),
      data: json['data'] ?? {},
    );
  }
}

enum BehaviorType {
  taskCompleted,
  taskDelayed,
  taskRescheduled,
  focusSessionCompleted,
  focusSessionSkipped,
  taskCreated,
  taskOverdue,
}

class BehaviorStats {
  final int totalTasksCompleted;
  final int totalDelays;
  final int totalReschedules;
  final int totalFocusSessions;
  final double avgCompletionTime; // in hours
  final double avgTasksPerDay;
  final List<int> productiveHours; // Hours with most completions
  final Map<String, int> categoryFrequency;

  BehaviorStats({
    required this.totalTasksCompleted,
    required this.totalDelays,
    required this.totalReschedules,
    required this.totalFocusSessions,
    required this.avgCompletionTime,
    required this.avgTasksPerDay,
    required this.productiveHours,
    required this.categoryFrequency,
  });

  double get delayFrequency =>
      totalTasksCompleted > 0 ? totalDelays / totalTasksCompleted : 0;

  double get rescheduleFrequency =>
      totalTasksCompleted > 0 ? totalReschedules / totalTasksCompleted : 0;
}
