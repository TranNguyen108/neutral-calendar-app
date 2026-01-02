import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../controllers/calendar_controller.dart';
import '../../../core/models/task.dart';
import '../../../routes/app_routes.dart';

class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(CalendarController());

    return Scaffold(
      appBar: AppBar(
        title: Text('calendar_title'.tr),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed(AppRoutes.SEARCH),
          ),
        ],
      ),
      body: Obx(() => Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: controller.focusedDay.value,
                selectedDayPredicate: (day) =>
                    isSameDay(controller.selectedDay.value, day),
                onDaySelected: (selected, focused) {
                  controller.onDaySelected(selected, focused);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: controller.getTasksForDay,
              ),
              const Divider(),
              Expanded(
                child: _buildTasksList(),
              ),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.ADD_TASK);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTasksList() {
    return Obx(() {
      final tasks = controller.getTasksForDay(controller.selectedDay.value);
      if (tasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'no_tasks_day'.tr,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final isOverdue = task.isOverdue;
          final cardColor = isOverdue ? Colors.red.shade50 : null;
          final borderColor = isOverdue ? Colors.red : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 1,
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  task.status == TaskStatus.done
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: task.status == TaskStatus.done
                      ? Colors.green
                      : Colors.grey,
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
                    ? Text(DateFormat('HH:mm').format(task.startTime!))
                    : null,
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () {
                  Get.toNamed(AppRoutes.TASK_DETAIL, arguments: task);
                },
              ),
            ),
          );
        },
      );
    });
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }
}
