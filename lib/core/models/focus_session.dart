class FocusSession {
  final String id;
  final String? taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final bool completed;

  FocusSession({
    required this.id,
    this.taskId,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.completed = false,
  });

  FocusSession copyWith({
    String? id,
    String? taskId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    bool? completed,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'completed': completed,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'],
      taskId: json['taskId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      durationMinutes: json['durationMinutes'] ?? (json['duration'] ?? 0),
      completed: json['completed'] ?? false,
    );
  }
}
