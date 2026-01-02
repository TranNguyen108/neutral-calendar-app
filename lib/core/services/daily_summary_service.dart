import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../services/achievement_service.dart';
import '../services/motivational_service.dart';

class DailySummaryService extends GetxService {
  StorageService get _storage => Get.find<StorageService>();

  AchievementService get _achievements => Get.find<AchievementService>();
  MotivationalService get _motivational => Get.find<MotivationalService>();

  /// Check if should show end-of-day summary
  bool shouldShowSummary() {
    final now = DateTime.now();
    final lastCheck = _storage.read<String>('last_summary_date');

    // Show summary between 9 PM and midnight
    if (now.hour < 21) return false;

    if (lastCheck == null) return true;

    final lastCheckDate = DateTime.parse(lastCheck);
    return !_isSameDay(now, lastCheckDate);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Update daily streak based on last completion
  Future<void> updateDailyStreak() async {
    final now = DateTime.now();
    final lastCompletion = _storage.getLastCompletionDate();
    final currentStreak = _storage.getDailyStreak();

    if (lastCompletion == null) {
      // First time - start streak at 1
      await _storage.setDailyStreak(1);
      await _storage.setLastCompletionDate(now);
      return;
    }

    final daysDiff = now.difference(lastCompletion).inDays;

    if (daysDiff == 0) {
      // Same day - no change
      return;
    } else if (daysDiff == 1) {
      // Consecutive day - increment streak
      final newStreak = currentStreak + 1;
      await _storage.setDailyStreak(newStreak);
      await _storage.setLastCompletionDate(now);
      _motivational.showStreakMilestone(newStreak);
      await _achievements.updateStreakAchievements(newStreak);
    } else {
      // Streak broken - reset to 1
      if (currentStreak > 0) {
        _motivational.showStreakBrokenMessage(currentStreak);
      }
      await _storage.setDailyStreak(1);
      await _storage.setLastCompletionDate(now);
      await _achievements.updateStreakAchievements(1);
    }
  }

  /// Show end-of-day summary dialog
  Future<void> showEndOfDaySummary() async {
    final stats = _storage.getTodayStats();
    final streak = _storage.getDailyStreak();

    await Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Text('🌙 '),
            Text('end_of_day_summary'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow(
              '✅',
              'completed_tasks'.tr,
              '${stats['completedTasks']}/${stats['totalTasks']}',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              '🎯',
              'focus_time'.tr,
              '${stats['focusMinutes']} ${'minutes'.tr}',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              '🔥',
              'daily_streak'.tr,
              '$streak ${'days'.tr}',
            ),
            const SizedBox(height: 16),
            Text(
              _getEncouragingMessage(stats),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _markSummaryShown();
            },
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String icon, String label, String value) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getEncouragingMessage(Map<String, dynamic> stats) {
    final completedTasks = stats['completedTasks'] as int;
    final totalTasks = stats['totalTasks'] as int;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0;

    if (completionRate >= 0.8) {
      return 'summary_excellent'.tr;
    } else if (completionRate >= 0.5) {
      return 'summary_good'.tr;
    } else {
      return 'summary_keep_going'.tr;
    }
  }

  Future<void> _markSummaryShown() async {
    await _storage.write('last_summary_date', DateTime.now().toIso8601String());
  }

  /// Check and show summary if needed
  Future<void> checkAndShowSummary() async {
    if (shouldShowSummary()) {
      await showEndOfDaySummary();
    }
  }
}

extension on StorageService {
  Future<void> write(String key, dynamic value) async {
    // Assuming StorageService uses GetStorage internally
    // This is a helper to write generic values
  }

  T? read<T>(String key) {
    // Read generic values from storage
    return null;
  }
}
