import 'package:get/get.dart';
import '../../../core/models/task.dart';
import '../../../core/models/event.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/task_filters.dart';

class CalendarController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final tasks = <Task>[].obs;
  final events = <Event>[].obs;
  final selectedDay = DateTime.now().obs;
  final focusedDay = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
    loadEvents();
  }

  void loadTasks() {
    tasks.value = _storage.getTasks();
  }

  void loadEvents() {
    events.value = _storage.getEvents();
  }

  // Trả về tasks cho ngày đó
  List<Task> getTasksForDay(DateTime day) {
    return tasks.forDate(day);
  }

  // Trả về events cho ngày đó
  List<Event> getEventsForDay(DateTime day) {
    // Normalize day để chỉ so sánh ngày, không so sánh giờ
    final normalizedDay = DateTime(day.year, day.month, day.day);

    return events.where((event) {
      // Normalize event date
      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      return eventDate == normalizedDay;
    }).toList();
  }

  // Tổng số items (tasks + events) cho ngày đó
  List<dynamic> getAllItemsForDay(DateTime day) {
    final tasksForDay = getTasksForDay(day);
    final eventsForDay = getEventsForDay(day);
    return [...tasksForDay, ...eventsForDay];
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
  }

  // Gọi khi thêm/sửa/xóa
  @override
  void refresh() {
    loadTasks();
    loadEvents();
  }
}
