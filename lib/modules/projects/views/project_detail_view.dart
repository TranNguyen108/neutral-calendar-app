import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/section.dart';
import '../../../core/models/task.dart';
import '../../../routes/app_routes.dart';
import '../../quick_add/views/quick_add_bottom_sheet.dart';
import '../controllers/project_detail_controller.dart';

class ProjectDetailView extends GetView<ProjectDetailController> {
  const ProjectDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.project.value?.name ?? 'project'.tr)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit project dialog
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final project = controller.project.value;
        if (project == null) {
          return const Center(child: Text('Project not found'));
        }

        return RefreshIndicator(
          onRefresh: () async => controller.loadProject(),
          child: CustomScrollView(
            slivers: [
              // Project header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: project.color.withValues(alpha: 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: project.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              project.icon,
                              color: project.color,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (project.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    project.description!,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: controller.getProgressPercentage() / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                project.color,
                              ),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${controller.getCompletedTasksCount()}/${controller.tasks.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Sections with tasks
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < controller.sections.length) {
                    final section = controller.sections[index];
                    return _buildSectionCard(section);
                  } else if (index == controller.sections.length) {
                    // Tasks without section
                    final noSectionTasks = controller.getTasksForSection(null);
                    if (noSectionTasks.isNotEmpty) {
                      return _buildNoSectionTasks(noSectionTasks);
                    }
                  }
                  return null;
                }, childCount: controller.sections.length + 1),
              ),

              // Add section button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddSectionDialog(),
                    icon: const Icon(Icons.add),
                    label: Text('add_section'.tr),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open quick add with this project pre-selected
          QuickAddBottomSheet.show();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionCard(Section section) {
    final tasks = controller.getTasksForSection(section.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          InkWell(
            onTap: () => controller.toggleSectionCollapse(section.id),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    section.isCollapsed
                        ? Icons.chevron_right
                        : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${tasks.length}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        controller.deleteSection(section.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tasks in section
          if (!section.isCollapsed && tasks.isNotEmpty)
            ...tasks.map((task) => _buildTaskTile(task)),
        ],
      ),
    );
  }

  Widget _buildNoSectionTasks(List<Task> tasks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'no_section'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...tasks.map((task) => _buildTaskTile(task)),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return ListTile(
      leading: Checkbox(
        value: task.status == TaskStatus.done,
        onChanged: (value) {
          // Toggle task status
        },
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.status == TaskStatus.done
              ? TextDecoration.lineThrough
              : null,
        ),
      ),
      subtitle: task.startTime != null
          ? Text(
              '${task.startTime!.hour}:${task.startTime!.minute.toString().padLeft(2, '0')}',
            )
          : null,
      trailing: Icon(
        task.priority == Priority.high
            ? Icons.flag
            : task.priority == Priority.low
            ? Icons.flag_outlined
            : null,
        color: task.priority == Priority.high ? Colors.red : Colors.grey,
        size: 20,
      ),
      onTap: () => Get.toNamed(AppRoutes.taskDetail, arguments: task),
    );
  }

  void _showAddSectionDialog() {
    final nameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('add_section'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'section_name'.tr,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                controller.addSection(nameController.text.trim());
                Get.back();
              }
            },
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }
}
