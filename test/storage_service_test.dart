import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nc_app/core/models/task.dart';
import 'package:nc_app/core/services/storage_service.dart';

void main() {
  group('StorageService Tests', () {
    late StorageService storageService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      storageService = StorageService();
      await storageService.init();
      Get.put(storageService);
    });

    tearDown(() async {
      // Clear all data after each test
      final tasks = storageService.getTasks();
      for (var task in tasks) {
        await storageService.deleteTask(task.id);
      }
    });

    test('addTask adds task to storage', () async {
      final task = Task(
        id: 'test1',
        title: 'Test Task',
        date: DateTime.now(),
        priority: Priority.medium,
        status: TaskStatus.todo,
        category: 'Work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await storageService.addTask(task);
      final tasks = storageService.getTasks();

      expect(tasks.length, 1);
      expect(tasks.first.id, 'test1');
      expect(tasks.first.title, 'Test Task');
    });

    test('updateTask updates existing task', () async {
      final task = Task(
        id: 'test2',
        title: 'Original',
        date: DateTime.now(),
        priority: Priority.low,
        status: TaskStatus.todo,
        category: 'Personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await storageService.addTask(task);

      final updatedTask = task.copyWith(
        title: 'Updated',
        priority: Priority.high,
      );
      await storageService.updateTask(updatedTask);

      final tasks = storageService.getTasks();
      expect(tasks.first.title, 'Updated');
      expect(tasks.first.priority, Priority.high);
    });

    test('deleteTask removes task from storage', () async {
      final task = Task(
        id: 'test3',
        title: 'To Delete',
        date: DateTime.now(),
        priority: Priority.medium,
        status: TaskStatus.todo,
        category: 'Work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await storageService.addTask(task);
      expect(storageService.getTasks().length, 1);

      await storageService.deleteTask('test3');
      expect(storageService.getTasks().isEmpty, true);
    });

    test('searchTasks filters by query', () async {
      final tasks = [
        Task(
          id: '1',
          title: 'Meeting with client',
          date: DateTime.now(),
          priority: Priority.high,
          status: TaskStatus.todo,
          category: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: '2',
          title: 'Review code',
          date: DateTime.now(),
          priority: Priority.medium,
          status: TaskStatus.todo,
          category: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: '3',
          title: 'Gym workout',
          date: DateTime.now(),
          priority: Priority.low,
          status: TaskStatus.todo,
          category: 'Health',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (var task in tasks) {
        await storageService.addTask(task);
      }

      final results = storageService.searchTasks('meeting');
      expect(results.length, 1);
      expect(results.first.title, 'Meeting with client');
    });

    test('searchTasks filters by priority', () async {
      final tasks = [
        Task(
          id: '1',
          title: 'High priority task',
          date: DateTime.now(),
          priority: Priority.high,
          status: TaskStatus.todo,
          category: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: '2',
          title: 'Low priority task',
          date: DateTime.now(),
          priority: Priority.low,
          status: TaskStatus.todo,
          category: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (var task in tasks) {
        await storageService.addTask(task);
      }

      final results = storageService.searchTasks(
        '',
        priorities: [Priority.high],
      );
      expect(results.length, 1);
      expect(results.first.priority, Priority.high);
    });

    test('searchTasks filters by category', () async {
      final tasks = [
        Task(
          id: '1',
          title: 'Work task',
          date: DateTime.now(),
          priority: Priority.medium,
          status: TaskStatus.todo,
          category: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: '2',
          title: 'Study task',
          date: DateTime.now(),
          priority: Priority.medium,
          status: TaskStatus.todo,
          category: 'Study',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (var task in tasks) {
        await storageService.addTask(task);
      }

      final results = storageService.searchTasks(
        '',
        categories: ['Study'],
      );
      expect(results.length, 1);
      expect(results.first.category, 'Study');
    });

    test('getTotalCompletedTasks returns correct count', () async {
      final tasks = [
        Task(
          id: '1',
          title: 'Done 1',
          date: DateTime.now(),
          priority: Priority.medium,
          status: TaskStatus.done,
          category: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: '2',
          title: 'Done 2',
          date: DateTime.now(),
          priority: Priority.medium,
          status: TaskStatus.done,
          category: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: '3',
          title: 'Todo',
          date: DateTime.now(),
          priority: Priority.medium,
          status: TaskStatus.todo,
          category: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (var task in tasks) {
        await storageService.addTask(task);
      }

      expect(storageService.getTotalCompletedTasks(), 2);
    });
  });
}
