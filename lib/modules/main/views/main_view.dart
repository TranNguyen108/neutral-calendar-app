import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../../today/views/today_view.dart';
import '../../calendar/views/calendar_view.dart';
import '../../projects/views/projects_view.dart';
import '../../focus/views/focus_view.dart';
import '../../profile/views/profile_view.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const TodayView(),
      const CalendarView(),
      const ProjectsView(),
      const FocusView(),
      const ProfileView(),
    ];

    return Obx(() => Scaffold(
          body: pages[controller.currentIndex.value],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.today),
                label: 'nav_today'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month),
                label: 'nav_calendar'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.folder_outlined),
                label: 'nav_projects'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.center_focus_strong),
                label: 'nav_focus'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: 'nav_profile'.tr,
              ),
            ],
          ),
        ));
  }
}
