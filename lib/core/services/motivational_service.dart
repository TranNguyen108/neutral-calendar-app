import 'dart:math';
import 'package:get/get.dart';
import '../services/storage_service.dart';

class MotivationalService extends GetxService {
  StorageService get _storage => Get.find<StorageService>();
  final _random = Random();

  // Random motivational messages
  final List<String> _motivationalMessages = [
    'motivational_msg_1',
    'motivational_msg_2',
    'motivational_msg_3',
    'motivational_msg_4',
    'motivational_msg_5',
    'motivational_msg_6',
    'motivational_msg_7',
    'motivational_msg_8',
  ];

  // Context-based messages
  final List<String> _lowProductivityMessages = [
    'motivational_low_productivity_1',
    'motivational_low_productivity_2',
    'motivational_low_productivity_3',
  ];

  final List<String> _streakBrokenMessages = [
    'motivational_streak_broken_1',
    'motivational_streak_broken_2',
    'motivational_streak_broken_3',
  ];

  final List<String> _encouragementMessages = [
    'motivational_encouragement_1',
    'motivational_encouragement_2',
    'motivational_encouragement_3',
  ];

  String getRandomMotivationalMessage() {
    final index = _random.nextInt(_motivationalMessages.length);
    return _motivationalMessages[index].tr;
  }

  String getLowProductivityMessage() {
    final index = _random.nextInt(_lowProductivityMessages.length);
    return _lowProductivityMessages[index].tr;
  }

  String getStreakBrokenMessage() {
    final index = _random.nextInt(_streakBrokenMessages.length);
    return _streakBrokenMessages[index].tr;
  }

  String getEncouragementMessage() {
    final index = _random.nextInt(_encouragementMessages.length);
    return _encouragementMessages[index].tr;
  }

  /// Show context-based motivational message
  void showContextualMessage() {
    final stats = _storage.getTodayStats();
    final completedTasks = stats['completedTasks'] as int;
    final totalTasks = stats['totalTasks'] as int;
    final focusMinutes = stats['focusMinutes'] as int;

    // Low productivity - few completed tasks
    if (totalTasks > 0 && completedTasks < totalTasks ~/ 3) {
      final now = DateTime.now();
      if (now.hour >= 14) {
        // After 2 PM
        Get.snackbar(
          '💪 ${'motivational_title'.tr}',
          getLowProductivityMessage(),
          duration: const Duration(seconds: 4),
        );
        return;
      }
    }

    // Low focus time
    if (focusMinutes < 30 && DateTime.now().hour >= 16) {
      Get.snackbar(
        '🎯 ${'motivational_title'.tr}',
        getEncouragementMessage(),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Random motivational message
    if (_random.nextDouble() < 0.3) {
      // 30% chance
      Get.snackbar(
        '✨ ${'motivational_title'.tr}',
        getRandomMotivationalMessage(),
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Show motivational message when streak is broken
  void showStreakBrokenMessage(int previousStreak) {
    Get.snackbar(
      '😔 ${'streak_broken'.tr}',
      getStreakBrokenMessage(),
      duration: const Duration(seconds: 5),
    );
  }

  /// Show celebration message when streak milestone reached
  void showStreakMilestone(int streak) {
    if (streak % 7 == 0 && streak > 0) {
      Get.snackbar(
        '🔥 ${'amazing'.tr}',
        '${'streak_milestone'.tr} $streak ${'days'.tr}!',
        duration: const Duration(seconds: 5),
      );
    }
  }
}
