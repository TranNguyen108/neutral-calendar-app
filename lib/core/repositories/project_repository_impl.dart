import 'package:get/get.dart';

import '../models/project.dart';
import '../models/section.dart';
import '../repositories/project_repository.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

/// Implementation of ProjectRepository using StorageService
class ProjectRepositoryImpl implements ProjectRepository {
  final StorageService _storage;
  final Logger _logger = Get.find<Logger>();

  ProjectRepositoryImpl(this._storage);

  @override
  List<Project> getProjects({bool includeArchived = false}) {
    try {
      final projectsJson = _storage.box.read<List>('projects');

      if (projectsJson == null) {
        // First time: create Inbox project
        _logger.info('Creating default Inbox project',
            tag: 'ProjectRepository');
        final inbox = Project.inbox();
        _storage.box.write('projects', [inbox.toJson()]);
        return [inbox];
      }

      final projects = projectsJson
          .map((json) {
            try {
              return Project.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              _logger.error('Failed to parse project JSON',
                  tag: 'ProjectRepository', error: e);
              return null;
            }
          })
          .whereType<Project>() // Filter out nulls from failed parsing
          .toList();

      // Defensive check: ensure Inbox exists
      if (!projects.any((p) => p.id == Project.inboxId)) {
        _logger.warning('Inbox project missing, recreating',
            tag: 'ProjectRepository');
        projects.insert(0, Project.inbox());
      }

      if (!includeArchived) {
        return projects.where((p) => !p.isArchived).toList();
      }
      return projects;
    } catch (e) {
      _logger.error('Error getting projects',
          tag: 'ProjectRepository', error: e);
      // Return Inbox as safe fallback
      return [Project.inbox()];
    }
  }

  @override
  Project? getProjectById(String id) {
    try {
      // Defensive check: validate ID
      if (id.isEmpty) {
        _logger.warning('getProjectById called with empty ID',
            tag: 'ProjectRepository');
        return null;
      }

      return getProjects(includeArchived: true).firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('Project not found'),
      );
    } catch (e) {
      // This is expected when project is not found
      if (e.toString().contains('Project not found')) {
        _logger.info('Project not found: $id', tag: 'ProjectRepository');
      } else {
        _logger.error('Error getting project by ID: $id',
            tag: 'ProjectRepository', error: e);
      }
      return null;
    }
  }

  @override
  Project? getById(String id) => getProjectById(id);

  @override
  List<Section> getSectionsForProject(String projectId) {
    try {
      // Defensive check: validate ID
      if (projectId.isEmpty) {
        _logger.warning('getSectionsForProject called with empty projectId',
            tag: 'ProjectRepository');
        return [];
      }

      final sectionsJson = _storage.box.read<List>('sections');
      if (sectionsJson == null) return [];

      final sections = sectionsJson
          .map((json) {
            try {
              return Section.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              _logger.error('Failed to parse section JSON',
                  tag: 'ProjectRepository', error: e);
              return null;
            }
          })
          .whereType<Section>() // Filter out nulls
          .where((s) => s.projectId == projectId)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      return sections;
    } catch (e) {
      _logger.error('Error getting sections for project: $projectId',
          tag: 'ProjectRepository', error: e);
      return []; // Safe fallback
    }
  }

  @override
  Section? getSectionById(String id) {
    try {
      // Defensive check: validate ID
      if (id.isEmpty) {
        _logger.warning('getSectionById called with empty ID',
            tag: 'ProjectRepository');
        return null;
      }

      final sectionsJson = _storage.box.read<List>('sections');
      if (sectionsJson == null) return null;

      return sectionsJson
          .map((json) {
            try {
              return Section.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .whereType<Section>()
          .firstWhere(
            (s) => s.id == id,
            orElse: () => throw Exception('Section not found'),
          );
    } catch (e) {
      // Expected when section is not found
      if (e.toString().contains('Section not found')) {
        _logger.info('Section not found: $id', tag: 'ProjectRepository');
      } else {
        _logger.error('Error getting section by ID: $id',
            tag: 'ProjectRepository', error: e);
      }
      return null;
    }
  }

  @override
  Future<void> addProject(Project project) async {
    try {
      // Defensive checks: validate project data
      if (project.id.isEmpty) {
        throw Exception('Cannot add project with empty ID');
      }
      if (project.name.trim().isEmpty) {
        throw Exception('Cannot add project with empty name');
      }

      // Check for duplicate ID
      final existingProject = getProjectById(project.id);
      if (existingProject != null) {
        _logger.warning(
            'Project with ID ${project.id} already exists, updating instead',
            tag: 'ProjectRepository');
        await updateProject(project);
        return;
      }

      final projects = getProjects(includeArchived: true);
      projects.add(project);
      await _storage.box
          .write('projects', projects.map((p) => p.toJson()).toList());

      _logger.info('Project added: ${project.id}', tag: 'ProjectRepository');
    } catch (e) {
      _logger.error('Error adding project: ${project.id}',
          tag: 'ProjectRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> updateProject(Project project) async {
    try {
      // Defensive checks: validate project data
      if (project.id.isEmpty) {
        throw Exception('Cannot update project with empty ID');
      }
      if (project.name.trim().isEmpty) {
        throw Exception('Cannot update project with empty name');
      }

      final projects = getProjects(includeArchived: true);
      final index = projects.indexWhere((p) => p.id == project.id);

      if (index == -1) {
        _logger.warning(
            'Project not found for update: ${project.id}, adding instead',
            tag: 'ProjectRepository');
        await addProject(project);
        return;
      }

      projects[index] = project;
      await _storage.box
          .write('projects', projects.map((p) => p.toJson()).toList());

      _logger.info('Project updated: ${project.id}', tag: 'ProjectRepository');
    } catch (e) {
      _logger.error('Error updating project: ${project.id}',
          tag: 'ProjectRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> deleteProject(String projectId,
      {String? moveTasksToProjectId}) async {
    try {
      // Defensive checks
      if (projectId.isEmpty) {
        throw Exception('Cannot delete project with empty ID');
      }

      // Cannot delete Inbox
      if (projectId == Project.inboxId) {
        _logger.error('Attempted to delete Inbox project',
            tag: 'ProjectRepository');
        throw Exception('Cannot delete Inbox project');
      }

      // Verify project exists
      final project = getProjectById(projectId);
      if (project == null) {
        _logger.warning('Project not found for deletion: $projectId',
            tag: 'ProjectRepository');
        return; // Already deleted or doesn't exist
      }

      // Handle orphan tasks
      final tasks = _storage.getTasks();
      final orphanTasks = tasks.where((t) => t.projectId == projectId).toList();

      if (orphanTasks.isNotEmpty) {
        final targetProjectId = moveTasksToProjectId ?? Project.inboxId;

        // Validate target project exists
        if (targetProjectId != Project.inboxId) {
          final targetProject = getProjectById(targetProjectId);
          if (targetProject == null) {
            _logger.warning(
                'Target project not found: $targetProjectId, using Inbox',
                tag: 'ProjectRepository');
            // Fall back to Inbox
            for (var task in orphanTasks) {
              final updated = task.copyWith(
                projectId: Project.inboxId,
                clearSectionId: true,
                updatedAt: DateTime.now(),
              );
              await _storage.updateTask(updated);
            }
          } else {
            for (var task in orphanTasks) {
              final updated = task.copyWith(
                projectId: targetProjectId,
                clearSectionId: true,
                updatedAt: DateTime.now(),
              );
              await _storage.updateTask(updated);
            }
          }
        } else {
          for (var task in orphanTasks) {
            final updated = task.copyWith(
              projectId: targetProjectId,
              clearSectionId: true,
              updatedAt: DateTime.now(),
            );
            await _storage.updateTask(updated);
          }
        }
        _logger.info('Moved ${orphanTasks.length} tasks to $targetProjectId',
            tag: 'ProjectRepository');
      }

      // Delete project
      final projects = getProjects(includeArchived: true);
      projects.removeWhere((p) => p.id == projectId);
      await _storage.box
          .write('projects', projects.map((p) => p.toJson()).toList());

      // Delete sections
      final allSections = _storage.box
              .read<List>('sections')
              ?.map((json) => Section.fromJson(json as Map<String, dynamic>))
              .where((s) => s.projectId != projectId)
              .toList() ??
          [];
      await _storage.box
          .write('sections', allSections.map((s) => s.toJson()).toList());

      _logger.info('Project deleted: $projectId', tag: 'ProjectRepository');
    } catch (e) {
      _logger.error('Error deleting project: $projectId',
          tag: 'ProjectRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> archiveProject(String projectId, bool isArchived) async {
    try {
      // Defensive checks
      if (projectId.isEmpty) {
        throw Exception('Cannot archive project with empty ID');
      }

      // Cannot archive Inbox
      if (projectId == Project.inboxId) {
        _logger.warning('Attempted to archive Inbox project',
            tag: 'ProjectRepository');
        throw Exception('Cannot archive Inbox project');
      }

      final project = getProjectById(projectId);
      if (project == null) {
        _logger.warning('Project not found for archiving: $projectId',
            tag: 'ProjectRepository');
        return; // Project doesn't exist
      }

      final updated = project.copyWith(
        isArchived: isArchived,
        updatedAt: DateTime.now(),
      );
      await updateProject(updated);

      _logger.info(
          'Project ${isArchived ? "archived" : "unarchived"}: $projectId',
          tag: 'ProjectRepository');
    } catch (e) {
      _logger.error('Error archiving project: $projectId',
          tag: 'ProjectRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> addSection(Section section) async {
    try {
      // Defensive checks: validate section data
      if (section.id.isEmpty) {
        throw Exception('Cannot add section with empty ID');
      }
      if (section.name.trim().isEmpty) {
        throw Exception('Cannot add section with empty name');
      }
      if (section.projectId.isEmpty) {
        throw Exception('Cannot add section without project ID');
      }

      // Verify project exists
      final project = getProjectById(section.projectId);
      if (project == null) {
        _logger.error('Project not found for section: ${section.projectId}',
            tag: 'ProjectRepository');
        throw Exception('Cannot add section: project not found');
      }

      // Check for duplicate ID
      final existingSection = getSectionById(section.id);
      if (existingSection != null) {
        _logger.warning(
            'Section with ID ${section.id} already exists, updating instead',
            tag: 'ProjectRepository');
        await updateSection(section);
        return;
      }

      final sections = _storage.box
              .read<List>('sections')
              ?.map((json) => Section.fromJson(json as Map<String, dynamic>))
              .toList() ??
          [];
      sections.add(section);
      await _storage.box
          .write('sections', sections.map((s) => s.toJson()).toList());

      _logger.info('Section added: ${section.id}', tag: 'ProjectRepository');
    } catch (e) {
      _logger.error('Error adding section: ${section.id}',
          tag: 'ProjectRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> updateSection(Section section) async {
    try {
      // Defensive checks
      if (section.id.isEmpty) {
        throw Exception('Cannot update section with empty ID');
      }
      if (section.name.trim().isEmpty) {
        throw Exception('Cannot update section with empty name');
      }

      final sections = _storage.box
              .read<List>('sections')
              ?.map((json) => Section.fromJson(json as Map<String, dynamic>))
              .toList() ??
          [];
      final index = sections.indexWhere((s) => s.id == section.id);

      if (index == -1) {
        _logger.warning(
            'Section not found for update: ${section.id}, adding instead',
            tag: 'ProjectRepository');
        await addSection(section);
        return;
      }

      sections[index] = section;
      await _storage.box
          .write('sections', sections.map((s) => s.toJson()).toList());

      _logger.info('Section updated: ${section.id}', tag: 'ProjectRepository');
    } catch (e) {
      _logger.error('Error updating section: ${section.id}',
          tag: 'ProjectRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> deleteSection(String sectionId) async {
    try {
      // Defensive check
      if (sectionId.isEmpty) {
        throw Exception('Cannot delete section with empty ID');
      }

      // Move tasks to "No Section" (null sectionId)
      final section = getSectionById(sectionId);
      if (section == null) {
        _logger.warning('Section not found for deletion: $sectionId',
            tag: 'ProjectRepository');
        return; // Already deleted or doesn't exist
      }

      final tasks = _storage.getTasks();
      final sectionTasks =
          tasks.where((t) => t.sectionId == sectionId).toList();

      if (sectionTasks.isNotEmpty) {
        for (var task in sectionTasks) {
          final updated = task.copyWith(
            clearSectionId: true,
            updatedAt: DateTime.now(),
          );
          await _storage.updateTask(updated);
        }
        _logger.info('Moved ${sectionTasks.length} tasks from deleted section',
            tag: 'ProjectRepository');
      }

      // Delete section
      final sections = _storage.box
              .read<List>('sections')
              ?.map((json) => Section.fromJson(json as Map<String, dynamic>))
              .where((s) => s.id != sectionId)
              .toList() ??
          [];
      await _storage.box
          .write('sections', sections.map((s) => s.toJson()).toList());

      _logger.info('Section deleted: $sectionId', tag: 'ProjectRepository');
    } catch (e) {
      _logger.error('Error deleting section: $sectionId',
          tag: 'ProjectRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> reorderProjects(List<String> projectIds) async {
    try {
      // Defensive check
      if (projectIds.isEmpty) {
        _logger.warning('reorderProjects called with empty projectIds',
            tag: 'ProjectRepository');
        return; // Nothing to do
      }

      final projects = getProjects(includeArchived: true);
      int reorderedCount = 0;

      for (int i = 0; i < projectIds.length; i++) {
        final index = projects.indexWhere((p) => p.id == projectIds[i]);
        if (index != -1) {
          projects[index] = projects[index].copyWith(order: i);
          reorderedCount++;
        } else {
          _logger.warning('Project not found for reordering: ${projectIds[i]}',
              tag: 'ProjectRepository');
        }
      }

      if (reorderedCount > 0) {
        await _storage.box
            .write('projects', projects.map((p) => p.toJson()).toList());
        _logger.info('Reordered $reorderedCount projects',
            tag: 'ProjectRepository');
      }
    } catch (e) {
      _logger.error('Error reordering projects',
          tag: 'ProjectRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> reorderSections(
      String projectId, List<String> sectionIds) async {
    try {
      // Defensive checks
      if (projectId.isEmpty) {
        throw Exception('Cannot reorder sections: empty projectId');
      }
      if (sectionIds.isEmpty) {
        _logger.warning('reorderSections called with empty sectionIds',
            tag: 'ProjectRepository');
        return; // Nothing to do
      }

      final sections = _storage.box
              .read<List>('sections')
              ?.map((json) => Section.fromJson(json as Map<String, dynamic>))
              .toList() ??
          [];

      int reorderedCount = 0;

      for (int i = 0; i < sectionIds.length; i++) {
        final index = sections.indexWhere(
            (s) => s.id == sectionIds[i] && s.projectId == projectId);
        if (index != -1) {
          sections[index] = sections[index].copyWith(order: i);
          reorderedCount++;
        } else {
          _logger.warning('Section not found for reordering: ${sectionIds[i]}',
              tag: 'ProjectRepository');
        }
      }

      if (reorderedCount > 0) {
        await _storage.box
            .write('sections', sections.map((s) => s.toJson()).toList());
        _logger.info(
            'Reordered $reorderedCount sections for project: $projectId',
            tag: 'ProjectRepository');
      }
    } catch (e) {
      _logger.error('Error reordering sections for project: $projectId',
          tag: 'ProjectRepository', error: e);
      rethrow; // Let caller handle
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _storage.box.remove('projects');
      await _storage.box.remove('sections');
      _logger.info('All projects and sections cleared',
          tag: 'ProjectRepository');
    } catch (e) {
      _logger.error('Error clearing projects and sections',
          tag: 'ProjectRepository', error: e);
      rethrow; // This is critical, let caller handle
    }
  }
}
