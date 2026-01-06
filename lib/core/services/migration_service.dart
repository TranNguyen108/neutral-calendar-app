import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/project.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import 'storage_service.dart';

/// Handles data migrations between app versions
/// Ensures smooth upgrades without data loss
class MigrationService extends GetxService {
  final TaskRepository _taskRepo;
  final ProjectRepository _projectRepo;
  final StorageService _storage;

  // Migration version tracking
  static const String _versionKey = 'migration_version';
  static const int _currentVersion = 1;

  MigrationService(this._taskRepo, this._projectRepo, this._storage);

  /// Run all pending migrations
  Future<void> runMigrations() async {
    final lastVersion = _storage.read<int>(_versionKey) ?? 0;

    if (lastVersion < _currentVersion) {
      Get.log('Running migrations from v$lastVersion to v$_currentVersion');

      // Run migrations in order
      if (lastVersion < 1) {
        await _migrationV1CategoriesToProjects();
      }

      // Update version
      await _storage.write(_versionKey, _currentVersion);
      Get.log('Migrations complete');
    }
  }

  /// Migration V1: Convert flat categories to projects
  /// This is the big one for projects/hierarchy feature
  Future<void> _migrationV1CategoriesToProjects() async {
    Get.log('Migration V1: Categories → Projects');

    // 1. Ensure Inbox project exists
    var projects = _projectRepo.getProjects();
    if (!projects.any((p) => p.id == Project.inboxId)) {
      await _projectRepo.addProject(Project.inbox());
    }

    // 2. Get all tasks with categories
    final tasks = _taskRepo.getTasks();
    final categories = tasks
        .where((t) => t.category != null && t.category!.isNotEmpty)
        .map((t) => t.category!)
        .toSet()
        .toList();

    Get.log('Found ${categories.length} categories to migrate');

    // 3. Create projects from categories
    final colorOptions = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final iconOptions = [
      Icons.work,
      Icons.school,
      Icons.person,
      Icons.favorite,
      Icons.home,
      Icons.shopping_cart,
      Icons.fitness_center,
      Icons.restaurant,
    ];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final now = DateTime.now();

      final project = Project(
        id: 'project_${now.millisecondsSinceEpoch}_$i',
        name: category,
        description: 'Migrated from category',
        colorValue: colorOptions[i % colorOptions.length].toARGB32(),
        iconCodePoint: iconOptions[i % iconOptions.length].codePoint,
        order: i + 1, // Inbox is 0
        createdAt: now,
        updatedAt: now,
      );

      await _projectRepo.addProject(project);

      // 4. Update tasks to use projectId
      final categoryTasks = tasks.where((t) => t.category == category).toList();
      Get.log('Migrating ${categoryTasks.length} tasks to project "$category"');

      for (var task in categoryTasks) {
        final updated = task.copyWith(
          projectId: project.id,
          updatedAt: DateTime.now(),
          // Keep category for backward compat
        );
        await _taskRepo.updateTask(updated);
      }
    }

    // 5. Move tasks without category to Inbox
    final uncategorized = tasks
        .where((t) => t.category == null || t.category!.isEmpty)
        .toList();

    if (uncategorized.isNotEmpty) {
      Get.log('Moving ${uncategorized.length} uncategorized tasks to Inbox');
      for (var task in uncategorized) {
        final updated = task.copyWith(
          projectId: Project.inboxId,
          updatedAt: DateTime.now(),
        );
        await _taskRepo.updateTask(updated);
      }
    }

    Get.log('Migration V1 complete: ${tasks.length} tasks migrated');
  }

  /// Check if migration is needed (for UI prompt)
  bool isMigrationNeeded() {
    final lastVersion = _storage.read<int>(_versionKey) ?? 0;
    return lastVersion < _currentVersion;
  }
}
