import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nc_app/core/models/task.dart';
import 'package:nc_app/core/services/recurrence_service.dart';
import 'package:nc_app/core/services/storage_service.dart';

void main() {
  group('RecurrenceService Tests', () {
    late RecurrenceService recurrenceService;
    late StorageService storageService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      storageService = StorageService();
      await storageService.init();
      Get.put(storageService);
      recurrenceService = RecurrenceService();
      Get.put(recurrenceService);
    });

    test('generateNextOccurrence creates daily recurring task', () {
      final task = Task(
        id: '1',
        title: 'Daily Task',
        date: DateTime(2026, 1, 3),
        startTime: DateTime(2026, 1, 3, 9, 0),
        endTime: DateTime(2026, 1, 3, 10, 0),
        priority: Priority.medium,
        status: TaskStatus.done,
        category: 'Work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recurrenceRule: RecurrenceRule.daily,
      );

      final nextTask = recurrenceService.generateNextOccurrence(task);

      expect(nextTask, isNotNull);
      expect(nextTask!.date.day, 4); // Next day
      expect(nextTask.startTime!.day, 4);
      expect(nextTask.endTime!.day, 4);
      expect(nextTask.status, TaskStatus.todo);
      expect(nextTask.totalFocusMinutes, 0); // Reset focus
    });

    test('generateNextOccurrence creates weekly recurring task', () {
      final task = Task(
        id: '1',
        title: 'Weekly Task',
        date: DateTime(2026, 1, 3),
        startTime: DateTime(2026, 1, 3, 14, 0),
        priority: Priority.high,
        status: TaskStatus.done,
        category: 'Study',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recurrenceRule: RecurrenceRule.weekly,
      );

      final nextTask = recurrenceService.generateNextOccurrence(task);

      expect(nextTask, isNotNull);
      expect(nextTask!.date.day, 10); // 7 days later
      expect(nextTask.startTime!.day, 10);
    });

    test('generateNextOccurrence creates monthly recurring task', () {
      final task = Task(
        id: '1',
        title: 'Monthly Task',
        date: DateTime(2026, 1, 15),
        startTime: DateTime(2026, 1, 15, 10, 0),
        priority: Priority.low,
        status: TaskStatus.done,
        category: 'Personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recurrenceRule: RecurrenceRule.monthly,
      );

      final nextTask = recurrenceService.generateNextOccurrence(task);

      expect(nextTask, isNotNull);
      expect(nextTask!.date.month, 2); // Next month
      expect(nextTask.date.day, 15); // Same day
    });

    test('generateNextOccurrence returns null for non-recurring task', () {
      final task = Task(
        id: '1',
        title: 'One-time Task',
        date: DateTime.now(),
        priority: Priority.medium,
        status: TaskStatus.done,
        category: 'Work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recurrenceRule: RecurrenceRule.none,
      );

      final nextTask = recurrenceService.generateNextOccurrence(task);

      expect(nextTask, isNull);
    });

    test('generateNextOccurrence respects recurrenceEndDate', () {
      final task = Task(
        id: '1',
        title: 'Limited Recurring Task',
        date: DateTime(2026, 1, 3),
        priority: Priority.medium,
        status: TaskStatus.done,
        category: 'Work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recurrenceRule: RecurrenceRule.daily,
        recurrenceEndDate: DateTime(2026, 1, 3), // Same day
      );

      final nextTask = recurrenceService.generateNextOccurrence(task);

      expect(nextTask, isNull); // Should not create next occurrence
    });

    test('generateNextOccurrence preserves task properties', () {
      final task = Task(
        id: '1',
        title: 'Daily Meeting',
        date: DateTime(2026, 1, 3),
        startTime: DateTime(2026, 1, 3, 15, 0),
        endTime: DateTime(2026, 1, 3, 16, 0),
        priority: Priority.high,
        status: TaskStatus.done,
        category: 'Work',
        note: 'Important meeting',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recurrenceRule: RecurrenceRule.daily,
        reminderMinutesBefore: 15,
      );

      final nextTask = recurrenceService.generateNextOccurrence(task);

      expect(nextTask, isNotNull);
      expect(nextTask!.title, task.title);
      expect(nextTask.priority, task.priority);
      expect(nextTask.category, task.category);
      expect(nextTask.note, task.note);
      expect(nextTask.recurrenceRule, task.recurrenceRule);
      expect(nextTask.reminderMinutesBefore, task.reminderMinutesBefore);
    });

    test('generateNextOccurrence with custom interval', () {
      final task = Task(
        id: '1',
        title: 'Custom Recurring Task',
        date: DateTime(2026, 1, 3),
        priority: Priority.medium,
        status: TaskStatus.done,
        category: 'Work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recurrenceRule: RecurrenceRule.custom,
        recurrenceInterval: 3, // Every 3 days
      );

      final nextTask = recurrenceService.generateNextOccurrence(task);

      expect(nextTask, isNotNull);
      expect(nextTask!.date.day, 6); // 3 days later
    });
  });
}
