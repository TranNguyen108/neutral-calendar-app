import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/focus_controller.dart';

class FocusView extends GetView<FocusController> {
  const FocusView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(FocusController());

    return Scaffold(
      appBar: AppBar(
        title: Text('focus_title'.tr),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'pomodoro_timer'.tr,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),
              Obx(() => Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 8),
                    ),
                    child: Center(
                      child: Text(
                        controller.getFormattedTime(),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 60),
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!controller.isRunning.value) ...[
                        ElevatedButton.icon(
                          onPressed: controller.startTimer,
                          icon: const Icon(Icons.play_arrow),
                          label: Text('start'.tr),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: controller.pauseTimer,
                          icon: const Icon(Icons.pause),
                          label: Text('pause'.tr),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: controller.resetTimer,
                        icon: const Icon(Icons.refresh),
                        label: Text('reset'.tr),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // TODO: Wire this up to a \"Select Task\" button in the UI
  // void _showTaskSelector(BuildContext context) {
  //   Get.bottomSheet(
  //     Container(
  //       padding: const EdgeInsets.all(20),
  //       decoration: const BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.only(
  //           topLeft: Radius.circular(20),
  //           topRight: Radius.circular(20),
  //         ),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'select_task'.tr,
  //             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 16),
  //           Obx(() {
  //             if (controller.todayTasks.isEmpty) {
  //               return Padding(
  //                 padding: const EdgeInsets.all(20),
  //                 child: Center(
  //                   child: Text(
  //                     'no_tasks_today'.tr,
  //                     style: TextStyle(color: Colors.grey.shade600),
  //                   ),
  //                 ),
  //               );
  //             }
  //
  //             return ListView.builder(
  //               shrinkWrap: true,
  //               itemCount: controller.todayTasks.length,
  //               itemBuilder: (context, index) {
  //                 final task = controller.todayTasks[index];
  //                 return ListTile(
  //                   leading: Container(
  //                     width: 4,
  //                     height: 40,
  //                     decoration: BoxDecoration(
  //                       color: _getPriorityColor(task.priority),
  //                       borderRadius: BorderRadius.circular(2),
  //                     ),
  //                   ),
  //                   title: Text(task.title),
  //                   subtitle: task.totalFocusMinutes > 0
  //                       ? Text('${task.totalFocusMinutes} min focused')
  //                       : null,
  //                   onTap: () {
  //                     controller.selectTask(task);
  //                     Get.back();
  //                   },
  //                 );
  //               },
  //             );
  //           }),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Color _getPriorityColor(Priority priority) {
  //   switch (priority) {
  //     case Priority.high:
  //       return Colors.red;
  //     case Priority.medium:
  //       return Colors.orange;
  //     case Priority.low:
  //       return Colors.green;
  //   }
  // }
}
