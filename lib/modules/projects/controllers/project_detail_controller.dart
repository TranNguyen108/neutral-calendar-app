import 'package:get/get.dart';

import '../../../core/models/project.dart';
import '../../../core/models/section.dart';
import '../../../core/models/task.dart';
import '../../../core/repositories/project_repository.dart';
import '../../../core/repositories/task_repository.dart';
import '../../../core/utils/task_filters.dart';

/// Controller for managing a single project with its sections and tasks
class ProjectDetailController extends GetxController {
  final ProjectRepository _projectRepo = Get.find<ProjectRepository>();
  final TaskRepository _taskRepo = Get.find<TaskRepository>();

  final Rx<Project?> project = Rx<Project?>(null);
  final sections = <Section>[].obs;
  final tasks = <Task>[].obs;
  final isLoading = false.obs;

  String get projectId => Get.parameters['projectId'] ?? '';

  @override
  void onInit() {
    super.onInit();
    loadProject();
  }

  void loadProject() {
    isLoading.value = true;
    try {
      project.value = _projectRepo.getProjectById(projectId);
      if (project.value == null) {
        Get.back();
        Get.snackbar('error'.tr, 'project_not_found'.tr);
        return;
      }

      sections.value = _projectRepo.getSectionsForProject(projectId);
      tasks.value = _taskRepo.getTasks().forProject(projectId);

      // Sort tasks by section, then by date
      tasks.sort((a, b) {
        if (a.sectionId != b.sectionId) {
          if (a.sectionId == null) return 1; // No section tasks last
          if (b.sectionId == null) return -1;

          final sectionA = sections.firstWhere((s) => s.id == a.sectionId,
              orElse: () => sections.first);
          final sectionB = sections.firstWhere((s) => s.id == b.sectionId,
              orElse: () => sections.first);
          return sectionA.order.compareTo(sectionB.order);
        }
        return a.date.compareTo(b.date);
      });
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSection(String name) async {
    final now = DateTime.now();
    final maxOrder = sections.isEmpty
        ? 0
        : sections.map((s) => s.order).reduce((a, b) => a > b ? a : b);

    final section = Section(
      id: 'section_${now.millisecondsSinceEpoch}',
      projectId: projectId,
      name: name,
      order: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    );

    await _projectRepo.addSection(section);
    loadProject();
  }

  Future<void> updateSection(Section section) async {
    await _projectRepo
        .updateSection(section.copyWith(updatedAt: DateTime.now()));
    loadProject();
  }

  Future<void> deleteSection(String sectionId) async {
    await _projectRepo.deleteSection(sectionId);
    loadProject();
  }

  Future<void> toggleSectionCollapse(String sectionId) async {
    final section = sections.firstWhere((s) => s.id == sectionId);
    await updateSection(section.copyWith(isCollapsed: !section.isCollapsed));
  }

  List<Task> getTasksForSection(String? sectionId) {
    return tasks.forSection(sectionId);
  }

  int getCompletedTasksCount() {
    return tasks.completed().length;
  }

  double getProgressPercentage() {
    if (tasks.isEmpty) return 0;
    return (getCompletedTasksCount() / tasks.length) * 100;
  }
}
