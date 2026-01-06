import '../models/project.dart';
import '../models/section.dart';

/// Repository interface for project data operations
abstract class ProjectRepository {
  /// Get all projects (active only)
  List<Project> getProjects({bool includeArchived = false});

  /// Get a single project by ID
  Project? getProjectById(String id);

  /// Get a single project by ID (alias for compatibility)
  Project? getById(String id);

  /// Get sections for a specific project
  List<Section> getSectionsForProject(String projectId);

  /// Get a single section by ID
  Section? getSectionById(String id);

  /// Add a new project
  Future<void> addProject(Project project);

  /// Update an existing project
  Future<void> updateProject(Project project);

  /// Delete a project (and handle orphan tasks)
  Future<void> deleteProject(String projectId, {String? moveTasksToProjectId});

  /// Archive/unarchive a project
  Future<void> archiveProject(String projectId, bool isArchived);

  /// Add a new section to a project
  Future<void> addSection(Section section);

  /// Update an existing section
  Future<void> updateSection(Section section);

  /// Delete a section (moves tasks to "No Section")
  Future<void> deleteSection(String sectionId);

  /// Reorder projects
  Future<void> reorderProjects(List<String> projectIds);

  /// Reorder sections within a project
  Future<void> reorderSections(String projectId, List<String> sectionIds);

  /// Clear all projects
  Future<void> clearAll();
}
