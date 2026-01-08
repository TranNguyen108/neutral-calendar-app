// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../core/services/sync_service.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProfileController());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('profile_title'.tr),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'nc_user'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'settings'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                Obx(() => SwitchListTile(
                      title: Text('dark_mode'.tr),
                      subtitle: Text('toggle_theme'.tr),
                      value: controller.isDarkMode.value,
                      onChanged: controller.toggleDarkMode,
                      secondary: const Icon(Icons.dark_mode),
                    )),
                const Divider(height: 1),
                Obx(() => ListTile(
                      leading: const Icon(Icons.language),
                      title: Text('language'.tr),
                      subtitle: Text(controller.currentLanguage.value),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _showLanguagePicker(context);
                      },
                    )),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: Text('reports_analytics'.tr),
                  subtitle: Text('view_statistics'.tr),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Get.toNamed(AppRoutes.report);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.emoji_events),
                  title: Text('achievements'.tr),
                  subtitle: Text('view_achievements'.tr),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showAchievements(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text('backup_restore'.tr),
                  subtitle: Text('manage_data'.tr),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Backup screen
                  },
                ),
                const Divider(height: 1),
                // Cloud Sync Status
                Obx(() {
                  final syncService = Get.find<SyncService>();
                  final isOnline = syncService.isOnline.value;
                  final syncStatus = syncService.syncStatus.value;
                  final lastSync = syncService.lastSyncTime.value;

                  String statusText = 'cloud_sync'.tr;
                  String subtitleText = '';
                  IconData statusIcon = Icons.cloud_off;
                  Color? iconColor;

                  if (!isOnline) {
                    subtitleText = 'offline_mode'.tr;
                    statusIcon = Icons.cloud_off;
                    iconColor = Colors.grey;
                  } else if (syncStatus == SyncStatus.syncing) {
                    subtitleText = 'syncing'.tr;
                    statusIcon = Icons.cloud_sync;
                    iconColor = Colors.blue;
                  } else if (syncStatus == SyncStatus.failed) {
                    subtitleText = 'sync_failed'.tr;
                    statusIcon = Icons.cloud_off;
                    iconColor = Colors.red;
                  } else if (lastSync != null) {
                    final diff = DateTime.now().difference(lastSync);
                    if (diff.inMinutes < 1) {
                      subtitleText = 'synced_just_now'.tr;
                    } else if (diff.inHours < 1) {
                      subtitleText = 'synced_minutes_ago'
                          .trParams({'minutes': '${diff.inMinutes}'});
                    } else if (diff.inHours < 24) {
                      subtitleText = 'synced_hours_ago'
                          .trParams({'hours': '${diff.inHours}'});
                    } else {
                      subtitleText = 'synced_days_ago'
                          .trParams({'days': '${diff.inDays}'});
                    }
                    statusIcon = Icons.cloud_done;
                    iconColor = Colors.green;
                  } else {
                    subtitleText = 'not_synced'.tr;
                  }

                  return ListTile(
                    leading: Icon(statusIcon, color: iconColor),
                    title: Text(statusText),
                    subtitle: Text(subtitleText),
                    trailing: isOnline && syncStatus != SyncStatus.syncing
                        ? IconButton(
                            icon: const Icon(Icons.sync, size: 20),
                            onPressed: () => syncService.syncAll(),
                            tooltip: 'sync_now'.tr,
                          )
                        : null,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'data'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text('clear_all_data'.tr,
                  style: const TextStyle(color: Colors.red)),
              subtitle: Text('clear_warning'.tr),
              onTap: () {
                Get.dialog(
                  AlertDialog(
                    title: Text('clear_confirm_title'.tr),
                    content: Text('clear_confirm_msg'.tr),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('cancel'.tr),
                      ),
                      TextButton(
                        onPressed: () {
                          controller.clearAllData();
                          Get.back();
                        },
                        child: Text('delete'.tr,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'version'.tr,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievements(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'achievements'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GetBuilder<ProfileController>(
                builder: (controller) {
                  final achievementService = controller.achievementService;
                  final achievements = achievementService.achievements;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: achievement.isUnlocked
                                ? Colors.amber
                                : Colors.grey.shade300,
                            child: Text(
                              achievement.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          title: Text(
                            achievement.titleKey.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: achievement.isUnlocked
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                achievement.descriptionKey.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: achievement.isUnlocked
                                      ? Colors.grey.shade700
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!achievement.isUnlocked) ...[
                                LinearProgressIndicator(
                                  value: achievement.progressPercentage / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.blue),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${achievement.currentProgress}/${achievement.targetProgress}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                              if (achievement.isUnlocked)
                                Text(
                                  '${'unlocked_on'.tr} ${_formatDate(achievement.unlockedAt!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showLanguagePicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'select_language'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() => RadioListTile<String>(
                  title: const Row(
                    children: [
                      Text('🇻🇳', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Text('Tiếng Việt'),
                    ],
                  ),
                  value: 'Tiếng Việt',
                  groupValue: controller.currentLanguage.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeLanguage(value);
                      Get.back();
                    }
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Row(
                    children: [
                      Text('🇺🇸', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Text('English'),
                    ],
                  ),
                  value: 'English',
                  groupValue: controller.currentLanguage.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeLanguage(value);
                      Get.back();
                    }
                  },
                )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
