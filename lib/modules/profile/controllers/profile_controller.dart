import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/achievement_service.dart';

class ProfileController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AchievementService achievementService = Get.find<AchievementService>();
  final isDarkMode = false.obs;
  final currentLanguage = 'Tiếng Việt'.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _storage.isDarkMode();
    final lang = _storage.getLanguage();
    currentLanguage.value = lang == 'vi' ? 'Tiếng Việt' : 'English';
  }

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    _storage.setDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void changeLanguage(String language) async {
    currentLanguage.value = language;
    final code = language == 'Tiếng Việt' ? 'vi' : 'en';
    await _storage.setLanguage(code);

    // Change locale immediately
    final locale =
        code == 'vi' ? const Locale('vi', 'VN') : const Locale('en', 'US');
    Get.updateLocale(locale);

    Get.snackbar(
      'success'.tr,
      'language_changed'.tr,
      duration: const Duration(seconds: 2),
    );
  }

  void clearAllData() async {
    await _storage.clearAll();
    Get.snackbar('Success', 'All data cleared');
  }
}
