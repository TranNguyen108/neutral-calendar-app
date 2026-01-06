import 'package:get/get.dart';
import '../models/task.dart';
import '../models/project.dart';

/// Service for validating data before storage operations
/// Prevents data corruption and ensures data integrity
class DataValidator {
  /// Validate a Task object
  static ValidationResult validateTask(Map<String, dynamic> json) {
    final errors = <String>[];

    // Required fields
    if (!json.containsKey('id') ||
        json['id'] == null ||
        json['id'].toString().isEmpty) {
      errors.add('Task must have a valid id');
    }

    if (!json.containsKey('title') ||
        json['title'] == null ||
        json['title'].toString().trim().isEmpty) {
      errors.add('Task must have a non-empty title');
    }

    if (!json.containsKey('date') || json['date'] == null) {
      errors.add('Task must have a valid date');
    } else {
      try {
        DateTime.parse(json['date'].toString());
      } catch (e) {
        errors.add('Task date is not a valid ISO8601 date: ${json['date']}');
      }
    }

    // Validate priority
    if (json.containsKey('priority')) {
      final validPriorities = ['high', 'medium', 'low'];
      if (!validPriorities.contains(json['priority'])) {
        errors.add('Invalid priority value: ${json['priority']}');
      }
    }

    // Validate status
    if (json.containsKey('status')) {
      final validStatuses = ['todo', 'in_progress', 'done'];
      if (!validStatuses.contains(json['status'])) {
        errors.add('Invalid status value: ${json['status']}');
      }
    }

    // Validate recurrence rule
    if (json.containsKey('recurrenceRule')) {
      final validRules = ['none', 'daily', 'weekly', 'monthly'];
      if (!validRules.contains(json['recurrenceRule'])) {
        errors.add('Invalid recurrence rule: ${json['recurrenceRule']}');
      }
    }

    // Validate timestamps
    if (json.containsKey('createdAt')) {
      try {
        DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        errors.add('Invalid createdAt timestamp: ${json['createdAt']}');
      }
    }

    if (json.containsKey('updatedAt')) {
      try {
        DateTime.parse(json['updatedAt'].toString());
      } catch (e) {
        errors.add('Invalid updatedAt timestamp: ${json['updatedAt']}');
      }
    }

    // Validate subtask order (must be non-negative)
    if (json.containsKey('subtaskOrder') && json['subtaskOrder'] != null) {
      final order = json['subtaskOrder'];
      if (order is! int || order < 0) {
        errors.add('subtaskOrder must be a non-negative integer');
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate a Project object
  static ValidationResult validateProject(Map<String, dynamic> json) {
    final errors = <String>[];

    // Required fields
    if (!json.containsKey('id') ||
        json['id'] == null ||
        json['id'].toString().isEmpty) {
      errors.add('Project must have a valid id');
    }

    if (!json.containsKey('name') ||
        json['name'] == null ||
        json['name'].toString().trim().isEmpty) {
      errors.add('Project must have a non-empty name');
    }

    // Validate color value (must be valid color int)
    if (json.containsKey('colorValue')) {
      final color = json['colorValue'];
      if (color is! int) {
        errors.add('colorValue must be an integer');
      }
    }

    // Validate icon code point
    if (json.containsKey('iconCodePoint')) {
      final icon = json['iconCodePoint'];
      if (icon is! int) {
        errors.add('iconCodePoint must be an integer');
      }
    }

    // Validate order (must be non-negative)
    if (json.containsKey('order') && json['order'] != null) {
      final order = json['order'];
      if (order is! int || order < 0) {
        errors.add('order must be a non-negative integer');
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate a Section object
  static ValidationResult validateSection(Map<String, dynamic> json) {
    final errors = <String>[];

    // Required fields
    if (!json.containsKey('id') ||
        json['id'] == null ||
        json['id'].toString().isEmpty) {
      errors.add('Section must have a valid id');
    }

    if (!json.containsKey('name') ||
        json['name'] == null ||
        json['name'].toString().trim().isEmpty) {
      errors.add('Section must have a non-empty name');
    }

    if (!json.containsKey('projectId') ||
        json['projectId'] == null ||
        json['projectId'].toString().isEmpty) {
      errors.add('Section must have a valid projectId');
    }

    // Validate order (must be non-negative)
    if (json.containsKey('order') && json['order'] != null) {
      final order = json['order'];
      if (order is! int || order < 0) {
        errors.add('order must be a non-negative integer');
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate a list of tasks
  static ValidationResult validateTaskList(List<dynamic> jsonList) {
    final errors = <String>[];

    for (int i = 0; i < jsonList.length; i++) {
      final item = jsonList[i];
      if (item is! Map<String, dynamic>) {
        errors.add('Item at index $i is not a valid JSON object');
        continue;
      }

      final result = validateTask(item);
      if (!result.isValid) {
        errors.add('Task at index $i has errors: ${result.errors.join(', ')}');
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate a list of projects
  static ValidationResult validateProjectList(List<dynamic> jsonList) {
    final errors = <String>[];

    for (int i = 0; i < jsonList.length; i++) {
      final item = jsonList[i];
      if (item is! Map<String, dynamic>) {
        errors.add('Item at index $i is not a valid JSON object');
        continue;
      }

      final result = validateProject(item);
      if (!result.isValid) {
        errors
            .add('Project at index $i has errors: ${result.errors.join(', ')}');
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Check for duplicate IDs in a list
  static bool hasDuplicateIds(List<dynamic> jsonList) {
    final ids = <String>{};
    for (final item in jsonList) {
      if (item is Map<String, dynamic> && item.containsKey('id')) {
        final id = item['id'].toString();
        if (ids.contains(id)) {
          return true;
        }
        ids.add(id);
      }
    }
    return false;
  }

  /// Validate data integrity for tasks
  static DataIntegrityResult checkTaskIntegrity(List<Task> tasks) {
    final issues = <String>[];
    final warnings = <String>[];

    // Check for orphaned subtasks
    final taskIds = tasks.map((t) => t.id).toSet();
    for (final task in tasks) {
      if (task.parentTaskId != null && !taskIds.contains(task.parentTaskId)) {
        warnings.add(
            'Task "${task.title}" (${task.id}) has orphaned parentTaskId: ${task.parentTaskId}');
      }
    }

    // Check for circular references in subtasks
    for (final task in tasks) {
      if (task.parentTaskId != null) {
        final visited = <String>{};
        var current = task.parentTaskId;
        while (current != null) {
          if (visited.contains(current)) {
            issues.add(
                'Circular reference detected in task hierarchy for task ${task.id}');
            break;
          }
          visited.add(current);
          final parent = tasks.firstWhereOrNull((t) => t.id == current);
          current = parent?.parentTaskId;
        }
      }
    }

    // Check for duplicate IDs
    final ids = <String>{};
    for (final task in tasks) {
      if (ids.contains(task.id)) {
        issues.add('Duplicate task ID found: ${task.id}');
      }
      ids.add(task.id);
    }

    return DataIntegrityResult(
      isHealthy: issues.isEmpty,
      issues: issues,
      warnings: warnings,
    );
  }

  /// Validate data integrity for projects
  static DataIntegrityResult checkProjectIntegrity(
    List<Project> projects,
    List<Task> tasks,
  ) {
    final issues = <String>[];
    final warnings = <String>[];

    // Check for duplicate IDs
    final projectIds = <String>{};
    for (final project in projects) {
      if (projectIds.contains(project.id)) {
        issues.add('Duplicate project ID found: ${project.id}');
      }
      projectIds.add(project.id);
    }

    // Check for orphaned tasks (tasks with projectId not in projects)
    final validProjectIds = projects.map((p) => p.id).toSet();
    for (final task in tasks) {
      if (task.projectId != null && !validProjectIds.contains(task.projectId)) {
        warnings.add(
            'Task "${task.title}" (${task.id}) references non-existent project: ${task.projectId}');
      }
    }

    return DataIntegrityResult(
      isHealthy: issues.isEmpty,
      issues: issues,
      warnings: warnings,
    );
  }
}

/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });

  @override
  String toString() {
    if (isValid) return 'Validation passed';
    return 'Validation failed: ${errors.join('; ')}';
  }
}

/// Result of a data integrity check
class DataIntegrityResult {
  final bool isHealthy;
  final List<String> issues;
  final List<String> warnings;

  DataIntegrityResult({
    required this.isHealthy,
    required this.issues,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() {
    final buffer = StringBuffer();
    if (isHealthy && !hasWarnings) {
      return 'Data integrity check passed';
    }
    if (!isHealthy) {
      buffer.writeln('Data integrity issues found:');
      for (final issue in issues) {
        buffer.writeln('  - $issue');
      }
    }
    if (hasWarnings) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    return buffer.toString();
  }
}
