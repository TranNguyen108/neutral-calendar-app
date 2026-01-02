import 'package:get/get.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';

class TaskSearchController extends GetxController {
  final StorageService _storage = Get.find();

  final searchQuery = ''.obs;
  final searchResults = <Task>[].obs;
  final selectedCategories = <String>[].obs;
  final selectedPriorities = <Priority>[].obs;
  final selectedStatuses = <TaskStatus>[].obs;

  final allCategories = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    allCategories.value = _storage.getAllCategories();
    performSearch();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    performSearch();
  }

  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
    performSearch();
  }

  void togglePriority(Priority priority) {
    if (selectedPriorities.contains(priority)) {
      selectedPriorities.remove(priority);
    } else {
      selectedPriorities.add(priority);
    }
    performSearch();
  }

  void toggleStatus(TaskStatus status) {
    if (selectedStatuses.contains(status)) {
      selectedStatuses.remove(status);
    } else {
      selectedStatuses.add(status);
    }
    performSearch();
  }

  void clearFilters() {
    selectedCategories.clear();
    selectedPriorities.clear();
    selectedStatuses.clear();
    performSearch();
  }

  void performSearch() {
    searchResults.value = _storage.searchTasks(
      searchQuery.value,
      categories: selectedCategories.isEmpty ? null : selectedCategories,
      priorities: selectedPriorities.isEmpty ? null : selectedPriorities,
      statuses: selectedStatuses.isEmpty ? null : selectedStatuses,
    );
  }
}
