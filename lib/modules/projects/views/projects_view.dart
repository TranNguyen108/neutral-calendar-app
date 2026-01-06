import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controllers/projects_controller.dart';
import 'widgets/project_card.dart';

class ProjectsView extends GetView<ProjectsController> {
  const ProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(ProjectsController());

    return Scaffold(
      appBar: AppBar(
        title: Text('projects'.tr),
        elevation: 0,
        actions: [
          Obx(() => IconButton(
                icon: Icon(controller.showArchived.value
                    ? Icons.archive
                    : Icons.archive_outlined),
                onPressed: controller.toggleShowArchived,
                tooltip: controller.showArchived.value
                    ? 'hide_archived'.tr
                    : 'show_archived'.tr,
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'no_projects'.tr,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'create_first_project'.tr,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.loadProjects(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.projects.length,
            itemBuilder: (context, index) {
              final project = controller.projects[index];
              return ProjectCard(
                project: project,
                onTap: () => Get.toNamed(
                  AppRoutes.projectDetail,
                  parameters: {'projectId': project.id},
                ),
                onEdit: () => _showEditProjectDialog(project),
                onDelete: () => controller.deleteProject(project.id),
                onArchive: () => controller.archiveProject(project.id),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(),
        icon: const Icon(Icons.add),
        label: Text('new_project'.tr),
      ),
    );
  }

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final selectedColor = Rx<Color>(Colors.blue);
    final selectedIcon = Rx<IconData>(Icons.work);

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

    Get.dialog(
      AlertDialog(
        title: Text('create_project'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'project_name'.tr,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'description'.tr,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('color'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    children: colorOptions.map((color) {
                      return GestureDetector(
                        onTap: () => selectedColor.value = color,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor.value == color
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 16),
              Text('icon'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    children: iconOptions.map((icon) {
                      return GestureDetector(
                        onTap: () => selectedIcon.value = icon,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: selectedIcon.value == icon
                                ? Colors.grey[300]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 28),
                        ),
                      );
                    }).toList(),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                Get.snackbar('error'.tr, 'enter_project_name'.tr);
                return;
              }

              controller.createProject(
                name: nameController.text.trim(),
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
                color: selectedColor.value,
                icon: selectedIcon.value,
              );
              Get.back();
            },
            child: Text('create'.tr),
          ),
        ],
      ),
    );
  }

  void _showEditProjectDialog(project) {
    // Similar to create, but pre-fill values
    // Implementation omitted for brevity - similar pattern
  }
}
