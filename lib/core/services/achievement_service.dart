import 'package:get/get.dart';
import '../models/achievement.dart';
import '../services/storage_service.dart';

class AchievementService extends GetxService {
  StorageService get _storage => Get.find<StorageService>();
  final achievements = <Achievement>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAchievements();
  }

  void _initializeAchievements() {
    // Load saved achievements or create defaults
    final savedAchievements = _loadAchievements();

    if (savedAchievements.isEmpty) {
      // Create default achievements
      achievements.value = [
        Achievement(
          id: AchievementIds.streak7Days,
          titleKey: 'achievement_streak_7_title',
          descriptionKey: 'achievement_streak_7_desc',
          icon: '🔥',
          currentProgress: 0,
          targetProgress: 7,
        ),
        Achievement(
          id: AchievementIds.tasks100,
          titleKey: 'achievement_tasks_100_title',
          descriptionKey: 'achievement_tasks_100_desc',
          icon: '✅',
          currentProgress: 0,
          targetProgress: 100,
        ),
        Achievement(
          id: AchievementIds.focusSessions10,
          titleKey: 'achievement_focus_10_title',
          descriptionKey: 'achievement_focus_10_desc',
          icon: '🎯',
          currentProgress: 0,
          targetProgress: 10,
        ),
        Achievement(
          id: AchievementIds.streak30Days,
          titleKey: 'achievement_streak_30_title',
          descriptionKey: 'achievement_streak_30_desc',
          icon: '💪',
          currentProgress: 0,
          targetProgress: 30,
        ),
        Achievement(
          id: AchievementIds.tasks500,
          titleKey: 'achievement_tasks_500_title',
          descriptionKey: 'achievement_tasks_500_desc',
          icon: '🏆',
          currentProgress: 0,
          targetProgress: 500,
        ),
        Achievement(
          id: AchievementIds.focusHours50,
          titleKey: 'achievement_focus_50h_title',
          descriptionKey: 'achievement_focus_50h_desc',
          icon: '⏱️',
          currentProgress: 0,
          targetProgress: 3000, // 50 hours in minutes
        ),
      ];
    } else {
      achievements.value = savedAchievements;
    }
  }

  List<Achievement> _loadAchievements() {
    final achievementsJson = _storage.getAchievements();
    return achievementsJson.map((json) => Achievement.fromJson(json)).toList();
  }

  Future<void> _saveAchievements() async {
    await _storage
        .saveAchievements(achievements.map((a) => a.toJson()).toList());
  }

  /// Check and unlock achievement if conditions are met
  Future<Achievement?> checkAndUnlock(
      String achievementId, int newProgress) async {
    final index = achievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return null;

    final achievement = achievements[index];
    if (achievement.isUnlocked) return null;

    // Update progress
    final updated = achievement.copyWith(currentProgress: newProgress);
    achievements[index] = updated;

    // Check if unlocked
    if (updated.currentProgress >= updated.targetProgress) {
      final unlocked = updated.copyWith(unlockedAt: DateTime.now());
      achievements[index] = unlocked;
      await _saveAchievements();

      // Show notification
      _showAchievementUnlocked(unlocked);
      return unlocked;
    }

    await _saveAchievements();
    return null;
  }

  void _showAchievementUnlocked(Achievement achievement) {
    Get.snackbar(
      '${achievement.icon} ${'achievement_unlocked'.tr}',
      '${achievement.titleKey.tr}',
      duration: const Duration(seconds: 5),
    );
  }

  /// Update streak-based achievements
  Future<void> updateStreakAchievements(int currentStreak) async {
    await checkAndUnlock(AchievementIds.streak7Days, currentStreak);
    await checkAndUnlock(AchievementIds.streak30Days, currentStreak);
  }

  /// Update task completion achievements
  Future<void> updateTaskAchievements() async {
    final totalCompleted = _storage.getTotalCompletedTasks();
    await checkAndUnlock(AchievementIds.tasks100, totalCompleted);
    await checkAndUnlock(AchievementIds.tasks500, totalCompleted);
  }

  /// Update focus session achievements
  Future<void> updateFocusAchievements() async {
    final totalSessions = _storage.getFocusSessions().length;
    final totalMinutes = _storage.getTotalFocusMinutes();

    await checkAndUnlock(AchievementIds.focusSessions10, totalSessions);
    await checkAndUnlock(AchievementIds.focusHours50, totalMinutes);
  }

  List<Achievement> getUnlockedAchievements() {
    return achievements.where((a) => a.isUnlocked).toList();
  }

  List<Achievement> getLockedAchievements() {
    return achievements.where((a) => !a.isUnlocked).toList();
  }
}
