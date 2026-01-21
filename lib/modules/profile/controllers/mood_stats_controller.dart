import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/diary.dart';
import '../../../core/models/daily_mood.dart'; // NEW: Daily mood model
import '../../../core/constants/mood_constants.dart';

class MoodStatsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final selectedPeriod = 'month'.obs; // 'month' or 'year'
  final selectedMonth = DateTime.now().obs;
  final selectedYear = DateTime.now().obs;
  final diaries = <Diary>[].obs;
  final moodCounts = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    final allDiaries = await _storage.getDiaries();

    if (selectedPeriod.value == 'month') {
      // Filter by selected month
      diaries.value = allDiaries.where((diary) {
        return diary.date.year == selectedMonth.value.year &&
            diary.date.month == selectedMonth.value.month;
      }).toList();
    } else {
      // Filter by selected year
      diaries.value = allDiaries.where((diary) {
        return diary.date.year == selectedYear.value.year;
      }).toList();
    }

    diaries.sort((a, b) => a.date.compareTo(b.date));
    _calculateMoodCounts();
  }

  void _calculateMoodCounts() {
    moodCounts.clear();
    for (var mood in MoodConstants.allMoods) {
      moodCounts[mood] = 0;
    }

    for (var diary in diaries) {
      final mood = diary.mood ?? MoodConstants.normal;
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }
  }

  void setMonth(DateTime month) {
    selectedMonth.value = month;
    loadData();
  }

  void setYear(DateTime year) {
    selectedYear.value = year;
    loadData();
  }

  void setPeriod(String period) {
    selectedPeriod.value = period;
    loadData();
  }

  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    loadData();
  }

  void nextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    loadData();
  }

  void previousYear() {
    selectedYear.value = DateTime(selectedYear.value.year - 1);
    loadData();
  }

  void nextYear() {
    selectedYear.value = DateTime(selectedYear.value.year + 1);
    loadData();
  }

  // Get diaries for a specific day
  List<Diary> getDiariesForDay(DateTime date) {
    return diaries.where((diary) {
      return diary.date.year == date.year &&
          diary.date.month == date.month &&
          diary.date.day == date.day;
    }).toList();
  }

  // Get mood for a specific day (first diary's mood)
  // === UPDATED: Now prioritizes daily mood if available ===
  String? getMoodForDay(DateTime date) {
    // 1. Try to get user-confirmed daily mood first
    final dailyMood = _storage.getDailyMoodForDate(date);
    if (dailyMood != null) {
      return dailyMood.mood;
    }

    // 2. Fallback: use first diary's mood for backward compatibility
    final dayDiaries = getDiariesForDay(date);
    return dayDiaries.isNotEmpty ? dayDiaries.first.mood : null;
  }

  /// === NEW: Get daily mood object if exists ===
  DailyMood? getDailyMoodForDay(DateTime date) {
    return _storage.getDailyMoodForDate(date);
  }

  /// === NEW: Check if daily mood is user-confirmed ===
  bool isDailyMoodUserConfirmed(DateTime date) {
    final dailyMood = getDailyMoodForDay(date);
    return dailyMood?.isUserConfirmed ?? false;
  }
}
