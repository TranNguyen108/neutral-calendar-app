import 'package:flutter_test/flutter_test.dart';
import 'package:nc_app/core/models/task.dart';

void main() {
  group('Task Model Tests', () {
    late Task sampleTask;

    setUp(() {
      sampleTask = Task(
        id: '1',
        title: 'Test Task',
        date: DateTime(2026, 1, 3, 10, 0),
        startTime: DateTime(2026, 1, 3, 10, 0),
        endTime: DateTime(2026, 1, 3, 11, 0),
        priority: Priority.high,
        status: TaskStatus.todo,
        category: 'Work',
        note: 'Test note',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        totalFocusMinutes: 25,
        recurrenceRule: RecurrenceRule.none,
      );
    });

    test('Task.toJson converts task to JSON correctly', () {
      final json = sampleTask.toJson();

      expect(json['id'], '1');
      expect(json['title'], 'Test Task');
      expect(json['priority'], 'high');
      expect(json['status'], 'todo');
      expect(json['category'], 'Work');
      expect(json['note'], 'Test note');
      expect(json['totalFocusMinutes'], 25);
      expect(json['recurrenceRule'], 'none');
    });

    test('Task.fromJson creates task from JSON correctly', () {
      final json = sampleTask.toJson();
      final task = Task.fromJson(json);

      expect(task.id, sampleTask.id);
      expect(task.title, sampleTask.title);
      expect(task.priority, sampleTask.priority);
      expect(task.status, sampleTask.status);
      expect(task.category, sampleTask.category);
      expect(task.note, sampleTask.note);
      expect(task.totalFocusMinutes, sampleTask.totalFocusMinutes);
    });

    test('Task.copyWith creates new task with updated fields', () {
      final updatedTask = sampleTask.copyWith(
        title: 'Updated Task',
        priority: Priority.low,
        status: TaskStatus.done,
      );

      expect(updatedTask.title, 'Updated Task');
      expect(updatedTask.priority, Priority.low);
      expect(updatedTask.status, TaskStatus.done);
      // Original fields should remain unchanged
      expect(updatedTask.id, sampleTask.id);
      expect(updatedTask.category, sampleTask.category);
    });

    test('isOverdue returns true for past tasks that are not done', () {
      final pastTask = sampleTask.copyWith(
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
        status: TaskStatus.todo,
      );

      expect(pastTask.isOverdue, true);
    });

    test('isOverdue returns false for completed tasks', () {
      final completedTask = sampleTask.copyWith(
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
        status: TaskStatus.done,
      );

      expect(completedTask.isOverdue, false);
    });

    test('isOverdue returns false for future tasks', () {
      final futureTask = sampleTask.copyWith(
        endTime: DateTime.now().add(const Duration(hours: 2)),
      );

      expect(futureTask.isOverdue, false);
    });

    test('isOverdue returns false when startTime is null', () {
      final noTimeTask =
          sampleTask.copyWith(clearStartTime: true, clearEndTime: true);

      expect(noTimeTask.isOverdue, false);
    });

    test('durationMinutes calculates correctly', () {
      expect(sampleTask.durationMinutes, 60);
    });

    test('durationMinutes returns null when endTime is null', () {
      final noEndTask = sampleTask.copyWith(clearEndTime: true);

      expect(noEndTask.durationMinutes, null);
    });

    test('recurrenceRule enum conversion works', () {
      final dailyTask = sampleTask.copyWith(
        recurrenceRule: RecurrenceRule.daily,
      );
      final json = dailyTask.toJson();
      final restored = Task.fromJson(json);

      expect(restored.recurrenceRule, RecurrenceRule.daily);
    });
  });
}
