import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';

class CalendarController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final tasks = <Task>[].obs;
  final selectedDay = DateTime.now().obs;
  final focusedDay = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  void loadTasks() {
    tasks.value = _storage.getTasks();
  }

  List<Task> getTasksForDay(DateTime day) {
    return tasks.where((task) {
      return isSameDay(task.date, day);
    }).toList();
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
  }
}
