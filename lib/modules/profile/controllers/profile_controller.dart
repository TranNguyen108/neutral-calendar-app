import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/ai/ai_service.dart';
import '../../../core/ai/ai_models.dart';

class ProfileController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AchievementService achievementService = Get.find<AchievementService>();
  final AIService _aiService = Get.find<AIService>();
  final isDarkMode = false.obs;
  final currentLanguage = 'Tiếng Việt'.obs;
  final apiKey = ''.obs;
  final isApiKeyConfigured = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _storage.isDarkMode();
    final lang = _storage.getLanguage();
    currentLanguage.value = lang == 'vi' ? 'Tiếng Việt' : 'English';
    _loadApiKey();
  }

  void _loadApiKey() {
    final key = _storage.getApiKey();
    if (key != null && key.isNotEmpty) {
      apiKey.value = key;
      isApiKeyConfigured.value = true;
    }
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

  Future<void> saveApiKey(String key) async {
    if (key.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'API key không được để trống',
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    try {
      // Save to storage
      await _storage.setApiKey(key.trim());

      // Set to AI Service
      await _aiService.setApiKey(key.trim());

      apiKey.value = key.trim();
      isApiKeyConfigured.value = true;

      Get.snackbar(
        'success'.tr,
        '✅ API key đã được lưu thành công',
        backgroundColor: Colors.green.shade100,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'Lỗi khi lưu API key: $e',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  Future<void> testApiKey() async {
    if (apiKey.value.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'Vui lòng nhập API key trước',
        backgroundColor: Colors.orange.shade100,
      );
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Simple test prompt
      final response = await _aiService.processUserIntent(
        'Xin chào',
        SystemContext(currentTime: DateTime.now()),
      );

      Get.back(); // Close loading dialog

      if (response.success) {
        Get.snackbar(
          'success'.tr,
          '✅ API key hoạt động tốt!',
          backgroundColor: Colors.green.shade100,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          '❌ API key không hợp lệ: ${response.error}',
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'error'.tr,
        '❌ Lỗi kiểm tra API key: $e',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  void removeApiKey() async {
    await _storage.setApiKey(null);
    apiKey.value = '';
    isApiKeyConfigured.value = false;
    Get.snackbar(
      'success'.tr,
      '🗑️ API key đã được xóa',
      backgroundColor: Colors.grey.shade200,
    );
  }
}
