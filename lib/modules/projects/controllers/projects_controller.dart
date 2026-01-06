import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/project.dart';
import '../../../core/repositories/project_repository.dart';
import '../../../core/utils/task_filters.dart';

/// Controller for managing all projects
class ProjectsController extends GetxController {
  final ProjectRepository _projectRepo = Get.find<ProjectRepository>();

  final projects = <Project>[].obs;
  final isLoading = false.obs;
  final showArchived = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  void loadProjects() {
    isLoading.value = true;
    try {
      projects.value = _projectRepo.getProjects(
        includeArchived: showArchived.value,
      );
      projects.sort((a, b) => a.order.compareTo(b.order));
    } finally {
      isLoading.value = false;
    }
  }

  void toggleShowArchived() {
    showArchived.value = !showArchived.value;
    loadProjects();
  }

  Future<void> createProject({
    required String name,
    String? description,
    required Color color,
    required IconData icon,
  }) async {
    final now = DateTime.now();
    final maxOrder = projects.isEmpty
        ? 0
        : projects.map((p) => p.order).reduce((a, b) => a > b ? a : b);

    final project = Project(
      id: 'project_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      colorValue: color.toARGB32(),
      iconCodePoint: icon.codePoint,
      order: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    );

    await _projectRepo.addProject(project);
    loadProjects();

    Get.snackbar(
      'success'.tr,
      'project_created'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> updateProject(Project project) async {
    await _projectRepo.updateProject(
      project.copyWith(updatedAt: DateTime.now()),
    );
    loadProjects();
  }

  Future<void> deleteProject(String projectId) async {
    if (projectId == Project.inboxId) {
      Get.snackbar(
        'error'.tr,
        'cannot_delete_inbox'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_project'.tr),
        content: Text('delete_project_warning'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _projectRepo.deleteProject(
        projectId,
        moveTasksToProjectId: Project.inboxId,
      );
      loadProjects();

      Get.snackbar(
        'success'.tr,
        'project_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> archiveProject(String projectId) async {
    await _projectRepo.archiveProject(projectId, true);
    loadProjects();
  }

  Future<void> unarchiveProject(String projectId) async {
    await _projectRepo.archiveProject(projectId, false);
    loadProjects();
  }

  // Get project statistics
  Map<String, int> getProjectStats(String projectId) {
    final tasks = Get.find<dynamic>().getTasks() as List;
    final projectTasks = tasks.forProject(projectId);

    return {
      'total': projectTasks.length,
      'completed': projectTasks.completed().length,
      'today': projectTasks.forToday().length,
    };
  }
}
